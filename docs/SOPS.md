# gestion des secrets avec sops et age

on utilise sops avec age pour chiffrer les secrets directement dans le dépôt git (= pas besoin de vm vault dédiée ni de gestion de token).

## 1. prérequis

installer `sops` et `age` :
```bash
# sous debian / ubuntu
sudo apt install age
# pour sops, binaire officiel github.com/getsops/sops
```

## 2. génération de la clé age

générer une paire de clés sur votre machine :
```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```
la commande affiche votre clé publique (commence par `age1...`).

mettez cette clé publique dans `.sops.yaml` à la racine du dépôt :
```yaml
creation_rules:
  - path_regex: .*\.enc\.ya?ml$
    age: "age1votrecleici..."
```

## 3. édition et chiffrement des secrets

pour créer ou modifier les secrets d'un service (ex: caddy) :
```bash
make edit-secrets SERVICE=caddy
# ou directement
sops services/caddy/secrets.enc.yml
```
vous pouvez partir des modèles `secrets.yml.example` présents dans chaque dossier de service.

un hook git pre-commit (`.githooks/pre-commit`) est configuré pour vérifier et chiffrer automatiquement les fichiers `*.enc.yml` avant commit.

## 4. cicd (github actions)

dans les secrets du dépôt github, ajouter la clé privée age complète sous le nom :
`SOPS_AGE_KEY`
