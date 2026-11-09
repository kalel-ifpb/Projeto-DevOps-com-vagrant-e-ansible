# Projeto 01 - DevOps com Vagrant e Ansible

**Instituto Federal da Paraíba - IFPB Campus João Pessoa**  
**Disciplina:** Administração de Sistemas Abertos  
**Professor:** Leonidas Lima  
**Período:** 2026.2

## Equipe
- Francisco Farias do Nascimento (Matrícula: 20241078)
- Kalel Aleksander Nery Bezerra (Matrícula: 20241021)

## Descrição do Projeto
Este projeto automatiza o provisionamento e a configuração de um ambiente de rede simulado através de Infraestrutura como Código (IaC). Utilizamos o **Vagrant** para gerenciar o hypervisor (VirtualBox) e o **Ansible** para padronizar as configurações de SO e serviços nativos de redes de computadores em 4 máquinas virtuais (Debian Bookworm):

1. **ARQ (Servidor de Arquivos):** Concentra serviços de base (DHCP, DNS), gestão de discos (LVM) e compartilhamento de arquivos via NFS. 
2. **DB (Banco de Dados):** Executa o MariaDB e acessa arquivos no servidor `arq` dinamicamente via `autofs`.
3. **APP (Aplicação):** Hospeda um servidor web Apache2 exibindo as informações da equipe.
4. **CLI (Cliente):** Máquina de testes configurada com X11Forwarding para exportação de interfaces gráficas.

## Como Executar

O Vagrant e o VirtualBox precisam estar instalados na sua máquina. O provisionamento das máquinas virtuais depende da inicialização dos serviços de DHCP e DNS hospedados no servidor de arquivos para que as demais máquinas adquiram endereçamento de rede corretamente.

Para automatizar o provisionamento respeitando essa ordem de inicialização, basta executar o script `up.sh` na raiz do projeto:

```bash
./up.sh