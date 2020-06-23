ANSIBLEDIR = ./ansible
PYTHONVENV = ./venv

total-clean:
	@echo "*** removing all the things ***"
	@rm -rf ${PYTHONVENV}

create-pythonenv:
	@echo "*** creating python3 virtual environment ***"
	@python3 -m venv ${PYTHONVENV}
	@( \
		. ${PYTHONVENV}/bin/activate; \
		pip install --requirement requirements.txt \
	)

upgrade-pythonenv:
	@echo "*** creating python3 virtual environment ***"
	@python3 -m venv ${PYTHONVENV}
	@( \
		. ${PYTHONVENV}/bin/activate; \
		pip install --upgrade --requirement requirements.txt \
	)

initialize: total-clean create-pythonenv
	@find -iname ".placeholder" -delete
	@find -iname ".initialize" -delete
