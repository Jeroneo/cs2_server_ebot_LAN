#! /bin/bash

# Sources :     - https://pterodactyl.io/wings/1.0/installing.html


# Verifie que le script est bien lance avec les privileges root
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


# ---------------------------------------------------- Reprise du script ----------------------------------------------------

# ------------------------------- Installation Wings ------------------------------

printf "$green" "[INFO] Demarrage du script"

printf "$green" "[INFO] Configuration des VLAN"
bash ./conf_VLAN.sh &
wait

LOCAL_IP_PROD=$(ip addr show eth0.10 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
LOCAL_IP_CS=$(ip addr show eth0.20 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

printf "$green" "[INFO] Configuration des VLAN terminé"
printf "$green" "Adresse IP de PROD : $LOCAL_IP_PROD"
printf "$green" "Adresse IP joueur CS : $LOCAL_IP_CS"

read -p "Appuyez sur Entrée pour continuer..."

printf "$green" "[INFO] Installation de curl"

apt -y install curl ca-certificates sudo lsb-release

# Installation Docker
printf "$green" "[INFO] Installation de Docker"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash

# Demarrage de Docker au demarrage de la machine
sudo systemctl enable --now docker

# Enabling Swap, to prevent OOM (out of memory) errors
printf "$green" "[INFO] Activation du Swap pour eviter les erreurs OOM"
# To enable swap, open /etc/default/grub as a root user and find the line starting with GRUB_CMDLINE_LINUX_DEFAULT. Make sure the line includes swapaccount=1 somewhere inside the double-quotes.
sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT="\).*\(".*\)/\1swapaccount=1\2/' /etc/default/grub

# Mise a jour du GRUB
printf "$green" "[INFO] Mise a jour du GRUB"
sudo update-grub

# Telechargement de Wings
printf "$green" "[INFO] Telechargement de Wings"
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"

# Attribution des droits
printf "$green" "[INFO] Attributation des droits a Wings"
chmod u+x /usr/local/bin/wings

# Demander une confirmation à l'utilisateur
echo "Se rendre sur le panel Pterodactyl pour creer une Node, plus d'informations : https://pterodactyl.io/wings/1.0/installing.html#configure"
read -p "Avez-vous creer une Node ? (o/n) :" reponse

# Vérifier la réponse
if [[ "$reponse" == "o" || "$reponse" == "O" ]]; then
    file="/etc/pterodactyl/config.yml"

    nano "$file"
else
    echo "[INFO] Se referer a la documentation pour finaliser l'installation."
    read -p "Appuyer sur une touche pour fermer." -n 1 -s reponse
    exit
fi

# Daemonizing Wings (using systemd)
#Place the contents below in a file called wings.service in the /etc/systemd/system directory.
printf "$green" "[INFO] Création du service Wings (deamininzing Wings)"

echo "[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/wings.service

printf "$green" "[INFO] Activation du service Wings"
sudo systemctl enable --now wings

printf "$yellow" "[INFO] Redemarrage necessaire"
read -p "Appuyer sur une touche pour redémarrer." -n 1 -s reponse

# Redémarrer le système
sudo reboot
