# Quickstart

Cette documentation a pour but de vous guider dans la mise en place de ce projet de GitOps.

## 1. Installation de Proxmox

Dans cette partie, nous partons du principe que vous avez créé une clé USB bootable à partir de l'ISO de Proxmox. Si ce n'est pas le cas, nous vous invitons à télécharger l'ISO [ici](https://www.proxmox.com/en/downloads/proxmox-virtual-environment) et à créer votre média d'installation (avec un outil comme BalenaEtcher ou Rufus).

### Choix du stockage

![Option](https://pve.proxmox.com/pve-docs/images/screenshot/pve-select-target-disk.png)

Lors de l'installation, nous recommandons d'utiliser au minimum le système de fichiers **ZFS (RAID 1)** si vous avez deux disques. Cela vous permettra de bénéficier du chiffrement natif (indispensable pour sécuriser vos données) et d'une redondance matérielle.

![Recap](https://pve.proxmox.com/pve-docs/images/screenshot/pve-install-summary.png)

## 2. Prérequis sur l'hôte Proxmox

Une fois Proxmox installé et accessible depuis votre navigateur, quelques étapes de configuration sont requises **sur le serveur** avant de pouvoir lancer le script d'initialisation.

### A. Clé SSH (Accès distant)
Terraform et Ansible ont besoin d'un accès SSH à votre hôte Proxmox.
1. Sur votre machine personnelle, générez une clé SSH (si vous n'en avez pas déjà une dédiée) :
   ```bash
   ssh-keygen -t ed25519 -C "proxmox_terraform" -f ~/.ssh/proxmox_terraform
   ```
2. Envoyez la clé publique sur votre serveur Proxmox (remplacez l'IP par celle de votre serveur) :
   ```bash
   ssh-copy-id -i ~/.ssh/proxmox_terraform.pub root@192.168.1.100
   ```

### B. Création d'un Token API Proxmox (Pour Terraform)
L'infrastructure as code (Terraform) a besoin d'interagir avec l'API de Proxmox de manière sécurisée et sans intervention manuelle.
1. Connectez-vous à l'interface web de Proxmox (`https://<IP_PROXMOX>:8006`).
2. Allez dans **Datacenter > Permissions > Users** et créez un nouvel utilisateur (ex: `terraform@pve`).
3. Allez dans **Datacenter > Permissions > API Tokens**, cliquez sur "Add" et créez un token pour l'utilisateur `terraform@pve` (décochez impérativement la case "Privilege Separation").
4. **Notez précieusement le `Token ID` et le `Secret`** affichés à l'écran, ils vous seront demandés par le script d'initialisation (le secret ne sera affiché qu'une seule fois !).
5. Allez dans **Datacenter > Permissions**, et ajoutez une permission globale (Path: `/`) pour l'utilisateur `terraform@pve` avec le rôle `Administrator`.

### C. Paquets sur Proxmox (Pour Ansible)
Par défaut, Proxmox n'installe pas `sudo`. Cependant, nos scripts de déploiement Ansible en ont besoin pour l'élévation de privilèges de certains services.
Ouvrez le terminal web de Proxmox (ou connectez-vous en SSH en tant que `root`) et lancez :
```bash
apt update && apt install -y sudo
```

## 3. Lancement du script d'initialisation

Une fois les prérequis validés (SSH et API Token en poche), vous êtes prêt à configurer votre dépôt. 

Ouvrez un terminal sur votre machine personnelle et téléchargez le script d'initialisation. Ce script s'occupera de cloner votre dépôt et de préparer l'environnement chiffré :

```bash
# Téléchargement du script d'initialisation (à adapter avec le nom de votre fork)
wget https://raw.githubusercontent.com/votre-orga/proxmox-gitops/main/helper-scripts/init.sh
chmod +x init.sh

# Lancement interactif de l'initialisation
./init.sh
```

*Le script vous guidera ensuite pas à pas (installation des dépendances, configuration du domaine, orga Github, création de la clé de chiffrement SOPS, et premier lancement de Terraform).*
