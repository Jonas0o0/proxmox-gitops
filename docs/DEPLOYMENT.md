# Guide de Déploiement et d'Ajout de Services

## Le processus de déploiement automatique (Ansible)
Le déploiement des stacks Docker Compose est entièrement automatisé et standardisé via un playbook Ansible unique : `deploy_any_compose.yml`.

Ce processus est déclenché de deux manières :
- **Manuellement (en local)** : avec la commande `make deploy-compose SERVICE=nom_du_service`
- **Automatiquement (CI/CD)** : par les GitHub Actions lors d'un commit sur la branche principale (via `make deploy-compose-ci`).

### Que fait Ansible en arrière-plan ?
1. **Déchiffrement global** : Ansible déchiffre à la volée le fichier `settings.enc.yml` situé à la racine du dépôt pour charger toutes vos configurations et secrets (sans jamais rien écrire en clair sur le disque de la CI ou de votre poste).
2. **Copie des fichiers** : Il transfère l'intégralité du dossier de votre service (ex: `services/mon-service/`) vers le serveur distant dans `/opt/mon-service`.
3. **Génération (Templating)** : Tous les fichiers se terminant par `.j2` (comme `.env.j2` ou `config.yml.j2`) sont lus. Ansible remplace dynamiquement vos variables (ex: `{{ secrets.mon_service.db_password }}`) par leurs valeurs déchiffrées, et écrit les fichiers finaux (`.env` ou `config.yml`) sur le serveur distant.
4. **Nettoyage** : Les fichiers `.j2` sources sont ensuite supprimés du serveur distant pour ne pas polluer l'environnement de production.
5. **Démarrage conditionnel** : Si un seul fichier de la stack a été modifié (configuration modifiée, secret mis à jour), Ansible lance ou redémarre la stack Docker Compose avec les nouveaux paramètres.

---

## Ajouter un nouveau service avec des secrets

Si vous souhaitez ajouter un nouveau service nécessitant des mots de passe ou des clés d'API, le processus avec SOPS est entièrement centralisé et très sécurisé.

### Étape 1 : Créer les fichiers du service
Créez le dossier de votre service dans `services/` :
```text
services/nouveau-service/
├── docker-compose.yml
└── .env.j2
```

### Étape 2 : Préparer le fichier `.env.j2`
Plutôt que d'écrire vos mots de passe en dur, référencez-les sous la forme de variables Jinja qui pointent vers le dictionnaire `secrets` :
```env
# services/nouveau-service/.env.j2
DB_HOST=db
DB_USER=admin
DB_PASSWORD={{ secrets.nouveau_service.db_password }}
API_KEY={{ secrets.nouveau_service.api_key }}
```

### Étape 3 : Déclarer les secrets
Pour que vos secrets soient connus d'Ansible et correctement injectés, vous devez les ajouter à la configuration centrale.

1. **Remplir les véritables secrets dans le fichier chiffré SOPS** :
   À la racine de votre projet, ouvrez le coffre-fort central avec :
   ```bash
   make edit-secrets
   ```
   Votre éditeur s'ouvrira avec les données en clair. Descendez dans la section `secrets:` et ajoutez votre service avec vos **vrais** mots de passe :
   ```yaml
   secrets:
     # ... autres services existants ...
     nouveau_service:
       db_password: "MonSuperMotDePasseSecret123"
       api_key: "ak_live_xyz123"
   ```
   Sauvegardez et quittez. SOPS va instantanément rechiffrer le fichier et le sauvegarder. Vous pouvez ensuite le *commiter* sur Git.

2. **(Optionnel) Maintenir le template à jour** :
   Pour que les futurs utilisateurs (ou les futures installations) sachent quelles variables sont requises, il est de bonne pratique d'ajouter également ces clés dans `settings.yml.j2` :
   ```yaml
   secrets:
     # ...
     nouveau_service:
       db_password: "{{ SECRETS_NOUVEAU_SERVICE_DB_PASSWORD }}"
       api_key: "{{ SECRETS_NOUVEAU_SERVICE_API_KEY }}"
   ```

### Étape 4 : Déployer
Vous pouvez tester votre nouveau service en le déployant :
```bash
make deploy-compose SERVICE=nouveau-service
```
Ansible va s'occuper de tout : se connecter, injecter les secrets du coffre-fort dans le `.env` généré, et démarrer les conteneurs !
