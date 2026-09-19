#!/bin/bash

# lance tous les scripts de setup

# Interrompt le script au moindre échec d'une commande
set -e

echo "==========================================================="
echo "[INFO] Initialisation de l'infrastructure Proxmox GitOps"
echo "==========================================================="

echo "[INFO] Configuration des permissions d'exécution..."
chmod +x helper-scripts/check_dependencies.sh helper-scripts/create_tfvars_credentials.sh helper-scripts/create_repo_settings.sh
git config core.hookspath .githooks

echo -e "\n[ÉTAPE 1/5] Vérification des dépendances (outils CLI)..."
./helper-scripts/check_dependencies.sh

echo -e "\n[ÉTAPE 2/5] Création de la configuration Proxmox (tfvars)..."
./helper-scripts/create_tfvars_credentials.sh < /dev/tty

TFVARS_PATH="terraform/environments/production/terraform.enc.tfvars"

echo -e "\n[ÉTAPE 3/5] Déploiement de la couche 'bootstrap' (Terraform)..."
make tf TF_LAYER=bootstrap ACTION=init
make tf TF_LAYER=bootstrap ACTION="apply -auto-approve"

echo -e "\n[ÉTAPE 4/5] Génération de la configuration globale (settings.yml)..."
./helper-scripts/create_repo_settings.sh < /dev/tty

echo -e "\n[ÉTAPE 5/5] Déploiement de la couche 'core' (Terraform)..."
make tf TF_LAYER=core ACTION=init
make tf TF_LAYER=core ACTION="apply -auto-approve"

echo -e "\n==========================================================="
echo "[SUCCESS] L'initialisation de l'infrastructure est terminée."
echo "==========================================================="
