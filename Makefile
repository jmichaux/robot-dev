VIRTUAL_ENV_NAME=rd-venv0

create-and-activate-virtual-env:
	python3 -m venv $(VIRTUAL_ENV_NAME)
	. $(VIRTUAL_ENV_NAME)/bin/activate

delete-virtual-env:
	rm -rf $(VIRTUAL_ENV_NAME)

init: delete-virtual-env create-and-activate-virtual-env install-as-editable

install-as-editable:
	python3 -m pip install -e .[dev]