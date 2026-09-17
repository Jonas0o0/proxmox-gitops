# sert à centraliser les commandes récurrentes et définir une convention courante (qu'on utilise de notre côté ou en CI)
TF_DIR := terraform/environments/production
ANSIBLE_INVENTORIES := ansible/inventories

ANSIBLE_INVENTORY := ansible/inventories/inventory.yml

# qq exemples : 
# make tf TF_LAYER=core ACTION=plan
# make tf-apply TF_LAYER=bootstrap
# make tf-apply # en defaut il fera sur la couche terraform core
# make deploy-compose SERVICE=monitoring

lint-checkov: 
	docker run --rm -v "$${PWD}:/repo" bridgecrew/checkov:2 -d /repo --quiet

lint-tflint:
	docker run --rm -v "$${PWD}:/repo" -w /repo ghcr.io/terraform-linters/tflint:latest --recursive


# défaut
TF_LAYER ?=core
tf: 
	cd $(TF_DIR)/$(TF_LAYER) && \
	if [ -f ./remote-backend-init.sh ]; then . ./remote-backend-init.sh; fi && \
	if [ -f ../terraform.enc.tfvars ]; then \
		sops --input-type binary --output-type binary exec-file ../terraform.enc.tfvars 'terraform $(ACTION) -var-file="{}"'; \
	elif [ -f ../terraform.tfvars ]; then \
		terraform $(ACTION) -var-file="../terraform.tfvars"; \
	else \
		terraform $(ACTION); \
	fi

tf-init: 
	$(MAKE) tf TF_LAYER=$(TF_LAYER) ACTION=init

tf-plan: 
	$(MAKE) tf TF_LAYER=$(TF_LAYER) ACTION=plan

tf-apply: 
	$(MAKE) tf TF_LAYER=$(TF_LAYER) ACTION=apply

tf-destroy: 
	$(MAKE) tf TF_LAYER=$(TF_LAYER) ACTION=destroy

deploy-compose-ci:
	ANSIBLE_STRICT_HOST_KEY_CHECKING=false ansible-playbook ansible/playbooks/deploy_any_compose.yml -e "host=$(SERVICE) target_service=$(SERVICE)" -i $(ANSIBLE_INVENTORY) $(EXTRA_ARGS)

# -K en option ansible pcq il va demander à become sudo pour verif les library
deploy-compose:
	$(MAKE) deploy-compose-ci EXTRA_ARGS="-K"


deploy-alloy:
	ANSIBLE_STRICT_HOST_KEY_CHECKING=false ansible-playbook ansible/playbooks/install_alloy.yml -i $(ANSIBLE_INVENTORY) $(EXTRA_ARGS)

deploy-lxc: 
	ANSIBLE_STRICT_HOST_KEY_CHECKING=false ansible-playbook ansible/playbooks/bootstrap.yml -i $(ANSIBLE_INVENTORIES)/lxc_inventory.yml $(EXTRA_ARGS)

edit-secrets:
	EDITOR=vim sops services/$(SERVICE)/secrets.enc.yml
