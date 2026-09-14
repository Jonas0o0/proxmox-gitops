#!/bin/bash

# lance tous les scripts de setup

# Interrompt le script au moindre échec d'une commande
set -e

echo "==========================================================="
echo "[INFO] Initialisation de l'infrastructure Proxmox GitOps"
echo "==========================================================="

REPO_URL="https://github.com/jobacogiez-org/proxmox-gitops.git"
REPO_DIR="proxmox-gitops"
BRANCH="main"

echo -e "\n[ÉTAPE 0/6] Récupération du dépôt Git..."
if [ -d "$REPO_DIR" ]; then
    echo "[INFO] Le dossier '$REPO_DIR' existe déjà. Mise à jour (git pull)..."
    cd "$REPO_DIR"
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    echo "[INFO] Clonage de la branche $BRANCH depuis $REPO_URL..."
    git clone -b "$BRANCH" "$REPO_URL"
    cd "$REPO_DIR"
fi

echo "[INFO] Configuration des permissions d'exécution..."
chmod +x helper-scripts/check_dependencies.sh helper-scripts/create_tfvars_credentials.sh helper-scripts/launch_terraform_by_layer.sh helper-scripts/create_repo_settings.sh
git config core.hookspath .githooks

echo -e "\n[ÉTAPE 1/5] Vérification des dépendances (outils CLI)..."
./helper-scripts/check_dependencies.sh

echo -e "\n[ÉTAPE 2/5] Création de la configuration Proxmox (tfvars)..."
./helper-scripts/create_tfvars_credentials.sh < /dev/tty

TFVARS_PATH="terraform/environments/production/terraform.tfvars"

echo -e "\n[ÉTAPE 3/5] Déploiement de la couche 'bootstrap' (Terraform)..."
./helper-scripts/launch_terraform_by_layer.sh "$TFVARS_PATH" "bootstrap"

echo -e "\n[ÉTAPE 4/5] Génération de la configuration globale (settings.yml)..."
./helper-scripts/create_repo_settings.sh < /dev/tty

echo -e "\n[ÉTAPE 5/5] Déploiement de la couche 'core' (Terraform)..."
./helper-scripts/launch_terraform_by_layer.sh "$TFVARS_PATH" "core"

echo -e "\n==========================================================="
echo "[SUCCESS] L'initialisation de l'infrastructure est terminée."
echo "==========================================================="
