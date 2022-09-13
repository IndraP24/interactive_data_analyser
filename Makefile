.PHONY: clean help

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DATA_URL := tsiaras/uk-road-safety-accidents-and-vehicles
DATA_DIR := $(PROJECT_DIR)/data/raw/
DATA_PROCESSED_DIR := $(PROJECT_DIR)/data/processed/
SCRIPT_DIR := $(PROJECT_DIR)/scripts/
ARTIFACT_DIR := $(PROJECT_DIR)/artifacts/
MODEL_DIR := $(ARTIFACT_DIR)/Models/

ifeq (,$(shell which conda))
HAS_CONDA=False
else
HAS_CONDA=True
endif

ifneq ("$(wildcard $(DATA_DIR)/*.csv)","")
    FILE_EXISTS = 1
else
    FILE_EXISTS = 0
endif

#################################################################################
# COMMANDS                                                                      #
#################################################################################

# Recipe for activating the conda environment within the sub-shell as a target, from my solution at https://stackoverflow.com/a/71548453/13749426
.ONESHELL:
# Need to specify bash in order for conda activate to work, otherwise it will try to use the default shell, which is "zsh" in this case
SHELL = /bin/zsh

# Note that the extra activate is needed to ensure that the activate floats env to the front of PATH, otherwise it will not work
CONDA_ACTIVATE = source $$(conda info --base)/etc/profile.d/conda.sh ; conda activate ; conda activate

# Install mamba(if not installed) -> dependencies(from r-env.yml)
install:
	@echo "Installing mamba..."
	$(CONDA_ACTIVATE) base
	@conda install -c conda-forge mamba -y
	@echo "Installing R dependencies..."
	@mamba env update -f r-env.yml
	@echo "Done! Exporting to r-env.yml..."
	@mamba env export -n data-analyser > r-env.yml
	@echo "Done! Activate the environment using 'conda activate data-analyser'"


clean:
	@# Help: Clean the data/raw/ directory
	[ -f $(DATA_DIR)*.csv ] && rm -f $(DATA_DIR)*.csv
	[ -f $(DATA_DIR)*.zip ] && rm -f $(DATA_DIR)*.zip
	[ -f $(DATA_DIR)*.csv ] && rm -f $(DATA_PROCESSED_DIR)*.csv

data: clean
	@# Help: Download the data from the source and save it to the `data/raw/` directory
	$(CONDA_ACTIVATE) data-analyser
	kaggle datasets download $(DATA_URL) -p $(DATA_DIR)
	unzip $(DATA_DIR)*.zip -d $(DATA_DIR)
	rm -f $(DATA_DIR)*.zip



.DEFAULT_GOAL := help
# Arcane incantation to print all the targets along with their descriptions mentioned with "@# Help: <<Description>>", from https://stackoverflow.com/a/65243296/13749426. Check https://stackoverflow.com/a/20983251/13749426 and https://stackoverflow.com/a/28938235/13749426 for coloring terminal outputs.
help:
	@printf "%-20s %s\n" "Target" "Description"
	@printf "%-20s %s\n" "------" "-----------"
	@make -pqR : 2>/dev/null \
		| awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' \
		| sort \
		| egrep -v -e '^[^[:alnum:]]' -e '^$@$$' \
		| xargs -I _ sh -c 'printf "\033[1;32m%-20s\033[0;33m " _; make _ -nB | (grep -i "^# Help:" || echo "") | tail -1 | sed "s/^# Help: //g"'
