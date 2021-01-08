ANSIBLEDIR := ${PWD}/ansible
PYTHONVENV := ./venv

CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
CURRENT_HASH := $(shell git rev-parse HEAD)

BASE_BACKUP_DIR := /mnt/c/Users/fisch/OneDrive/Code/github/rockaut/home-stack

total-clean:
	@echo "*** removing all the things ***"
	@rm -rf ${PYTHONVENV}

create-pythonenv: total-clean
	@echo "*** creating python3 virtual environment ***"
	@python3 -m venv ${PYTHONVENV}
	@( \
		. ${PYTHONVENV}/bin/activate; \
		pip install wheel; \
		pip install -r requirements.txt; \
	)

upgrade-pythonenv:
	@echo "*** creating python3 virtual environment ***"
	@python3 -m venv ${PYTHONVENV}
	@( \
		. ${PYTHONVENV}/bin/activate; \
		pip install wheel; \
		pip install --upgrade --requirement requirements.txt; \
	)

initialize: total-clean create-pythonenv
	@find -iname ".placeholder" -delete
	@find -iname ".initialize" -delete

ansible-prepare:
	@cd ${ANSIBLEDIR}; \
	mkdir -p tmp; \
	chmod 0644 .vault_pass;

ansible-setup: ansible-prepare
	. ${PYTHONVENV}/bin/activate; \
		pip install -r requirements.txt; \
		cd ${ANSIBLEDIR}; \
		ansible-galaxy install -r requirements.yml

vaults-encrypt: ansible-prepare
	. $(PYTHONVENV)/bin/activate; cd ${ANSIBLEDIR}; \
		find \
		-type f \( -iname "vault" -or -iname "*.vault" \) \
		-print -exec ansible-vault encrypt {} \;

vaults-decrypt: ansible-prepare
	. $(PYTHONVENV)/bin/activate; cd ${ANSIBLEDIR}; \
		find \
		-type f \( -iname "vault" -or -iname "*.vault" \) \
		-print -exec ansible-vault decrypt {} \;

vaults-backup: vaults-encrypt
	rsync -vrapP --prune-empty-dirs --delete \
		--exclude='*/.git/' --exclude='*/venv/' --exclude='*/ansible/collections/*' \
		--include='vault' --include='.vault' --include='vault.yml' --include='vault.yaml' \
		--include='*/secrets/*/*' \
		--include='*/' --exclude='*' \
		${PWD} ${BASE_BACKUP_DIR}/${CURRENT_BRANCH}
secrets-backup: vaults-backup

vaults-restore:
	@echo "*** restores missing vaults and updates older ones ***"
	rsync -vrapP --update \
		--exclude='*/.git/' --exclude='*/venv/' --exclude='*/ansible/collections/*' \
		--include='vault' --include='.vault' --include='vault.yml' --include='vault.yaml' \
		--include='*/secrets/*/*' \
		--include='*/' --exclude='*' \
		${BASE_BACKUP_DIR}/${CURRENT_BRANCH}/*/ ${PWD}
secrets-restore: vaults-restore

vaults-populate:
	@echo "*** restores missing vaults not touching already present ***"
	rsync -vrapP --ignore-existing \
		--exclude='*/.git/' --exclude='*/venv/' --exclude='*/ansible/collections/*' \
		--include='vault' --include='.vault' --include='vault.yml' --include='vault.yaml' \
		--include='*/secrets/*/*' \
		--include='*/' --exclude='*' \
		${BASE_BACKUP_DIR}/${CURRENT_BRANCH}/*/ ${PWD}
secrets-populate: vaults-populate

SUB:=prod

k:
	kustomize build k8s/${APP}/overlays/${SUB} | kubectl apply -f -
