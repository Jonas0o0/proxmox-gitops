#!/bin/bash

set -e

TFVARS_DIR="terraform/environments/production"
TFVARS_ENC="$TFVARS_DIR/terraform.enc.tfvars"
TFVARS_TMP="$TFVARS_DIR/terraform.tfvars.tmp"
TFVARS_TEMPLATE="$TFVARS_DIR/terraform.tfvars.j2"

echo "[INFO] Génération de la clé SOPS et configuration Terraform"
echo "---------------------------------------------------"

# 1. Génération de la clé AGE
AGE_DIR="$HOME/.config/sops/age"
AGE_KEY_FILE="$AGE_DIR/keys.txt"

if [ ! -f "$AGE_KEY_FILE" ]; then
    echo "[INFO] Génération d'une nouvelle clé AGE dans $AGE_KEY_FILE..."
    mkdir -p "$AGE_DIR"
    age-keygen -o "$AGE_KEY_FILE"
else
    echo "[INFO] Clé AGE existante trouvée."
fi

AGE_PUB_KEY=$(grep 'public key:' "$AGE_KEY_FILE" | awk '{print $4}')
echo "[INFO] Clé publique AGE : $AGE_PUB_KEY"

# 2. Mise à jour de .sops.yaml
SOPS_YAML=".sops.yaml"
if [ -f "$SOPS_YAML" ]; then
    echo "[INFO] Mise à jour de $SOPS_YAML..."
    cat > "$SOPS_YAML" <<EOF
# https://github.com/getsops/sops
creation_rules:
  - path_regex: .*\.enc\.(ya?ml|tfvars)$
    age: "${AGE_PUB_KEY}"
EOF
fi

# 3. Secret GitHub
if grep -q "USE_GH=true" .setup_env 2>/dev/null; then
    echo "[INFO] Ajout du secret SOPS_AGE_KEY via GitHub CLI..."
    gh secret set SOPS_AGE_KEY < "$AGE_KEY_FILE"
    echo "[SUCCESS] Secret ajouté avec succès."
else
    echo -e "\n==========================================================="
    echo "[RECAP] À FAIRE MANUELLEMENT SUR GITHUB :"
    echo "Allez dans Settings -> Secrets and variables -> Actions -> New repository secret"
    echo "Nom : SOPS_AGE_KEY"
    echo "Valeur : (copiez le contenu ci-dessous)"
    echo "-----------------------------------------------------------"
    cat "$AGE_KEY_FILE"
    echo "-----------------------------------------------------------"
    echo "==========================================================="
fi
echo ""

if [ ! -f "$TFVARS_TEMPLATE" ]; then
    echo "[ERROR] Template introuvable : $TFVARS_TEMPLATE"
    exit 1
fi

read -r -p "Adresse du host Proxmox (ex: https://192.168.1.10:8006) : " proxmox_host < /dev/tty
read -r -p "Utilisateur (ex: terraform) : " proxmox_user < /dev/tty
read -r -p "Realm (ex: pve) : " proxmox_realm < /dev/tty
read -r -p "Token ID (ex: tf) : " proxmox_token_id < /dev/tty
read -r -s -p "Secret du token (champ masqué): " proxmox_token_secret < /dev/tty
echo ""
read -r -p "Chemin clé privée SSH (ex: ~/.ssh/id_rsa) : " ssh_private_key_path < /dev/tty
read -r -p "Chemin clé publique SSH (ex: ~/.ssh/id_rsa.pub) : " ssh_public_key_path < /dev/tty
read -r -p "Nom du stockage (ex: local-lvm) : " storage < /dev/tty
read -r -p "Nom du stockage pour les backups minimaux (ex: local-lvm) : " backup_storage < /dev/tty
read -r -p "Nom du node (ex: pve) : " node_name < /dev/tty

mkdir -p "$TFVARS_DIR"

TF_PROXMOX_HOST="${proxmox_host%/}" \
TF_PROXMOX_USER="$proxmox_user" \
TF_PROXMOX_REALM="$proxmox_realm" \
TF_PROXMOX_TOKEN_ID="$proxmox_token_id" \
TF_PROXMOX_TOKEN_SECRET="$proxmox_token_secret" \
TF_PROXMOX_SSH_PRIVATE_KEY_PATH="$ssh_private_key_path" \
TF_PROXMOX_SSH_PUBLIC_KEY_PATH="$ssh_public_key_path" \
TF_STORAGE="$storage" \
TF_BACKUP_STORAGE="$backup_storage" \
TF_NODE_NAME="$node_name" \
TF_PROXMOX_HOST_IP="$proxmox_host_ip" \
TF_PROXMOX_LAN_SUBNET="$proxmox_lan_subnet" \
j2 "$TFVARS_TEMPLATE" > "$TFVARS_TMP"

echo "[INFO] Chiffrement du fichier terraform variables..."
sops --input-type binary --output-type binary -e "$TFVARS_TMP" > "$TFVARS_ENC"
rm "$TFVARS_TMP"

echo "[SUCCESS] Fichier $TFVARS_ENC chiffré et généré avec succès !"
