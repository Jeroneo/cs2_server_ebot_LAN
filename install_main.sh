#! /bin/bash

if [ $(id -u) -ne 0 ]
    then echo Lancez ce script en tant que root ou avec sudo!
    exit
fi

red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
yellow='\e[1;33m%s\e[0m\n'
blue='\e[1;34m%s\e[0m\n'
magenta='\e[1;35m%s\e[0m\n'
cyan='\e[1;36m%s\e[0m\n'


sudo apt update
sudo apt upgrade

# Configuration des VLAN
printf "$green" "[INFO] Configuration des VLAN"
bash ./conf_VLAN.sh &
wait

LOCAL_IP_PROD=$(ip addr show eth0.10 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
LOCAL_IP_CS=$(ip addr show eth0.20 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

printf "$green" "[INFO] Configuration des VLAN terminé"
printf "$green" "Installation des service sur l'adresse IP de PROD : $LOCAL_IP_PROD"
printf "$green" "Adresse IP joueur CS : $LOCAL_IP_CS"

read -p "Appuyez sur Entrée pour continuer..."

# Installation de Docker et Docker Compose
printf "$green" "[INFO] Installation de Docker"
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
curl -sSL https://get.docker.com/ | CHANNEL=stable bash

sudo systemctl enable --now docker

printf "$green" "[INFO] Installation de Docker Compose"
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Instalation de Pterodactyl
printf "$green" "[INFO] Installation de Pterodactyl"
cd ./pterodactyl
cp env.sample .env
bash ./install_pterodactyl.sh &
wait
rm env.sample
cd ..
printf "$green" "[INFO] Installation de Pterodactyl terminé"

# Installation de Ebot
printf "$green" "[INFO] Installation de Ebot"

cd ./ebot
cp env.sample .env
sed -i "s|EBOT_IP=.*|EBOT_IP=$LOCAL_IP_PROD|g" .env
sed -i "s|LOG_ADDRESS_SERVER=.*|LOG_ADDRESS_SERVER=http:\/\/$LOCAL_IP_PROD:12345|g" .env
sed -i "s|WEBSOCKET_URL=.*|WEBSOCKET_URL=http:\/\/$LOCAL_IP_PROD:12360|g" .env

bash ./setup.sh &
wait

docker compose up -d &
wait

rm env.sample

printf "$green" "[INFO] Installation de Ebot terminé"

echo "Tous les services ont été installés, vous pouvez y accedez via :
    -   Pterodactyl : http://$LOCAL_IP_PROD:8000
    -   Ebot :  http://$LOCAL_IP_PROD
    -   Ebot admin : http://$LOCAL_IP_PROD/admin.php"


