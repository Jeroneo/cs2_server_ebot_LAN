#! /bin/bash

sudo apt-get update
sudo apt-get install vlan

# Activer le module 8021q
sudo modprobe 8021q

# Pour le charger automatiquement au démarrage
echo "8021q" | sudo tee -a /etc/modules

echo "# VLAN pour PROD
auto eth0.10 # Utilise l'ID VLAN 10 pour PROD
iface eth0.10 inet static
    address 192.168.1.10 # IP de PROD
    netmask 255.255.255.0 # masque de sous-réseau
    gateway 192.168.1.1 # passerelle
    dns-nameservers 1.1.1.1 1.0.0.1  # serveurs DNS ici
    vlan-raw-device eth0

# VLAN pour joueurs CS
auto eth0.20 # Utilise l'ID VLAN 20 pour les joueurs CS
iface eth0.20 inet static
    address 192.168.2.10 # IP des joueurs CS
    netmask 255.255.255.0 # masque de sous-réseau
    dns-nameservers 1.1.1.1 1.0.0.1  # serveurs DNS ici
    vlan-raw-device eth0
" > /etc/network/interfaces

sudo systemctl restart networking
