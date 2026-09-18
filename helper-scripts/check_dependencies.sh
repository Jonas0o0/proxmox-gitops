#!/bin/bash

echo "--- Vérification des prérequis de l'infrastructure ---"

# Codes couleurs pour un affichage lisible
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Liste des dépendances à vérifier
DEPENDENCIES=("git" "terraform" "ansible" "sops" "age" "j2")
MISSING_COUNT=0

# Demander pour Github CLI
read -r -p "Voulez-vous utiliser Github CLI (gh) pour ajouter automatiquement les secrets sur le repo ? (o/N) : " USE_GH < /dev/tty
if [[ "$USE_GH" =~ ^[OoYy]$ ]]; then
    DEPENDENCIES+=("gh")
    echo "USE_GH=true" > .setup_env
else
    echo "USE_GH=false" > .setup_env
fi

# Variables pour stocker les commandes d'installation manquantes
MISSING_TOOLS=()

# Boucle de vérification
for cmd in "${DEPENDENCIES[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        VERSION=$("$cmd" --version | head -n 1 | cut -d' ' -f1-3)
        echo -e "[${GREEN}OK${NC}] $cmd est installé -> $VERSION"
    else
        echo -e "[${RED}ERREUR${NC}] $cmd n'est pas installé ou n'est pas dans le PATH."
        MISSING_COUNT=$((MISSING_COUNT + 1))
        MISSING_TOOLS+=("$cmd")
    fi
done

echo "------------------------------------------------------"

# Fonction pour afficher l'aide à l'installation
print_install_help() {
    echo -e "${RED}Il vous manque des dépendances. Voici comment les installer sur Ubuntu/Debian :${NC}\n"
    
    for tool in "${MISSING_TOOLS[@]}"; do
        case $tool in
            "git"|"ansible"|"age"|"gh")
                echo "- $tool : sudo apt install -y $tool"
                ;;
            "j2")
                echo "- j2 (j2cli) : sudo apt install -y j2cli (ou pip3 install j2cli)"
                ;;
            "terraform")
                echo "- terraform :"
                echo "  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
                echo "  echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list"
                echo "  sudo apt update && sudo apt install -y terraform"
                ;;
            "sops")
                echo "- sops :"
                echo "  wget https://github.com/getsops/sops/releases/download/v3.8.1/sops_3.8.1_amd64.deb"
                echo "  sudo dpkg -i sops_3.8.1_amd64.deb"
                ;;
        esac
    done
}

# Bilan final et code de sortie
if [ "$MISSING_COUNT" -gt 0 ]; then
    print_install_help
    echo -e "\n${RED}Échec : Veuillez installer les dépendances manquantes avant de continuer.${NC}"
    exit 1
else
    echo -e "${GREEN}Succès : Toutes les dépendances sont prêtes !${NC}"
    exit 0
fi
