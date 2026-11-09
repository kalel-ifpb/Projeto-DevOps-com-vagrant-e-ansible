#!/bin/bash
# Sobe o ambiente na ordem correta: arq (DHCP/DNS/NFS) primeiro, depois o resto.
# O Ansible roda automaticamente em cada VM durante o "vagrant up".
set -e

echo "=== [1/3] Subindo e provisionando o servidor de arquivos (arq)... ==="
vagrant up arq

echo "=== [2/3] Subindo e provisionando db, app e cli... ==="
vagrant up db app cli

echo "=== [3/3] Status das máquinas: ==="
vagrant status
