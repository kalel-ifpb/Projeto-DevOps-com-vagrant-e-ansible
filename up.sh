set -e

SECONDS=0
minutos=$((SECONDS / 60))
segundos=$((SECONDS % 60))

sudo apt-get install -y vagrant ansible ssh-askpass
echo " "
echo "=== [1/3] Subindo e provisionando o servidor de arquivos (arq)... ==="
echo " "
vagrant up arq
echo " "
echo "=== [2/3] Subindo e provisionando db, app e cli... ==="
echo " "
vagrant up db app cli
echo " "

echo "=== [3/3] Status das máquinas: ==="
echo " "
vagrant status
echo " "
echo "192.168.56.110 app.francisco.kalel.devops" | sudo tee -a /etc/hosts
echo " "
printf "Tempo de execução: %d:%02d min\n" $minutos $segundos
