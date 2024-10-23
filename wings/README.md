# Wings

## Aperçu
Wings est le système de gestion des serveurs de Pterodactyl, conçu pour exécuter et gérer les instances de serveurs de jeux sur des machines distantes. En tant que composant essentiel de l'architecture Pterodactyl, Wings fonctionne en arrière-plan pour garantir que les serveurs de jeux sont déployés, supervisés et gérés de manière efficace.

## Ce qui doit être modifié
Configuration des VLAN via le script [conf_VLAN.sh](./conf_VLAN.sh) qui sera executé lors de l'installation.

## Installation
Telecharger le dossier
```
sudo apt-get install -y wget
wget -r --no-parent -nH --cut-dirs=3 -R index.html https://github.com/Jeroneo/cs2_server_ebot_LAN/raw/main/wings/
```

Modification de conf_VLAN.sh
```
nano conf_VLAN.sh
```

Exécution du script en tant que root
```
su -
bash install_wings.sh
```

Pour la création d'une node sur le panel Pterodactyl, suivre la documentation officielle [disponible ici](https://pterodactyl.io/wings/1.0/installing.html#configure).