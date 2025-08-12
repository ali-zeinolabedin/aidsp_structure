# ======================================================
# Script Name: Makefile
# Author: Ali Zeinolabedin
# Created: 2025-08-12
# Description: Makefile to release the 'startup' folder to 'startup_release'
# Version 1.0: 
# ======================================================

RELEASE_DIR=startup_release
SRC_DIR=startup

.PHONY: release clean install

release:
	@echo "Releasing $(SRC_DIR) to $(RELEASE_DIR) ..."
	@if [ -d $(RELEASE_DIR) ]; then \
		rm -rf $(RELEASE_DIR); \
	fi
	@cp -r ./* ../$(RELEASE_DIR)
	@chmod -R 755 ../$(RELEASE_DIR)
	@echo "Release complete: $(RELEASE_DIR) created with permissions 755."

clean:
	@echo "Cleaning up release directory..."
	@if [ -d $(RELEASE_DIR) ]; then \
		rm -rf ../$(RELEASE_DIR); \
		echo "Removed ../$(RELEASE_DIR)."; \
	else \
		echo "No release directory to clean."; \
	fi
