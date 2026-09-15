#!/bin/bash

echo "--- Vérification des prérequis de l'infrastructure ---"

# Codes couleurs pour un affichage lisible
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Liste des dépendances à vérifier
DEPENDENCIES=("git" "terraform" "ansible" "sops" "age" "j2")
MISSING_COUNT=0

# Boucle de vérification
for cmd in "${DEPENDENCIES[@]}"; do
    # 'command -v' vérifie si la commande existe dans le système
    if command -v "$cmd" >/dev/null 2>&1; then
        # On récupère juste la première ligne de la commande de version pour faire propre
        VERSION=$("$cmd" --version | head -n 1 | cut -d' ' -f1-3)
        echo -e "[${GREEN}OK${NC}] $cmd est installé -> $VERSION"
    else
        echo -e "[${RED}ERREUR${NC}] $cmd n'est pas installé ou n'est pas dans le PATH."
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done

echo "------------------------------------------------------"

# Bilan final et code de sortie
if [ "$MISSING_COUNT" -gt 0 ]; then
    echo -e "${RED}Échec : Il manque $MISSING_COUNT dépendance(s). Veuillez les installer.${NC}"
    exit 1 # Renvoie une erreur au système
else
    echo -e "${GREEN}Succès : Toutes les dépendances sont prêtes !${NC}"
    exit 0 # Tout s'est bien passé
fi
