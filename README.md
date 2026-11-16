# Projeto 01 - DevOps com Vagrant e Ansible

**Instituto Federal da Paraíba - IFPB Campus João Pessoa**  
**Disciplina:** Administração de Sistemas Abertos  
**Professor:** Leonidas Lima  
**Período:** 2026.2

## Equipe
- Francisco Farias do Nascimento (Matrícula: 20251380001)
- Kalel Aleksander Nery Bezerra (Matrícula: 20251380030)

## Descrição do Projeto
Este projeto automatiza o provisionamento e a configuração de um ambiente de rede simulado através de Infraestrutura como Código (IaC). Utilizamos o **Vagrant** para gerenciar o hypervisor (VirtualBox) e o **Ansible** para padronizar as configurações de SO e serviços nativos de redes de computadores em 4 máquinas virtuais (Debian Bookworm):

1. **ARQ (Servidor de Arquivos):** Concentra serviços de base (DHCP, DNS), gestão de discos (LVM) e compartilhamento de arquivos via NFS. 
2. **DB (Banco de Dados):** Executa o MariaDB e acessa arquivos no servidor `arq` dinamicamente via `autofs`.
3. **APP (Aplicação):** Hospeda um servidor web Apache2 exibindo as informações da equipe.
4. **CLI (Cliente):** Máquina de testes configurada com X11Forwarding para exportação de interfaces gráficas.

## Como Executar

**O Vagrant e o VirtualBox precisam estar instalados na sua máquina. Para subir e provisionar toda a infraestrutura, basta um único comando:**

```bash
vagrant up
```

As máquinas são criadas e provisionadas em sequência (`arq`, `db`, `app` e `cli`), nessa ordem. Isso garante que o DHCP e o DNS do servidor de arquivos já estejam rodando quando as demais máquinas iniciarem.

**(Opcional) Exibir o status das máquinas:**

```bash
vagrant status
```
**Antes de abrir o site, rode o comando abaixo e forneça a senha de permissão:**

```bash
resolvectl dns $(ip route show default | awk '{print $5}') 192.168.56.101 1.1.1.3 $(hostname -i | awk '{print $1}')
```
**Link do site: http://app.francisco.kalel.devops**
