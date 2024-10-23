#! /bin/bash

# Sources :     - https://pterodactyl.io/community/installation-guides/panel/debian.html
#               - https://pterodactyl.io/panel/1.0/getting_started.html#download-files
#               - https://pterodactyl.io/wings/1.0/installing.html
#               - https://stackoverflow.com/questions/66158318/couldnt-find-any-package-by-glob-php8-0-in-debian


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

# ----------------------------------------------------- Debut du script -----------------------------------------------------

# ------------------------ Installation de l'environnement ------------------------

source .env

LOCAL_MYSQL_PASSWORD=$(echo "${MYSQL_PASSWORD}" | tr -d '\r')
LOCAL_PTERODACTYL_EMAIL=$(echo "${PTERODACTYL_EMAIL}" | tr -d '\r')
LOCAL_PTERODACTYL_LOGIN=$(echo "${PTERODACTYL_LOGIN}" | tr -d '\r')
LOCAL_PTERODACTYL_NAME=$(echo "${PTERODACTYL_NAME}" | tr -d '\r')
LOCAL_PTERODACTYL_LASTNAME=$(echo "${PTERODACTYL_LASTNAME}" | tr -d '\r')
LOCAL_PTERODACTYL_PASSWORD=$(echo "${PTERODACTYL_PASSWORD}" | tr -d '\r')

printf "$green" "[INFO] Installation de software-properties-common, curl, ca-certificates, gnupg2"

apt -y install software-properties-common curl ca-certificates gnupg2 sudo lsb-release

# Ajout de repertoires supplementaire pour PHP
printf "$green" "[INFO] AJout de repertoires supplementaire pour PHP"
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg

# Ajout du repertoire APT officiel de Redis
printf "$green" "[INFO] Ajout du repertoire APT officiel de Redis"
curl -fsSL https://packages.redis.io/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

printf "$green" "[INFO] APT UPDATE"
sudo apt update

# Repertoire setup script MariaDB
printf "$green" "[INFO] Execution du setup script de MariaDB"
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Necessaire pour l'installation de PHP 8.3, car glob ne contient pas le package
printf "$green" "[INFO] Installation de apt-transport-https"
apt install apt-transport-https

printf "$green" "[INFO] APT UPDATE"
sudo apt update

printf "$green" "[INFO] Installation de PHP 8.3, MariaDB-server, nginx, tar, unzip, git, redis-server"
apt install -y php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server

# Installation de Composer
printf "$green" "[INFO] Installation de Composer"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer


# ---------------------------- Pterodactyl Installation ---------------------------
    
# Telechargement des fichier Pterodactyl
printf "$green" "[INFO] Telechargement des fichiers Pterodactyl"
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# Database Config
printf "$green" "[INFO] Configuration de la base de donnees MariaDB"
mariadb -u root -e 'CREATE USER "pterodactyl"@"127.0.0.1" IDENTIFIED BY "'"${LOCAL_MYSQL_PASSWORD}"'";'
mariadb -u root -e 'CREATE DATABASE panel;'
mariadb -u root -e 'GRANT ALL PRIVILEGES ON panel.* TO "pterodactyl"@"127.0.0.1" WITH GRANT OPTION;'

printf "$green" "[INFO] Installation de Pterodactyl"
cp .env.example .env
export COMPOSER_ROOT_VERSION=1.0.0
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# ------------------------------------- /!\ DANGER /!\ ------------------------------------------------ #
# Back up your encryption key (APP_KEY in the .env file). It is used as an encryption key for all	    #
# data that needs to be stored securely (e.g. api keys). Store it somewhere safe - not just on your 	#
# server. If you lose it all encrypted data is irrecoverable -- even if you have database backups.	    #
# ----------------------------------------------------------------------------------------------------- #

printf "$green" "[INFO] Generation de la cle de chiffement"
php artisan key:generate --force

# Configuration de l'environnement
printf "$green" "[INFO] Configuration de l'environnement PHP"
# Author Email, Application URL, Application Time Zone, Cache Driver, Session Driver, Queue Driver, Enable UI based settings editor, Enable sending anonymous telemetry data, Redis host, Redis Password
php artisan p:environment:setup <<EOF
test@test.com
panel.cs_server.com
Europe/Paris
redis
redis
redis
yes
no
127.0.0.1

EOF

# Database host (127.0.0.1), Database Port (3306), Database name (panel), Database username (pterodactyl), Database password
php artisan p:environment:database --no-interaction --password="${LOCAL_MYSQL_PASSWORD}"

# Database setup
printf "$green" "[INFO] Setup de la base de données PHP"
php artisan migrate --seed --force

# Ajout du premier utilisateur (admin)
printf "$green" "[INFO] Création de premier utilisateur (admin)"
php artisan p:user:make --no-interaction --admin=1 --email="${LOCAL_PTERODACTYL_EMAIL}" --username="${LOCAL_PTERODACTYL_LOGIN}" --name-first="${LOCAL_PTERODACTYL_NAME}" --name-last="${LOCAL_PTERODACTYL_LASTNAME}" --password="${LOCAL_PTERODACTYL_PASSWORD}"

# Set Permissions
printf "$green" "[INFO] Mise a jour des permission du panel Pterodactyl"
chown -R www-data:www-data /var/www/pterodactyl/*

# Crontab Configuration
printf "$green" "[INFO] Creation d'un Crontab pour l'execution des taches Pterodactyl"
# The first thing we need to do is create a new cronjob that runs every minute to process specific Pterodactyl tasks, such as session cleanup and sending scheduled tasks to daemons.
#write out current crontab
crontab -l > mycron
#echo new cron into cron file
echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1" >> mycron
#install new cron file
crontab mycron
rm mycron

# Create Queue Worker
printf "$green" "[INFO] Creation d'un Pterodactyl Queue Worker"
# Create the file 'pteroq.service' in '/etc/systemd/system' with the contents below
echo "# Pterodactyl Queue Worker File
# ----------------------------------

[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
# On some systems the user and group might be different.
# Some systems use 'apache' or 'nginx' as the user and group.
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/pteroq.service

# Start on boot
printf "$green" "[INFO] Demarrage du serveur Redis"
sudo systemctl enable --now redis-server

# Enable the service
printf "$green" "[INFO] Activation du Pterodactyl Queue Worker"
sudo systemctl enable --now pteroq.service


# ---------------------------- Configuration Webserver ----------------------------
printf "$green" "[INFO] Configuration du Webserver"

# Nginx sans SSL
rm /etc/nginx/sites-enabled/default

echo "server {
    # Replace the example <domain> with your domain name or IP address
    listen 8000;
    server_name 127.0.0.1;

    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE \"upload_max_filesize = 100M \\n post_max_size=100M\";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY \"\";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}" > /etc/nginx/sites-available/pterodactyl.conf

# Ajout du webserver dans la liste des sites actifs
ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf

# Reboot Nginx
printf "$green" "[INFO] Redemarrage du Webserver (nginx)"
sudo systemctl restart nginx

printf "$yellow" "# ------------------------------------------------------- /!\ DANGER /!\ ------------------------------------------------------ #
# Back up your encryption key (APP_KEY in the /var/www/pterodactyl/.env file). It is used as an encryption key for all	        #
# data that needs to be stored securely (e.g. api keys). Store it somewhere safe - not just on your                             #
# server. If you lose it all encrypted data is irrecoverable -- even if you have database backups.	                            #
# ----------------------------------------------------------------------------------------------------------------------------- #"


