#!/bin/csh
# ======================================================
# Script Name: pexit.csh
# Author: Ali Zeinolabedin
# Created: 2025-08-11
# Version1.1
# Description: `pexit` command to exit the current project environment.
#   - Unsets project-related environment variables
#   - Restores default prompt and HOME
#   - Changes directory to /home/$USER/project/
# Usage:
#   source pexit.csh
#   source pexit.csh -h   # for help
# ======================================================

# --- Help option ---
if ($#argv > 0) then
    if ($#argv > 0 && ( "$argv[1]" == "-h" || "$argv[1]" == "--help" )) then
        echo "\nUsage: source pexit.csh [options]"
        echo ""
        echo "Exit the current project environment and restore defaults."
        echo ""
        echo "Options:"
        echo "  -h, --help    Show this help message and exit."
        echo ""
        echo "This script will unset PROJECT, PRJ_DIR, ICPRO_DIR, and restore HOME and prompt."
        echo ""
        exit 0
    endif
endif

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

# Restore HOME and clean up
if ( $?OLDHOME ) then
    setenv HOME "$OLDHOME"
    unsetenv OLDHOME
endif

# Change to default project directory
cd /home/$USER/project/

echo "Project variables cleared and prompt reset."
