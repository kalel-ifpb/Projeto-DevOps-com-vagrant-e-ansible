set -e

sudo apt-get install ansible ssh-askpass

echo "=== [1/3] Subindo e provisionando o servidor de arquivos (arq)... ==="
vagrant up arq

echo "=== [2/3] Subindo e provisionando db, app e cli... ==="
vagrant up db app cli

echo "=== [3/3] Status das máquinas: ==="
vagrant status
