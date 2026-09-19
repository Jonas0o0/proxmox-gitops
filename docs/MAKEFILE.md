# Documentation du Makefile

Ce document décrit l'utilisation et le comportement du `Makefile` central du projet. Le Makefile standardise les opérations courantes sur l'infrastructure (Terraform, Ansible, SOPS) pour les environnements de développement locaux et d'intégration continue (CI).

## Vue d'ensemble

Le `Makefile` encapsule les commandes complexes et la gestion de l'environnement dans des cibles simples. Ses fonctionnalités principales incluent :
- Le chargement de configurations spécifiques à l'environnement (ex: identifiants du backend distant).
- Le déchiffrement transparent et à la volée des variables chiffrées par SOPS.
- L'exécution standardisée des playbooks Ansible.

## Variables d'Environnement et de Configuration

Le Makefile s'appuie sur les variables par défaut suivantes, qui peuvent être surchargées lors de l'exécution :

- `TF_DIR` (Défaut : `terraform/environments/production`) : Le répertoire racine des couches Terraform.
- `TF_LAYER` (Défaut : `core`) : La couche Terraform spécifique à cibler (ex: `core`, `bootstrap`).
- `ANSIBLE_INVENTORY` (Défaut : `ansible/inventories/inventory.yml`) : Le fichier principal d'inventaire Ansible.
- `ANSIBLE_INVENTORIES` (Défaut : `ansible/inventories`) : Le répertoire contenant tous les inventaires Ansible.
- `SERVICE` : Le nom du service cible requis pour les commandes de déploiement ou de gestion des secrets.
- `EXTRA_ARGS` : Arguments optionnels passés en suffixe aux commandes Ansible.

## Référence des Cibles

### Commandes Terraform (`tf-*`)

La cible principale `tf` gère le contexte d'exécution pour Terraform. Avant de lancer l'action spécifiée, elle effectue les étapes suivantes :
1. Navigation vers le répertoire `$(TF_DIR)/$(TF_LAYER)`.
2. Chargement du fichier `./remote-backend-init.sh` s'il est présent (requis pour l'authentification du backend HTTP).
3. Vérification de la présence de `../terraform.enc.tfvars`. S'il est trouvé, exécution de `sops exec-file` pour déchiffrer les variables en mémoire et les injecter via le paramètre `-var-file`. Si seul `../terraform.tfvars` est présent, il est utilisé directement.

| Cible | Description |
|---|---|
| `tf-init` | Initialise le répertoire de travail Terraform et le backend pour la couche `TF_LAYER` spécifiée. |
| `tf-plan` | Génère et affiche un plan d'exécution pour la couche `TF_LAYER` spécifiée. |
| `tf-apply` | Applique le plan d'exécution pour provisionner ou mettre à jour l'infrastructure de la couche `TF_LAYER`. |
| `tf-destroy` | Détruit l'infrastructure gérée par Terraform pour la couche `TF_LAYER`. |
| `tf` | Cible de base. Requiert la variable `ACTION` (ex: `make tf ACTION="apply -auto-approve"`). |

### Commandes de Déploiement (Ansible / Docker)

Toutes les cibles de déploiement contournent la vérification stricte des clés d'hôtes SSH (`ANSIBLE_STRICT_HOST_KEY_CHECKING=false`) afin de permettre les déploiements automatisés sur des noeuds éphémères.

| Cible | Description |
|---|---|
| `deploy-compose` | Déploie un service Docker Compose (`SERVICE`). Exécute le playbook `deploy_any_compose.yml` de manière interactive (utilise `-K` pour demander les privilèges sudo). |
| `deploy-compose-ci` | Version adaptée à la CI de `deploy-compose`. S'exécute sans demander de mot de passe sudo. |
| `deploy-alloy` | Déploie l'agent de télémétrie Grafana Alloy via le playbook `install_alloy.yml` sur l'inventaire par défaut. |
| `deploy-lxc` | Initialise les conteneurs LXC via le playbook `bootstrap.yml` en utilisant l'inventaire spécifique `lxc_inventory.yml`. |

### Gestion des Secrets

| Cible | Description |
|---|---|
| `edit-secrets` | Ouvre le fichier de secrets centralisé `settings.enc.yml` chiffré par SOPS dans l'éditeur de texte par défaut (`vim`). Les modifications sont chiffrées automatiquement lors de la sauvegarde. |

### Assurance Qualité et Sécurité (Linters)

Les cibles de linting utilisent des conteneurs Docker pour garantir une exécution cohérente sans nécessiter l'installation locale des outils sous-jacents.

| Cible | Description |
|---|---|
| `lint-checkov` | Analyse le dépôt à la recherche de mauvaises configurations et de vulnérabilités (IaC) à l'aide de `bridgecrew/checkov`. |
| `lint-tflint` | Valide la syntaxe Terraform et applique les bonnes pratiques de manière récursive à l'aide de `terraform-linters/tflint`. |

## Exemples d'Utilisation

**Terraform :**
```bash
# Appliquer les changements sur la couche par défaut (core)
make tf-apply

# Générer un plan pour la couche bootstrap
make tf-plan TF_LAYER=bootstrap
```

**Déploiement :**
```bash
# Déployer le service 'monitoring' interactivement
make deploy-compose SERVICE=monitoring

# Lancer l'initialisation des LXC
make deploy-lxc
```

**Secrets :**
```bash
# Éditer les secrets
make edit-secrets
```
