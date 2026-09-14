#!/usr/bin/env python3
import yaml
import re 
import subprocess
import json
import sys

with open(".sops.yaml", "r") as sops_config:
    doc = yaml.safe_load(sops_config)
    creation_rules=doc["creation_rules"]
    secrets_regex = creation_rules[0]["path_regex"]

uncommited_files = subprocess.getoutput("git diff --cached --name-only --diff-filter=ACM").splitlines()

secret_files = [filepath for filepath in uncommited_files if re.match(secrets_regex, filepath)]

for secret_file in secret_files:
    try:
        encryption_status = subprocess.getoutput(f"sops filestatus {secret_file}")
        is_encrypted = json.loads(encryption_status)["encrypted"]
    except Exception:
        print(f"couldn't get status for {secret_file}, exiting")
        sys.exit(1)

    if(is_encrypted==False):
        print(f"{secret_file} not encrypted, proceed to its encryption")
        # in place
        encryption = subprocess.run(f"sops -e -i {secret_file}", shell=True)
        git_added = subprocess.run(f"git add {secret_file}", shell=True)

        if (encryption.returncode==0 and git_added.returncode==0):
            print(f"{secret_file} correctly encrypted and added to git")
        else :
            print(f"couldn't encrypt {secret_file}")
            # wont commiittt
            sys.exit(1)
