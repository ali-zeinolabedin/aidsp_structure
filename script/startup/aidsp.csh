

#!/bin/csh
# ======================================================
# Script Name: aidsp.csh
# Author: Ali Zeinolabedin
# Created: 2025-08-11
# Description: `aidsp` command to select the project
# Version 2.0: 
# - obsolete: replaced by icdeck.csh
# - Added the ability to install the project if it does not exist
# --- New function: install_project
# --- New function: check_project
# - Improved user prompts and error handling
# ======================================================


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

b_blue_echo "Please select a project to navigate to:"
b_green_echo "0) ASIC-W-ICONS"
b_green_echo "1) IMEC_Colibri"
b_green_echo "2) BCI-HW-ASIC-BONSAI-V1.x: NEURALACE_VER1"
b_green_echo "3) BCI-HW-ASIC-BONSAI-V1.x: NEURALACE_VER1.1"
b_green_echo "4) BCI-HW-ASIC-MT-FEP4x4"
yellow_echo "5) NEURALACE_VER2.0 (Not available yet)"
#yellow_echo "6) AIDSP (Not available yet)"
echo "Enter the number of the project you want to navigate to, or 'q' to quit."

set choice = $<
switch ($choice)
    case 0:
        echo "Navigating to ASIC-W-ICONS ..."
        setenv PROJECT "ASIC-W-ICONS"
        setenv PRJ_DIR "/home/$USER/project/ASIC-W-ICONS/Cadence/w_icons/"
        set git_url = "git@github.com:BlackrockNeurotech/ASIC-W-ICONS.git"
        goto check_project
        breaksw
    case 1:
        echo "Navigating to IMEC Colibri ..."
        setenv PROJECT "ASIC-W-ICONS"
        setenv PRJ_DIR "/projects/BCI-ASIC/BONSAI-V1.x/Colibri_digital/"
        set git_url = ""
        goto check_project
        breaksw
    case 2:
        echo "Navigating to NEURALACE_VER1 ..."
        setenv PROJECT "BCI-HW-ASIC-BONSAI-V1.x:NEURALACE_VER1"
        setenv PRJ_DIR "/home/$USER/project/BCI-HW-ASIC-BONSAI-V1.x/NEURALACE_VER1"
        set git_url = "git@github.com:BlackrockNeurotech/BCI-HW-ASIC-BONSAI-V1.x.git"
        goto check_project
        breaksw
    case 3:
        echo "Navigating to NEURALACE_VER1.1 ..."
        setenv PROJECT "BCI-HW-ASIC-BONSAI-V1.x:NEURALACE_VER1.1"
        setenv PRJ_DIR "/home/$USER/project/BCI-HW-ASIC-BONSAI-V1.x/NEURALACE_VER1.1"
        set git_url = "git@github.com:BlackrockNeurotech/BCI-HW-ASIC-BONSAI-V1.x.git"
        goto check_project
        breaksw
    case 4:
        echo "Navigating to Mini-Tapeout: FEP4x4 ..."
        setenv PROJECT "BCI-HW-ASIC-MT-FEP4x4"
        setenv PRJ_DIR "/home/$USER/project/BCI-HW-ASIC-MT-FEP4x4"
        set git_url = "git@github.com:BlackrockNeurotech/BCI-HW-ASIC-MT-FEP4x4.git"
        goto check_project
        breaksw
    case 5:
        echo "Not ready to be shared, Contact Ali Zeinolabedin ..."
        #echo "Navigating to Mini-Tapeout: FEP4x4 ..."
        #setenv PRJ_DIR "/home/$USER/project/BCI-HW-ASIC-MT-FEP4x4"
        #goto check_project 
        breaksw
    case 6:
        #echo "Navigating to Test ..."
        #setenv PROJECT "AIDSP"
        #setenv PRJ_DIR "/home/$USER/project/AIDSP"
        #set git_url = "git@github.com:BlackrockNeurotech/AIDSP.git"
        #goto check_project
        #breaksw
    case q:
        echo "Exiting without changing directories."
        breaksw
    default:
        echo "Invalid selection. Exiting."
        breaksw
endsw


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



install_project:
    echo
    echo "${echo_boldblue}Project directory does not exist. Do you want to install the project? (y/n)${echo_reset}"
    set install_choice = $<
    if ( "$install_choice" == "y" || "$install_choice" == "Y" ) then
        echo "Changed to [/home/$USER/project] :"
        cd "/home/$USER/project"
        git clone "$git_url"
        set repo_name = `basename "$git_url" .git`
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
