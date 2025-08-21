#!/bin/csh
# ======================================================
# Script Name: pexit.csh
# Author: Ali Zeinolabedin
# Created: 2025-08-11
# Description: `pexit` command to exit the current project
# Version1.0
# ======================================================
# Restore a simple default prompt
set prompt = "%n@%m:%~ %# "

# Clear environment variables
if ( $?PROJECT ) then
    unsetenv PROJECT
endif

if ( $?PRJ_DIR ) then
    unsetenv PRJ_DIR
endif

if ( $?ICPRO_DIR ) then
    unsetenv ICPRO_DIR
endif

echo "Project variables cleared and prompt reset."
setenv HOME "$OLDHOME"
unsetenv OLDHOME
cd /home/$USER/project/
