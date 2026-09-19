#!/usr/bin/env python3
import os
import re
import shutil
import subprocess
import sys

# Define color codes for pretty output
GREEN = '\033[0;32m'
RED = '\033[0;31m'
YELLOW = '\033[0;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'

DEPENDENCIES = ["git", "terraform", "ansible", "sops", "age", "j2"]

def print_info(msg):
    print(f"{BLUE}[INFO]{NC} {msg}")

def print_success(msg):
    print(f"{GREEN}[SUCCESS]{NC} {msg}")

def print_error(msg):
    print(f"{RED}[ERREUR]{NC} {msg}")

def print_warning(msg):
    print(f"{YELLOW}[ATTENTION]{NC} {msg}")

def check_dependencies():
    print_info("Vérification des dépendances...")
    missing = []
    
    use_gh = input("Voulez-vous utiliser Github CLI (gh) pour ajouter automatiquement la clé SOPS sur le repo ? (o/N) : ").strip().lower()
    if use_gh in ['o', 'y', 'oui', 'yes']:
        DEPENDENCIES.append("gh")
        os.environ["USE_GH"] = "true"
    else:
        os.environ["USE_GH"] = "false"

    for cmd in DEPENDENCIES:
        if shutil.which(cmd):
            # Try to get version
            try:
                version_output = subprocess.check_output([cmd, "--version"], stderr=subprocess.STDOUT, text=True).splitlines()[0]
                version = " ".join(version_output.split()[:3])
            except Exception:
                version = "installé"
            print(f"[{GREEN}OK{NC}] {cmd} -> {version}")
        else:
            print(f"[{RED}ERREUR{NC}] {cmd} n'est pas installé.")
            missing.append(cmd)
            
    if missing:
        print(f"\n{RED}Échec : Il vous manque des dépendances. Voici comment les installer sur Ubuntu/Debian :{NC}\n")
        for tool in missing:
            if tool in ["git", "ansible", "age", "gh"]:
                print(f"- {tool} : sudo apt install -y {tool}")
            elif tool == "j2":
                print(f"- j2 (j2cli) : sudo apt install -y j2cli (ou pip3 install j2cli)")
            elif tool == "terraform":
                print(f"- terraform :\n  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg\n  echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list\n  sudo apt update && sudo apt install -y terraform")
            elif tool == "sops":
                print(f"- sops :\n  wget https://github.com/getsops/sops/releases/download/v3.8.1/sops_3.8.1_amd64.deb\n  sudo dpkg -i sops_3.8.1_amd64.deb")
        sys.exit(1)
    print_success("Toutes les dépendances sont prêtes !")

def setup_sops():
    print_info("Configuration de la clé SOPS...")
    keys_dir = os.path.expanduser("~/.config/sops/age")
    key_file = os.path.join(keys_dir, "keys.txt")
    
    if os.path.exists(key_file):
        print_info(f"Une clé AGE existe déjà dans {key_file}. Utilisation de cette clé.")
    else:
        os.makedirs(keys_dir, exist_ok=True)
        subprocess.run(["age-keygen", "-o", key_file], check=True)
        print_success(f"Nouvelle clé AGE générée dans {key_file}")
        
        if os.environ.get("USE_GH") == "true":
            try:
                print_info("Ajout de la clé privée sur Github Secrets (SOPS_AGE_KEY)...")
                with open(key_file, "r") as f:
                    subprocess.run(["gh", "secret", "set", "SOPS_AGE_KEY"], input=f.read().encode(), check=True)
                print_success("Clé SOPS_AGE_KEY ajoutée avec succès sur GitHub.")
            except Exception as e:
                print_error(f"Échec de l'ajout du secret via Github CLI. L'avez-vous configuré (gh auth login) ?")
    
    # Extract public key
    with open(key_file, "r") as f:
        pub_key = None
        for line in f:
            if line.startswith("# public key:"):
                pub_key = line.split(":")[1].strip()
                break
                
    if pub_key:
        print_info("Mise à jour de .sops.yaml avec la clé publique...")
        with open(".sops.yaml", "w") as f:
            f.write(f"# https://github.com/getsops/sops\ncreation_rules:\n  - path_regex: .*\\.enc\\.(ya?ml|tfvars)$\n    age: \"{pub_key}\"\n")
    else:
        print_error("Impossible de trouver la clé publique dans keys.txt")
        sys.exit(1)

def parse_and_prompt(template_paths, answers):
    print_info("Collecte interactive des variables...")
    var_regex = re.compile(r'\{\{\s*([A-Z0-9_]+)\s*\}\}')
    
    for path in template_paths:
        if not os.path.exists(path):
            continue
            
        with open(path, "r") as f:
            lines = f.readlines()
            
        for i, line in enumerate(lines):
            matches = var_regex.findall(line)
            for var in matches:
                # Do not prompt for SECRETS_, user fills them later via edit-secrets
                if var.startswith("SECRETS_"):
                    continue
                
                if var not in answers:
                    # Look for comment immediately preceding
                    comment = ""
                    # Traverse backwards looking for comments
                    for j in range(i-1, -1, -1):
                        if lines[j].strip().startswith("#"):
                            comment = lines[j].strip()[1:].strip() + " " + comment
                        elif not lines[j].strip():
                            continue # skip empty lines between comment and variable
                        else:
                            break
                    
                    if not comment:
                        # Try inline comment
                        if "#" in line:
                            comment = line.split("#")[1].strip()
                            
                    prompt_text = f"{YELLOW}{comment}{NC}\n[{var}] : " if comment else f"[{var}] : "
                    answer = input(prompt_text).strip()
                    answers[var] = answer
    return answers

def render_and_encrypt(template_path, output_enc_path, answers):
    print_info(f"Génération et chiffrement de {output_enc_path}...")
    tmp_path = output_enc_path.replace(".enc.", ".") + ".tmp"
    
    var_regex = re.compile(r'\{\{\s*([A-Z0-9_]+)\s*\}\}')
    
    with open(template_path, "r") as infile, open(tmp_path, "w") as outfile:
        for line in infile:
            def replacer(match):
                var = match.group(1)
                if var.startswith("SECRETS_"):
                    return "REMPLIR_ICI"
                return answers.get(var, "")
            new_line = var_regex.sub(replacer, line)
            outfile.write(new_line)
            
    subprocess.run(["sops", "-e", "--filename-override", output_enc_path, tmp_path], stdout=open(output_enc_path, "w"), check=True)
    os.remove(tmp_path)
    print_success(f"{output_enc_path} généré.")

def get_github_info():
    print_info("Détection automatique de l'organisation et du dépôt GitHub...")
    try:
        remote_url = subprocess.check_output(["git", "remote", "get-url", "origin"], text=True).strip()
        # Handle both SSH and HTTPS
        # SSH: git@github.com:Orga/Repo.git
        # HTTPS: https://github.com/Orga/Repo.git
        if remote_url.startswith("git@"):
            path = remote_url.split(":")[1]
        elif remote_url.startswith("https://"):
            path = remote_url.split("github.com/")[1]
        else:
            return {}
            
        path = path.replace(".git", "")
        org, repo = path.split("/")
        print_success(f"Détecté : {org}/{repo}")
        return {"GITHUB_ORG": org, "GITHUB_REPO": repo}
    except Exception as e:
        print_warning("Impossible de détecter automatiquement l'organisation GitHub.")
        return {}

def main():
    print("===========================================================")
    print("[INFO] Initialisation Intelligente Proxmox GitOps")
    print("===========================================================")
    
    check_dependencies()
    
    print_info("Configuration des permissions (githooks)...")
    subprocess.run(["git", "config", "core.hookspath", ".githooks"])
    
    setup_sops()
    
    templates_to_parse = [
        "settings.yml.j2",
        "terraform/environments/production/terraform.tfvars.j2",
        "terraform/environments/production/core/versions.tf.j2"
    ]
    
    answers = get_github_info()
    answers = parse_and_prompt(templates_to_parse, answers)
    
    render_and_encrypt("settings.yml.j2", "settings.enc.yml", answers)
    render_and_encrypt("terraform/environments/production/terraform.tfvars.j2", "terraform/environments/production/terraform.enc.tfvars", answers)
    
    print_info("Génération de versions.tf (non chiffré)...")
    # For versions.tf, just do standard templating
    with open("terraform/environments/production/core/versions.tf.j2", "r") as infile, open("terraform/environments/production/core/versions.tf", "w") as outfile:
        var_regex = re.compile(r'\{\{\s*([A-Z0-9_]+)\s*\}\}')
        for line in infile:
            def replacer(match):
                return answers.get(match.group(1), "")
            outfile.write(var_regex.sub(replacer, line))
            
    print("\n===========================================================")
    print("[INFO] Déploiement de l'infrastructure avec Terraform")
    print("===========================================================")
    subprocess.run(["make", "tf", "TF_LAYER=bootstrap", "ACTION=init"], check=True)
    subprocess.run(["make", "tf", "TF_LAYER=bootstrap", "ACTION=apply -auto-approve"], check=True)
    subprocess.run(["make", "tf", "TF_LAYER=core", "ACTION=init"], check=True)
    subprocess.run(["make", "tf", "TF_LAYER=core", "ACTION=apply -auto-approve"], check=True)
    
    print("\n===========================================================")
    print(f"{GREEN}[SUCCESS] Initialisation terminée avec succès !{NC}")
    print(f"Rappel : N'oubliez pas d'exécuter '{YELLOW}make edit-secrets{NC}' pour remplir vos mots de passe de services.")
    print("===========================================================")

if __name__ == "__main__":
    main()
