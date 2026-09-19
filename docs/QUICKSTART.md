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
Au lieu de passer par l'interface web, ouvrez le **shell de votre serveur Proxmox** (ou connectez-vous en SSH en tant que `root`) et lancez les commandes suivantes :

```bash
# 1. Création de l'utilisateur 'terraform'
pveum user add terraform@pve

# 2. Attribution des droits d'Administrateur global à l'utilisateur
pveum acl modify / -user terraform@pve -role Administrator

# 3. Création du Token API (sans séparation des privilèges)
pveum user token add terraform@pve provision -privsep 0
```

> **⚠️ IMPORTANT :** La dernière commande va vous afficher la valeur du **secret**. 
> Notez précieusement la valeur affichée sous `value:` (c'est votre *Token Secret*) ainsi que l'identifiant complet (ici `terraform@pve!provision` qui est votre *Token ID*). Ils vous seront demandés par le script d'initialisation !

### C. Paquets sur Proxmox (Pour Ansible)
Par défaut, Proxmox n'installe pas `sudo`. Cependant, nos scripts de déploiement Ansible en ont besoin pour l'élévation de privilèges de certains services.
Ouvrez le terminal web de Proxmox (ou connectez-vous en SSH en tant que `root`) et lancez :
```bash
apt update && apt install -y sudo
```

## 3. Lancement du script d'initialisation

Une fois les prérequis validés (SSH et API Token en poche), vous êtes prêt à configurer votre dépôt. 

Ouvrez un terminal sur votre machine personnelle et téléchargez votre dépôt. Ce script s'occupera ensuite de préparer l'environnement chiffré et l'infrastructure :

```bash
# Téléchargement du dépôt complet (remplacez l'URL par celle de votre propre fork/dépôt)
git clone https://github.com/votre-orga/proxmox-gitops.git
cd proxmox-gitops

# Lancement interactif de l'initialisation
./helper-scripts/init.sh
```

*Le script vous guidera ensuite pas à pas (installation des dépendances, configuration du domaine, orga Github, création de la clé de chiffrement SOPS, et premier lancement de Terraform).*
