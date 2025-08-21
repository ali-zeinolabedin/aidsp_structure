# ======================================================
# Script Name: Makefile
# Author: Ali Zeinolabedin
# Created: 2025-08-12
# Description: Makefile to release the 'startup' folder to 'startup_release'
# Version 1.0: 
# ======================================================

# Makefile to release the 'startup' folder to 'startup_release'

# Makefile to release the 'startup' folder to 'startup_release'

RELEASE_DIR=release
SRC_DIR=startup


.PHONY: release  install


release:
	@echo "Releasing $(SRC_DIR) to $(RELEASE_DIR) ..."
	@cp  startup/icdeck.csh startup/icdeck_project_select.py startup/projects.yaml startup/icdeck.txt  startup/pexit.csh startup/env.sh  $(RELEASE_DIR)
	@chmod -R 750 $(RELEASE_DIR)
	@echo "Release complete: $(RELEASE_DIR) created with permissions 750."


