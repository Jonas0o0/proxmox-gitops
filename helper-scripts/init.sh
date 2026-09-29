#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CONFIGURATION GLOBALE
# ==============================================================================
ENV_NAME="${1:-production}"
TFVARS_DIR="terraform/environments/${ENV_NAME}"
VERSIONS_DIR="${TFVARS_DIR}/core"

KEYS_DIR="$HOME/.config/sops/age"
KEY_FILE="$KEYS_DIR/keys.txt"
EDITOR="${EDITOR:-sops}"

declare -a SECRETS_TO_GENERATE=(
    "settings.source.yml|settings.enc.yml|Configuration globale (Source de vérité)"
)

DEPENDENCIES=("git" "terraform" "ansible-playbook" "sops" "age-keygen" "awk" "grep" "sed")

# ==============================================================================
# INITIALISATION ET TRAP (Nettoyage)
# ==============================================================================
TMP_DIR=$(mktemp -d)
TMP_SECRET_FILE="$TMP_DIR/secret.enc.yml"
trap 'rm -rf "$TMP_DIR"' EXIT

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

# ==============================================================================
# FONCTIONS UTILITAIRES
# ==============================================================================
log_info()    { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warn()    { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_error()   { echo -e "${RED}[ERREUR] $1${NC}"; }

check_dependencies() {
    log_info "Vérification des dépendances..."
    local missing=()
    for cmd in "${DEPENDENCIES[@]}"; do
        command -v "$cmd" &> /dev/null || missing+=("$cmd")
    done

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Outils manquants : ${missing[*]}"
        exit 1
    fi
}

setup_sops_age() {
    log_info "Configuration SOPS / AGE..."
    if [ ! -f "$KEY_FILE" ]; then
        mkdir -p "$KEYS_DIR"
        age-keygen -o "$KEY_FILE" 2>/dev/null
        log_success "Clé AGE générée dans $KEY_FILE"
    fi

    export SOPS_AGE_KEY_FILE="$KEY_FILE"

    local pub_key
    pub_key=$(grep -o 'age1.*' "$KEY_FILE" || true)

    if [ -n "$pub_key" ]; then
        if [ -f ".sops.yaml" ]; then
            # Utilisation de .bak pour assurer la compatibilité entre GNU/Linux et macOS (BSD)
            sed -i.bak "s/age: .*/age: \"$pub_key\"/" .sops.yaml
            rm -f .sops.yaml.bak
            log_success "Fichier .sops.yaml mis à jour avec votre clé publique."
        else
            log_info "Création du fichier .sops.yaml..."
            cat <<EOF > .sops.yaml
creation_rules:
  - path_regex: .*\.enc\.(ya?ml|tfvars)$
    age: "$pub_key"
EOF
            log_success "Fichier .sops.yaml généré avec votre clé publique."
        fi
        
        # Mise à jour des clés sur les fichiers existants si besoin
        if command -v sops &> /dev/null; then
            for enc_file in $(find . -type f -name "*.enc.yml" -o -name "*.enc.tfvars"); do
                sops updatekeys -y "$enc_file" 2>/dev/null || true
            done
        fi
    fi
}

generate_secret() {
    local template="$1"
    local secret="$2"
    local desc="$3"

    log_info "Traitement de : $desc"

    if [ -f "$secret" ]; then
        log_success "-> Déjà configuré. Ignoré."
        return 0
    fi

    if [ ! -f "$template" ]; then
        log_warn "-> Template introuvable ($template). Ignoré."
        return 0
    fi

    sops -e "$template" > "$secret"

    log_warn "-> L'éditeur va s'ouvrir. Remplissez les valeurs."
    read -p "Appuyez sur Entrée..."
    $EDITOR "$secret"
    log_success "-> Chiffré et sauvegardé."
}

# ==============================================================================
# SCRIPT PRINCIPAL
# ==============================================================================
echo "==========================================================="
echo -e "${BLUE}[INFO] Initialisation Proxmox GitOps (Env: $ENV_NAME)${NC}"
echo "==========================================================="

check_dependencies

log_info "Configuration des git hooks..."
git config core.hookspath .githooks 2>/dev/null || log_warn "Git non initialisé dans ce dossier."

setup_sops_age

for item in "${SECRETS_TO_GENERATE[@]}"; do
    IFS="|" read -r tpl sec desc <<< "$item"
    generate_secret "$tpl" "$sec" "$desc"
done

cat "$(dirname "$0")/next_steps.txt"
cat "$KEY_FILE"
echo ""