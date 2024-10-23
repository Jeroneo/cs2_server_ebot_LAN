# Pterodactyl

## Aperçu
Pterodactyl est une plateforme de gestion de serveurs de jeux et d'applications, qui permet aux utilisateurs de créer, gérer et déployer des serveurs de manière intuitive et efficace. Conçu pour les développeurs et les administrateurs, Pterodactyl utilise une architecture moderne basée sur des conteneurs pour garantir des performances optimales et une évolutivité facile.

## Ce qui doit être modifié

Modification du fichier env.sample avec vos informations

```
MYSQL_PASSWORD=yourPassword
PTERODACTYL_EMAIL=admin@UTTArena.com
PTERODACTYL_LOGIN=admin
PTERODACTYL_NAME=admin
PTERODACTYL_LASTNAME=admin
PTERODACTYL_PASSWORD=admin
```

```
nano env.sample
```

## Installation des serveurs CS

### Installation de l'egg CS2

Pour créer ses serveurs, Ptérodactyl utilise des "eggs". Un egg est un template qui va permettre de créer un serveur avec une configuration spécifique. Il existe des eggs pour de nombreux jeux, dont CS2.

Pour installer un egg, il faut se rendre dans l'interface d'administration de Ptérodactyl, puis dans l'onglet "Nests" et enfin dans l'onglet "Eggs". Il faut ensuite cliquer sur "Import Egg".

On peut utiliser l'egg CS2 disponible [ici](./egg_cs2_GOTV.json).

### Création des serveurs CS

Pour créer les serveurs CS, il faut se rendre dans l'interface d'administration de Ptérodactyl, puis dans l'onglet "Servers" et enfin dans l'onglet "Create". Il faut ensuite choisir l'egg CS2 et le serveur / port sur lequel on veut créer le serveur. Il faut ensuite remplir les champs demandés. 

Il faut bien penser à allouer un deuxième port pour la GOTV.

Attention, lors de la création d'un serveur, il faut renseigner le RCON (pour le contrôle du serveur par Ebot) et le port de la GOTV.
