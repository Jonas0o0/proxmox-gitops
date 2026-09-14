# Scripts de facilitation de la configuration du dépôt

Les scripts présents dans ce dossier ont principalement pour objectif de créer les fichiers de configuration principaux du dépôt de façon simple en demandant à l'utilisateur de les entrer.

Certains secrets alors créés, comme par exemple le token Terraform pour Proxmox sont plus simples à entrer puisque leur complexité est abstraite.
Pour les secrets des services (SOPS / age), ils sont directement chiffrés dans le dépôt, ce qui évite d'avoir une VM dédiée ou des scripts d'injection complexes à faire tourner.

Cela permet une accessibilité plus générale au dépôt, et a pour but de faciliter les migrations et personnalisations, d'autant plus dans notre contexte de projet en binôme devant être opérationnel sur deux machines, avec des paramètres différents.