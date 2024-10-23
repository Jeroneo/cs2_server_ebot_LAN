# eBot Docker

## Aperçu
Il s'agit d'une version conteneurisée d'eBot, qui est un serveur-bot entièrement géré, écrit en PHP et en Node.js. eBot propose une création de matchs facile et de nombreuses statistiques sur les joueurs et les matchs. Une fois configuré, l'utilisation d'eBot est simple et rapide.
Le coontrôle des serveurs est réalisé via le RCON.

## Ce qui doit être modifié

Modification du fichier env.sample avec vos informations

```
COMPOSE_PROJECT_NAME=ebot

# Configuration d'eBot
EBOT_IP=192.168.1.x
LOG_ADDRESS_SERVER=http://192.168.1.x:12345
EBOT_ADMIN_LOGIN=admin
EBOT_ADMIN_PASSWORD=admin
EBOT_ADMIN_EMAIL=admin@admin
WEBSOCKET_SECRET_KEY=websocket_key
COMMAND_STOP_DISABLED=true
WEBSOCKET_URL=http://192.168.1.x:12360

# Configuration de la base de données
MYSQL_USER=ebotv3
MYSQL_DATABASE=ebotv3
MYSQL_PASSWORD=ebotv3
MYSQL_ROOT_PASSWORD=ebotv3
```

Pour ce faire:
```
nano env.sample
```

Les champs EBOT_IP, LOG_ADDRESS_SERVER et WEBSOCKET_URL seront automatiquement modifiés lors de l'installation.

## Crédits

- [deStrO](https://github.com/deStrO/eBot-docker)
