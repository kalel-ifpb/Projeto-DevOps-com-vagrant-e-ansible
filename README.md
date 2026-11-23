# Projeto 01 — Automação de Infraestrutura DevOps com Vagrant e Ansible

**Instituição:** Instituto Federal da Paraíba (IFPB) — Campus João Pessoa  
**Curso / Disciplina:** Administração de Sistemas Abertos  
**Professor:** Leonidas Lima  
**Período Letivo:** 2026.2  

## Integrantes da Equipe

* **Francisco Farias do Nascimento** — Matrícula: `20251380001`
* **Kalel Aleksander Nery Bezerra** — Matrícula: `20251380030`

---

## Sumário

1. [Visão Geral do Projeto](#visão-geral-do-projeto)
2. [Arquitetura e Topologia de Rede](#arquitetura-e-topologia-de-rede)
3. [Detalhamento das Máquinas Virtuais e Serviços](#detalhamento-das-máquinas-virtuais-e-serviços)
4. [Estrutura do Repositório e Função de Cada Arquivo](#estrutura-do-repositório-e-função-de-cada-arquivo)
5. [Pré-requisitos do Ambiente Host](#pré-requisitos-do-ambiente-host)
6. [Passo a Passo para Execução](#passo-a-passo-para-execução)
7. [Acesso Remoto (SSH e X11 Forwarding)](#acesso-remoto-ssh-e-x11-forwarding)
8. [Guia de Validação e Testes dos Serviços](#guia-de-validação-e-testes-dos-serviços)
9. [Comandos Úteis de Gerenciamento](#comandos-úteis-de-gerenciamento)

---

## Visão Geral do Projeto

Este projeto implementa o provisionamento e o gerenciamento de configuração automatizado de uma infraestrutura corporativa simulada utilizando princípios de **Infraestrutura como Código (IaC)** e **DevOps**.

A solução combina duas ferramentas principais:

* **Vagrant + VirtualBox:** Responsáveis por orquestrar todo o ciclo de vida das máquinas virtuais (criação otimizada via *linked clones* a partir do Debian 12, configuração de interfaces de rede privada, anexação de discos rígidos virtuais e execução de gatilhos/*triggers* no sistema hospedeiro).
* **Ansible:** Responsável por configurar e manter o estado desejado de forma idempotente em todas as instâncias, abrangendo políticas de segurança (*hardening* SSH e `sudo`), sincronização de relógio (NTP), gerenciamento de volumes lógicos (LVM), serviços essenciais de rede (DHCP e DNS), armazenamento compartilhado (NFS + Autofs), banco de dados (MariaDB), servidor web (Apache2) e estação cliente com suporte gráfico (Firefox ESR + X11).

---

## Arquitetura e Topologia de Rede

Toda a comunicação interna ocorre em uma rede privada isolada (*Host-Only*) no intervalo **`192.168.56.0/24`**, sob o domínio interno **`francisco.kalel.devops`**.

```text
                    [ Host Linux / VirtualBox: vboxnet0 ]
                             IP Gateway: 192.168.56.1
                                        │
                    ┌───────────────────┴───────────────────┐
                    │     Rede Privada: 192.168.56.0/24     │
                    │     Domínio: francisco.kalel.devops   │
                    └─┬─────────┬───────────────┬─────────┬─┘
                      │         │               │         │
         ┌────────────┘         │               │         └────────────┐
         ▼                      ▼               ▼                      ▼
┌─────────────────┐    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│       ARQ       │    │       DB        │ │       APP       │ │       CLI       │
│ 192.168.56.101  │    │ 192.168.56.130  │ │ 192.168.56.110  │ │ .50 a .100      │
│   (IP Fixo)     │    │ (DHCP Reserva)  │ │ (DHCP Reserva)  │ │ (DHCP Dinâmico) │
├─────────────────┤    ├─────────────────┤ ├─────────────────┤ ├─────────────────┤
│ • ISC DHCP      │    │ • MariaDB       │ │ • Apache2       │ │ • Firefox ESR   │
│ • BIND9 (DNS)   │    │ • Autofs        │ │ • Autofs        │ │ • X11 / xauth   │
│ • LVM (30 GB)   │    └────────┬────────┘ └────────┬────────┘ │ • Autofs        │
│ • NFS Server    │             │ monta /var/nfs    │          └────────┬────────┘
└────────▲────────┘             └───────────────────┼───────────────────┘
         └──────────────────────────────────────────┘
```

### Resumo das Instâncias

| Hostname | FQDN | IP na Rede `eth1` | Tipo de Endereçamento | RAM | Discos Extras | Papel na Infraestrutura |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`arq`** | `arq.francisco.kalel.devops` | `192.168.56.101` | Estático | 512 MB | 3 × 10 GB | Servidor Core (DHCP, DNS) e Arquivos (LVM + NFS) |
| **`db`** | `db.francisco.kalel.devops` | `192.168.56.130` | DHCP Reservado (`08:00:27:11:11:11`) | 512 MB | — | Servidor de Banco de Dados (MariaDB) + Cliente NFS |
| **`app`** | `app.francisco.kalel.devops` | `192.168.56.110` | DHCP Reservado (`08:00:27:22:22:22`) | 512 MB | — | Servidor de Aplicação Web (Apache2) + Cliente NFS |
| **`cli`** | `cli.francisco.kalel.devops` | `192.168.56.50`–`100` | DHCP Dinâmico | 1024 MB | — | Estação Cliente (Firefox ESR, X11) + Cliente NFS |

---

## Detalhamento das Máquinas Virtuais e Serviços

Todas as máquinas virtuais utilizam a imagem base **Debian 12 Bookworm (`debian/bookworm64`)**. Antes de receberem suas funções específicas, todas passam por uma etapa de **configuração global e endurecimento (*hardening*)**.

### 0. Configurações Globais Aplicadas a Todas as VMs (`arq`, `db`, `app`, `cli`)

* **Preparação do Sistema Operacional:** Configuração não interativa do pacote `grub-pc` via `debconf` (apontando para `/dev/sda`) e atualização do cache de repositórios APT (`cache_valid_time: 3600`).
* **Sincronização de Horário (Chrony / NTP):** Ajuste do fuso horário do sistema para `America/Recife` e configuração do daemon **Chrony** (`chrony`) sincronizando com os servidores oficiais brasileiros `pool.ntp.br` (`iburst`).
* **Gerenciamento de Usuários e Privilégios (`sudo`):**
  * Criação do grupo administrativo `ifpb`.
  * Criação dos usuários `francisco` e `kalel` (shell `/bin/bash`, membros do grupo `ifpb`).
  * Concessão de privilégios administrativos sem exigência de senha (`%ifpb ALL=(ALL) NOPASSWD: ALL`) em `/etc/sudoers.d/ifpb`, com validação sintática automática via `visudo -cf`.
* **Segurança e Autenticação SSH (`openssh-server`):**
  * Geração automática no host de pares de chaves **RSA 2048 bits** (`keys/francisco` e `keys/kalel`) e distribuição das chaves públicas para o `authorized_keys` dos respectivos usuários nas VMs.
  * Aplicação de regras rígidas em `/etc/ssh/sshd_config` (validado com `sshd -t`):
    * `PermitRootLogin no` (bloqueia login direto como `root`);
    * `PasswordAuthentication no` (desativa autenticação por senha);
    * `PubkeyAuthentication yes` (permite apenas autenticação por chave assimétrica);
    * `AllowGroups vagrant ifpb` (restringe o acesso SSH apenas aos usuários do grupo `vagrant` e `ifpb`);
    * Exibição de banner de aviso legal configurado em `/etc/issue.net`.

---

### 1. Máquina `arq` (`arq.francisco.kalel.devops`) — Servidor de Infraestrutura e Arquivos

É o servidor central da topologia e, por isso, é sempre a **primeira máquina a ser iniciada e provisionada**. Fornece endereçamento IP, resolução de nomes e armazenamento em rede para todo o ambiente.

* **Servidor DHCP (`isc-dhcp-server`):**
  * Escuta exclusivamente na interface de rede privada `eth1` (`/etc/default/isc-dhcp-server`).
  * Distribui endereços dinâmicos no intervalo de **`192.168.56.50` a `192.168.56.100`** (utilizado pela estação `cli`).
  * Entrega aos clientes o domínio `francisco.kalel.devops`, o servidor DNS `192.168.56.101` e o roteador padrão `192.168.56.1`.
  * Mantém **reservas de IP fixas por endereço MAC** (`host db` → `192.168.56.130`; `host app` → `192.168.56.110`), garantindo previsibilidade de rede mesmo usando DHCP.
* **Servidor DNS Autoritativo (`bind9`):**
  * Responde pelas consultas internas da sub-rede `192.168.56.0/24` e encaminha consultas externas (*forwarders*) para `1.1.1.1` (Cloudflare) e `8.8.8.8` (Google).
  * **Zona Direta (`francisco.kalel.devops`):** Resolve os nomes `ns1`, `arq` (`.101`), `app` (`.110`) e `db` (`.130`) para seus respectivos IPs.
  * **Zona Reversa (`56.168.192.in-addr.arpa`):** Resolve os endereços IP de volta para seus FQDNs por meio de registros `PTR`.
* **Gerenciamento de Armazenamento com LVM (`lvm2`):**
  * Agrupa três discos virtuais adicionais de 10 GB anexados pelo VirtualBox (`/dev/sdb`, `/dev/sdc` e `/dev/sdd`) em um **Volume Group** chamado **`dados`** (totalizando 30 GB de capacidade bruta).
  * Cria um **Logical Volume** chamado **`ifpb`** com **15 GB** (`/dev/dados/ifpb`), formata com o sistema de arquivos `ext4` e configura a montagem persistente em **`/dados`** via `/etc/fstab`.
* **Servidor de Arquivos NFS (`nfs-kernel-server`):**
  * Cria o usuário e grupo de sistema `nfs-ifpb` (UID `2000` / GID `2000`), proprietário do diretório `/dados/nfs`.
  * Exporta `/dados/nfs` via `/etc/exports` para toda a rede `192.168.56.0/24` com os parâmetros `rw,sync,no_wdelay,all_squash,anonuid=2000,anongid=2000`, padronizando o mapeamento de permissões de escrita e leitura entre todos os clientes.

---

### 2. Máquina `db` (`db.francisco.kalel.devops`) — Servidor de Banco de Dados

Responsável por hospedar o sistema gerenciador de banco de dados relacional da infraestrutura.

* **Banco de Dados Relacional (`mariadb-server`):**
  * Serviço `mariadb` instalado, iniciado e habilitado no boot para prover persistência de dados para aplicações corporativas.
* **Montagem Dinâmica NFS (`autofs` + `nfs-common`):**
  * Configurado com `/etc/auto.master` e `/etc/auto.nfs` para montar sob demanda o compartilhamento remoto `192.168.56.101:/dados/nfs` no diretório local **`/var/nfs`**. O uso do Autofs evita travamentos na inicialização caso o servidor `arq` esteja indisponível e libera a conexão automaticamente após períodos de inatividade.

---

### 3. Máquina `app` (`app.francisco.kalel.devops`) — Servidor de Aplicação Web

Responsável por servir a camada de apresentação HTTP da infraestrutura.

* **Servidor Web (`apache2`):**
  * Serviço `apache2` ativo na porta `80/TCP`.
  * Hospeda uma página institucional personalizada em `/var/www/html/index.html` contendo a identificação do projeto, da disciplina e dos integrantes da equipe.
* **Montagem Dinâmica NFS (`autofs` + `nfs-common`):**
  * Assim como o nó `db`, monta automaticamente o diretório compartilhado `192.168.56.101:/dados/nfs` em **`/var/nfs`** sempre que acessado.

---

### 4. Máquina `cli` (`cli.francisco.kalel.devops`) — Estação Cliente

Simula uma estação de trabalho de usuário/administrador dentro da rede corporativa, com **1024 MB de RAM** para suportar aplicações gráficas.

* **Navegador Web (`firefox-esr`):**
  * Instalado para validar a resolução DNS interna, o recebimento automático de IP via DHCP e o acesso HTTP à aplicação hospedada em `http://app.francisco.kalel.devops`.
* **Suporte a Aplicações Gráficas Remotas (`xauth` + SSH X11 Forwarding):**
  * O pacote `xauth` e a diretiva `X11Forwarding yes` no daemon SSH permitem abrir o Firefox ESR (ou outras ferramentas gráficas) diretamente na tela da máquina hospedeira Linux via túnel SSH (`ssh -X`).
* **Montagem Dinâmica NFS (`autofs` + `nfs-common`):**
  * Monta sob demanda o compartilhamento `192.168.56.101:/dados/nfs` em **`/var/nfs`**, permitindo troca de arquivos entre a estação cliente e os servidores `app` e `db`.

---

## Estrutura do Repositório e Função de Cada Arquivo

```text
Projeto-DevOps-com-vagrant-e-ansible-main/
├── .gitignore
├── README.md
├── Vagrantfile
├── keys/                      # (Gerado automaticamente na execução)
└── ansible/
    ├── ansible.cfg
    ├── inventory.yml
    └── playbook.yml
```

### Descrição Detalhada dos Arquivos

* **`Vagrantfile`**
  * **Função:** Arquivo principal de definição de infraestrutura do Vagrant.
  * **O que faz:**
    * Define a box base `debian/bookworm64` e ativa *linked clones* (`v.linked_clone = true`) para economizar espaço em disco e acelerar a criação das VMs.
    * Instancia as 4 VMs (`arq`, `db`, `app`, `cli`) com seus respectivos hostnames, quantidades de memória RAM, interfaces de rede privada (`192.168.56.0/24`) e endereços MAC fixos para `db` e `app`.
    * Cria e anexa dinamicamente os três discos virtuais `.vdi` de 10 GB (`disk1.vdi`, `disk2.vdi`, `disk3.vdi`) exclusivamente na VM `arq`.
    * Configura **dois *triggers* de automação** no host:
      1. *Antes de conectar via SSH (`before :WaitForCommunicator`):* executa `vboxmanage dhcpserver stop --network=HostInterfaceNetworking-vboxnet0` para desativar o DHCP nativo do VirtualBox e evitar conflito com o `isc-dhcp-server` da VM `arq`.
      2. *Após subir a última VM (`cli`, `after :up`):* solicita permissão `sudo` no host e adiciona os mapeamentos de IP e FQDN (`arq`, `db`, `app`, `cli`) ao `/etc/hosts` da máquina hospedeira.
    * Invoca o provisionador `ansible` apontando para `ansible/inventory.yml` e `ansible/playbook.yml`.

* **`ansible/ansible.cfg`**
  * **Função:** Arquivo de configuração local do Ansible.
  * **O que faz:** Desativa a verificação interativa de impressões digitais SSH (`host_key_checking = False`) para evitar bloqueios durante o provisionamento automatizado de novas VMs e oculta avisos de depreciação (`deprecation_warnings = False`) para manter a saída do terminal limpa.

* **`ansible/inventory.yml`**
  * **Função:** Inventário estático dos nós gerenciados pelo Ansible.
  * **O que faz:** Lista os quatro hosts (`arq`, `db`, `app`, `cli`), define seus endereços IP internos na sub-rede `192.168.56.0/24` (como `192.168.56.101`, `192.168.56.130`, `192.168.56.110`) e configura as credenciais padrão de conexão inicial via usuário `vagrant` e chave privada insegura padrão do Vagrant.

* **`ansible/playbook.yml`**
  * **Função:** Coração da automação e gerência de configuração do ambiente.
  * **O que faz:** Organiza todo o provisionamento em 5 *plays* sequenciais e idempotentes:
    1. **`hosts: all`:** Configura `debconf`/GRUB, fuso horário `America/Recife`, NTP com Chrony, grupo `ifpb`, usuários `francisco` e `kalel`, permissões `sudo`, geração local das chaves SSH em `../keys` e *hardening* do `sshd_config`.
    2. **`hosts: arq`:** Instala e configura `isc-dhcp-server`, `bind9` (zonas direta e reversa), `lvm2` (VG `dados` + LV `ifpb` de 15 GB montado em `/dados`) e `nfs-kernel-server` (`/dados/nfs`).
    3. **`hosts: db:app:cli`:** Instala `autofs` e `nfs-common` e configura a montagem automática de `192.168.56.101:/dados/nfs` em `/var/nfs`.
    4. **`hosts: db` e `hosts: app`:** Instala e habilita o **MariaDB** em `db` e o **Apache2** (com `index.html` customizado) em `app`.
    5. **`hosts: cli`:** Instala o **Firefox ESR** e o **`xauth`** e habilita `X11Forwarding yes` no SSH.
    * Inclui também **handlers** dedicados para reiniciar/recarregar serviços (`ssh`, `chrony`, `isc-dhcp-server`, `bind9`, `nfs-kernel-server`, `autofs`, `apache2`) somente quando seus arquivos de configuração forem alterados.

* **`.gitignore`**
  * **Função:** Controle de arquivos ignorados pelo Git.
  * **O que faz:** Impede que diretórios de estado local do Vagrant (`.vagrant/`), arquivos temporários do VirtualBox (`*.vbox`, `*.vbox-prev`), arquivos de falha do Ansible (`*.retry`), scripts auxiliares locais e as chaves privadas geradas dinamicamente (`keys/`) sejam enviados ao repositório remoto.

* **`README.md`**
  * **Função:** Documentação técnica de referência do projeto, descrevendo arquitetura, topologia, serviços por nó, estrutura de arquivos e instruções de implantação e teste.

---

## Pré-requisitos do Ambiente Host

Para executar este projeto sem ajustes manuais, recomenda-se uma máquina hospedeira **Linux** com:

* **VirtualBox** (com suporte à rede Host-Only `vboxnet0`)
* **Vagrant** (versão `2.3` ou superior)
* **Ansible** (instalado no host, pois o `Vagrantfile` utiliza o provisionador local `ansible`)
* **OpenSSH Client** e **`systemd-resolved` (`resolvectl`)**

---

## Passo a Passo para Execução

### 1. Clonar o repositório e iniciar a infraestrutura

```bash
git clone <URL_DO_REPOSITORIO>
cd Projeto-DevOps-com-vagrant-e-ansible-main
vagrant up
```

> **Nota sobre a ordem de boot:** O Vagrant inicializa e provisiona as VMs sequencialmente na ordem **`arq` → `db` → `app` → `cli`**. Essa sequência garante que os serviços de DHCP e DNS estejam operacionais em `arq` antes que `db`, `app` e `cli` solicitem endereçamento e resolução de nomes. Durante o processo, será solicitada a senha `sudo` do host para registrar os hosts em `/etc/hosts`.

### 2. Configurar a resolução DNS no host (opcional/recomendado)

Para que o navegador e o terminal da sua máquina hospedeira utilizem o servidor DNS **BIND9** da VM `arq` (`192.168.56.101`) para resolver o domínio `francisco.kalel.devops`:

```bash
resolvectl dns $(ip route show default | awk '{print $5}') 192.168.56.101 1.1.1.3 $(hostname -i | awk '{print $1}')
```

### 3. Acessar a aplicação web

Abra o navegador na máquina hospedeira (ou via estação `cli`) e acesse:

* **Via nome de domínio (DNS):** `http://app.francisco.kalel.devops`
* **Via endereço IP direto:** `http://192.168.56.110`

---

## Acesso Remoto (SSH e X11 Forwarding)

Após o provisionamento, o login via senha e o login direto como `root` estão desabilitados. Utilize o comando `vagrant ssh` ou conecte-se diretamente com as chaves privadas geradas na pasta `keys/`:

```bash
# Acessar uma VM pelo Vagrant
vagrant ssh arq

# Acessar via SSH direto usando a chave gerada para o usuário criado pelo Ansible
ssh -i keys/francisco francisco@arq.francisco.kalel.devops
ssh -i keys/kalel kalel@app.francisco.kalel.devops

# Abrir o Firefox ESR da estação cliente (cli) na tela do host via X11 Forwarding
ssh -X -i keys/francisco francisco@cli.francisco.kalel.devops firefox-esr
```

---

## Guia de Validação e Testes dos Serviços

Utilize os comandos abaixo para auditar cada componente implantado:

| Serviço / Recurso | Onde Executar | Comando de Verificação | Comportamento Esperado |
| :--- | :--- | :--- | :--- |
| **DNS Direto** | `cli` ou Host | `dig @192.168.56.101 app.francisco.kalel.devops +short` | Retorna `192.168.56.110` |
| **DNS Reverso** | `cli` ou Host | `dig @192.168.56.101 -x 192.168.56.130 +short` | Retorna `db.francisco.kalel.devops.` |
| **DHCP (Lease)** | `cli` | `ip -4 addr show eth1` | Exibe IP dinâmico entre `.50` e `.100` |
| **LVM e Disco** | `arq` | `sudo pvs && sudo vgs && sudo lvs && df -h /dados` | VG `dados` (30 GB) e LV `ifpb` (15 GB) montado em `/dados` |
| **NFS + Autofs** | `db`, `app`, `cli` | `ls -la /var/nfs && mount \| grep /var/nfs` | Monta `192.168.56.101:/dados/nfs` automaticamente sob demanda |
| **MariaDB** | `db` | `sudo systemctl status mariadb` | Serviço `active (running)` |
| **Apache2** | `app` ou `cli` | `curl -s http://app.francisco.kalel.devops` | Retorna o HTML institucional do projeto |
| **Sincronização NTP** | Todas as VMs | `chronyc sources` | Exibe sincronização ativa com `pool.ntp.br` |
| **Hardening SSH** | `cli` | `ssh root@192.168.56.101` | Acesso negado (`Permission denied (publickey)`) |

---

## Comandos Úteis de Gerenciamento

```bash
# Verificar o status atual das 4 máquinas virtuais
vagrant status

# Reexecutar apenas o Ansible para validar a idempotência da infraestrutura
vagrant provision

# Desligar todas as VMs mantendo os discos e configurações salvas
vagrant halt

# Destruir completamente todas as VMs e discos virtuais criados
vagrant destroy -f
```
