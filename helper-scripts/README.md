# Scripts d'initialisation de l'infrastructure

Ce dossier contient les scripts nécessaires pour configurer votre environnement lors de la **toute première installation** de l'infrastructure. 

Leur rôle est de préparer vos variables (domaines, identifiants Proxmox, paramètres GitHub) de façon interactive, de générer votre clé de chiffrement SOPS et de chiffrer vos fichiers de configuration sensibles de façon automatisée avant même de les écrire sur le disque.

### Scripts disponibles

- `init.sh` : C'est le script principal. Il orchestre l'ensemble du processus. Il clone le dépôt, vérifie les dépendances, génère les fichiers de variables et lance le déploiement initial complet de Terraform (couches `bootstrap` et `core`). **C'est le seul script que vous avez besoin de lancer.**
- `check_dependencies.sh` : Vérifie que tous les outils prérequis (`git`, `terraform`, `ansible`, `sops`, `age`, `j2`, `gh`) sont installés sur votre machine.
- `create_tfvars_credentials.sh` : Génère la clé AGE, ajoute le secret sur GitHub et crée le fichier chiffré des variables Terraform (`terraform.enc.tfvars`).
- `create_repo_settings.sh` : Crée le fichier de variables globales Ansible (`settings.enc.yml`) et le fichier de configuration du backend distant Terraform (`versions.tf`).

### Utilisation au quotidien

Ces scripts ne servent **qu'une seule fois** pour initialiser tout le projet. 

Une fois l'initialisation terminée, vous n'aurez plus jamais à utiliser les scripts de ce dossier. La gestion quotidienne de votre infrastructure, les mises à jour et les déploiements se feront exclusivement via le `Makefile` à la racine du projet.

👉 **[Consulter la documentation du Makefile](../docs/MAKEFILE.md)**