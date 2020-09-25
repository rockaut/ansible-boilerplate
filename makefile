ANSIBLEDIR = ./ansible
PYTHONVENV = ./venv

total-clean:
	@echo "*** removing all the things ***"
	@rm -rf ${PYTHONVENV}

create-pythonenv: total-clean
	@echo "*** creating python3 virtual environment ***"
	@python3 -m venv ${PYTHONVENV}
	@( \
		. ${PYTHONVENV}/bin/activate; \
		pip install wheel; \
		pip install --requirement requirements.txt; \
	)

upgrade-pythonenv:
	@echo "*** creating python3 virtual environment ***"
	@python3 -m venv ${PYTHONVENV}
	@( \
		. ${PYTHONVENV}/bin/activate; \
		pip install wheel; \
		pip install --upgrade --requirement requirements.txt; \
	)

get-collections:
	@echo "*** fetch ansible-collections ***"
	. $(PY_VENV_DIR)/bin/activate && \
		cd $(ANSIBLE_DIR) && \
		ansible-galaxy collection install -r requirements.yml && \
	deactivate

ansible-encrypt:
	@. $(PY_VENV_DIR)/bin/activate; cd $(ANSIBLE_DIR); \
		find ./ -name "vault" \( -exec echo {} \; -exec ansible-vault encrypt {} \; \); \
		find ./ -name "*.vault" \( -exec echo {} \; -exec ansible-vault decrypt {} \; \);

ansible-decrypt:
	@. $(PY_VENV_DIR)/bin/activate; cd $(ANSIBLE_DIR); \
		find ./ -name "vault" \( -exec echo {} \; -exec ansible-vault decrypt {} \; \); \
		find ./ -name "*.vault" \( -exec echo {} \; -exec ansible-vault decrypt {} \; \);

initialize: total-clean create-pythonenv
	@find -iname ".placeholder" -delete
	@find -iname ".initialize" -delete
