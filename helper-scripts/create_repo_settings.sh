#!/bin/bash

set -e

SETTINGS_TMP="settings.yml.tmp"
SETTINGS_ENC="settings.enc.yml"
SETTINGS_TEMPLATE="settings.yml.j2"

echo "[INFO] Génération du fichier de configuration (settings.yml)"
echo "---------------------------------------------------"

echo "--- Configuration Globale ---"
read -r -p "Domaine principal [votre-domaine.fr] : " domain < /dev/tty
domain=${domain:-"votre-domaine.fr"}

read -r -p "Organisation ou User GitHub [votre-orga] : " github_org < /dev/tty
github_org=${github_org:-"votre-orga"}

read -r -p "Dépôt GitHub [proxmox-gitops] : " github_repo < /dev/tty
github_repo=${github_repo:-"proxmox-gitops"}

read -r -p "Timezone [Europe/Paris] : " timezone < /dev/tty
timezone=${timezone:-"Europe/Paris"}

read -r -p "Utilisateur Admin [admin] : " admin_user < /dev/tty
admin_user=${admin_user:-"admin"}

echo -e "\n--- Infrastructure Proxmox ---"
read -r -p "Endpoint Proxmox [https://pve.home.arpa:8006/api2/json] : " px_endpoint < /dev/tty
px_endpoint=${px_endpoint:-"https://pve.home.arpa:8006/api2/json"}

read -r -p "Nom du noeud Proxmox [homelab] : " px_node < /dev/tty
px_node=${px_node:-"homelab"}

read -r -p "Stockage [local-lvm] : " px_storage < /dev/tty
px_storage=${px_storage:-"local-lvm"}

read -r -p "Utilisateur SSH [root] : " px_ssh_user < /dev/tty
px_ssh_user=${px_ssh_user:-"root"}

export SETTINGS_DOMAIN="$domain"
export SETTINGS_GITHUB_ORG="$github_org"
export SETTINGS_GITHUB_REPO="$github_repo"
export SETTINGS_TIMEZONE="$timezone"
export SETTINGS_ADMIN_USER="$admin_user"
export SETTINGS_PROXMOX_ENDPOINT="$px_endpoint"
export SETTINGS_PROXMOX_NODE="$px_node"
export SETTINGS_PROXMOX_STORAGE="$px_storage"
export SETTINGS_PROXMOX_SSH_USER="$px_ssh_user"

j2 "$SETTINGS_TEMPLATE" > "$SETTINGS_TMP"
j2 "terraform/environments/production/core/versions.tf.j2" > "terraform/environments/production/core/versions.tf"

echo "[INFO] Chiffrement de $SETTINGS_ENC..."
sops -e "$SETTINGS_TMP" > "$SETTINGS_ENC"
rm "$SETTINGS_TMP"

echo "[SUCCESS] Fichier $SETTINGS_ENC chiffré généré avec succès."
