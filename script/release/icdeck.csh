#!/bin/csh
# ======================================================
# Script Name: icdeck.csh
# Author: Ali Zeinolabedin
# Created: 2025-08-11
# Description: Interactive project environment selector for ICDECK.
# Version1.1
#   - Replacing the aidsp.csh
#   - ICDECK: Integrated Circuit Design & Engineering Collaboration Kernel
#   - Uses a YAML file (projects.yaml) for project configuration
#   - Uses a Python helper to select project and set variables
#   - Handles project directory navigation and environment setup
#   - Optionally installs project if missing (via git)
# Usage:
#   source icdeck.csh
#   source icdeck.csh -h   # for help
# ======================================================

# --- Help option ---
if ($#argv > 0) then
    if ( "$argv[1]" == "-h" || "$argv[1]" == "--help" ) then
        echo "\nUsage: source icdeck.csh [options]"
        echo ""
        echo "Interactive project selector and environment setup for ICDECK."
        echo ""
        echo "Options:"
        echo "  -h, --help    Show this help message and exit."
        echo ""
        echo "After running, you will be prompted to select a project."
        echo "The script sets PROJECT, PRJ_DIR, and GIT_URL variables,"
        echo "changes to the project directory, and updates your shell prompt."
        echo "If the project directory does not exist, you will be offered to clone it from git."
        echo ""
        exit 0
    endif
endif

# Bold green escape codes for the Linux prompt only
set boldgreen = "%{\033[1;32m%}"
set reset     = "%{\033[0m%}"

# Bold color for echo only
set echo_boldgreen = "\033[1;32m"
set echo_boldred   = "\033[1;31m"
set echo_boldyellow = "\033[1;33m"
set echo_boldblue  = "\033[1;34m"
set echo_boldpurple = "\033[1;35m"
set echo_boldcyan  = "\033[1;36m"
set echo_reset      = "\033[0m"

# Regular Colors
alias black_echo   'printf "\033[0;30m%s\033[0m\n" \!*'
alias red_echo     'printf "\033[0;31m%s\033[0m\n" \!*'
alias green_echo   'printf "\033[0;32m%s\033[0m\n" \!*'
alias yellow_echo  'printf "\033[0;33m%s\033[0m\n" \!*'
alias blue_echo    'printf "\033[0;34m%s\033[0m\n" \!*'
alias purple_echo  'printf "\033[0;35m%s\033[0m\n" \!*'
alias cyan_echo    'printf "\033[0;36m%s\033[0m\n" \!*'
alias white_echo   'printf "\033[0;37m%s\033[0m\n" \!*'

# Bold/Bright Colors
alias b_red_echo     'printf "\033[1;31m%s\033[0m\n" \!*'
alias b_green_echo   'printf "\033[1;32m%s\033[0m\n" \!*'
alias b_yellow_echo  'printf "\033[1;33m%s\033[0m\n" \!*'
alias b_blue_echo    'printf "\033[1;34m%s\033[0m\n" \!*'
alias b_purple_echo  'printf "\033[1;35m%s\033[0m\n" \!*'
alias b_cyan_echo    'printf "\033[1;36m%s\033[0m\n" \!*'
alias b_white_echo   'printf "\033[1;37m%s\033[0m\n" \!*'


# Use Python helper to select project and set variables
eval `python3.6 /projects/BCI-HW-ASIC/ICDECK/script/release/icdeck_project_select.py`

# --- Add these lines for debugging ---
#echo "PROJECT is set to: $PROJECT"
#echo "PRJ_DIR is set to: $PRJ_DIR"
#echo "GIT_URL is set to: $GIT_URL"

# ------------------------------------
if ( ! $?PROJECT || ! $?PRJ_DIR ) then
    echo "${echo_boldred}No project selected or configuration error.${echo_reset}"
    exit 1
endif
goto check_project

check_project:
    if ( ! -d "$PRJ_DIR" ) then
        echo
        echo "${echo_boldred}WARNING:${echo_reset} Project directory does not exist: $PRJ_DIR"
        echo "Please check if the project is created under ${echo_boldyellow}[/home/$USER]${echo_reset}"
        goto install_project
    endif   

    # If directory exists, set ICPRO_DIR, change HOME, and cd
    setenv ICPRO_DIR "$PRJ_DIR"
    if ( ! $?OLDHOME ) setenv OLDHOME "$HOME"
    setenv HOME "$PRJ_DIR"
    cd "$PRJ_DIR"
    set prompt = "[${boldgreen}$PROJECT${reset}] %~ %# "
    goto end_script
    goto end_script

install_project:
    echo
    echo "${echo_boldblue}Project directory does not exist. Do you want to install the project? (y/n)${echo_reset}"
    set install_choice = $<
    if ( "$install_choice" == "y" || "$install_choice" == "Y" ) then
        echo "Changed to [/home/$USER/project] :"
        cd "/home/$USER/project"
        git clone "$GIT_URL"
        set repo_name = `basename "$GIT_URL" .git`
        if ( -d "$repo_name" ) then
            cd "$repo_name"
            echo "${echo_boldgreen}Project cloned."
        else
            echo "${echo_boldred}Failed to clone the repository.${echo_reset}"
        endif
    else
        echo "${echo_boldred}Project not installed. Exiting.${echo_reset}"
    endif

    # If directory exists, set ICPRO_DIR, change HOME, and cd
    setenv ICPRO_DIR "$PRJ_DIR"
    if ( ! $?OLDHOME ) setenv OLDHOME "$HOME"
    setenv HOME "$PRJ_DIR"
    cd "$PRJ_DIR"
    set prompt = "[${boldgreen}$PROJECT${reset}] %~ %# "

    goto end_script


end_script:
