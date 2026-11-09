set -e

SECONDS=0
minutos=$((SECONDS / 60))
segundos=$((SECONDS % 60))

sudo apt-get install -y vagrant ansible ssh-askpass

echo "=== [1/3] Subindo e provisionando o servidor de arquivos (arq)... ==="
vagrant up arq

echo "=== [2/3] Subindo e provisionando db, app e cli... ==="
vagrant up db app cli

echo "=== [3/3] Status das máquinas: ==="
vagrant status

echo "192.168.56.171 app.francisco.kalel.devops" | sudo tee -a /etc/hosts

printf "Tempo de execução: %d:%02d min\n" $minutos $segundos
