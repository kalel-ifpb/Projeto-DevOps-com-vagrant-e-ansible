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

O Vagrant e o VirtualBox precisam estar instalados na sua máquina. Você pode apenas executar o script up e fazer o provisionamento automaticamente seguido do status das máquinas:

   ```bash
   bash up.sh
   ```
Ou manualmente seguindo a ordem de execução abaixo, uma vez que as máquinas dependem do DHCP e DNS do servidor de arquivos:

1. **Subir e provisionar o Servidor de Arquivos (arq) primeiro:**
   Isso garante que o DHCP e o DNS já estejam rodando para das próximas máquinas.
   ```bash
   vagrant up arq

2. **Subir e provisionar o restante da infraestrutura (db, app, cli):**
   Execute o comando para iniciar e provisionar o banco de dados, a aplicação e o cliente em sequência:
   ```bash
   vagrant up db app cli

3. **(Opcional: exibir o status das máquinas:**
   Pra verificar o status das máquinas após o termino do processo:
   ```bash
   vagrant status
