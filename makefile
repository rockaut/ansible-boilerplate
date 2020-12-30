ANSIBLEDIR := ./ansible
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
		pip install --requirement requirements.txt
	)

upgrade-pythonenv:
	@echo "*** creating python3 virtual environment ***"
	@python3 -m venv ${PYTHONVENV}
	@( \
		. ${PYTHONVENV}/bin/activate; \
		pip install wheel; \
		pip install --upgrade --requirement requirements.txt
	)

initialize: total-clean create-pythonenv
	@find -iname ".placeholder" -delete
	@find -iname ".initialize" -delete

ansible-prepare:
	@cd ${ANSIBLEDIR}; \
	mkdir -p tmp; \
	chmod 0644 .vault_pass; \

ansible-encrypt: ansible-prepare
	@. $(PY_VENV_DIR)/bin/activate; cd $(ANSIBLE_DIR); \
		find ./ -name "vault" \( -exec echo {} \; -not -path '*/ansible_collections/*' -exec ansible-vault encrypt {} \; \); \
		find ./ -name "*.vault" \( -exec echo {} \; -not -path '*/ansible_collections/*' -exec ansible-vault decrypt {} \; \);

ansible-decrypt: ansible-prepare
	@. $(PY_VENV_DIR)/bin/activate; cd $(ANSIBLE_DIR); \
		find ./ -name "vault" \( -exec echo {} \; -not -path '*/ansible_collections/*' -exec ansible-vault decrypt {} \; \); \
		find ./ -name "*.vault" \( -exec echo {} \; -not -path '*/ansible_collections/*' -exec ansible-vault decrypt {} \; \);

ansible-setup: ansible-prepare
	. ${PYTHONVENV}/bin/activate; \
		pip install -r requirements.txt; \
		cd ${ANSIBLEDIR}; \
		ansible-galaxy install -r requirements.yml

vaults-backup: ansible-encrypt
	rsync -vrapP --prune-empty-dirs --delete \
		--exclude='*/.git/' --exclude='*/venv/' --exclude='*/ansible/collections/*' \
		--include='vault' --include='.vault' --include='vault.yml' --include='vault.yaml' \
		--include='*/' --exclude='*' \
		${PWD} ${BASE_BACKUP_DIR}/${CURRENT_BRANCH}

vaults-restore:
	@echo "*** restores missing vaults and updates older ones ***"
	rsync -vrapP --update \
		--exclude='*/.git/' --exclude='*/venv/' --exclude='*/ansible/collections/*' \
		--include='vault' --include='.vault' --include='vault.yml' --include='vault.yaml' \
		--include='*/' --exclude='*' \
		${BASE_BACKUP_DIR}/${CURRENT_BRANCH}/*/ ${PWD}

vaults-populate:
	@echo "*** restores missing vaults not touching already present ***"
	rsync -vrapP --ignore-existing \
		--exclude='*/.git/' --exclude='*/venv/' --exclude='*/ansible/collections/*' \
		--include='vault' --include='.vault' --include='vault.yml' --include='vault.yaml' \
		--include='*/' --exclude='*' \
		${BASE_BACKUP_DIR}/${CURRENT_BRANCH}/*/ ${PWD}
