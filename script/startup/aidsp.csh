#!/bin/csh
# ======================================================
# Script Name: aidsp.csh
# Author: Ali Zeinolabedin
# Created: 2025-08-11
# Description: `aidsp` command to select the project
# Version1.0
# ======================================================

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
echo "Enter the number of the project you want to navigate to, or 'q' to quit."

set choice = $<
switch ($choice)
    case 0:
        echo "Navigating to ASIC-W-ICONS ..."
        setenv PROJECT "ASIC-W-ICONS"
        setenv PRJ_DIR "/home/$USER/project/ASIC-W-ICONS/Cadence/w_icons/"
        cd $PRJ_DIR
        setenv ICPRO_DIR $PRJ_DIR
        breaksw
    case 1:
        echo "Navigating to IMEC Colibri ..."
        setenv PROJECT "ASIC-W-ICONS"
        setenv PRJ_DIR "/projects/BCI-ASIC/BONSAI-V1.x/Colibri_digital/"
        cd $PRJ_DIR
        setenv ICPRO_DIR $PRJ_DIR
        breaksw
    case 2:
        echo "Navigating to NEURALACE_VER1 ..."
        setenv PROJECT "BCI-HW-ASIC-BONSAI-V1.x:NEURALACE_VER1"
        setenv PRJ_DIR "/home/$USER/project/BCI-HW-ASIC-BONSAI-V1.x/NEURALACE_VER1"
        cd $PRJ_DIR
        setenv ICPRO_DIR $PRJ_DIR
        breaksw
    case 3:
        echo "Navigating to NEURALACE_VER1.1 ..."
        setenv PROJECT "BCI-HW-ASIC-BONSAI-V1.x:NEURALACE_VER1.1"
        setenv PRJ_DIR "/home/$USER/project/BCI-HW-ASIC-BONSAI-V1.x/NEURALACE_VER1.1"
        cd $PRJ_DIR
        setenv ICPRO_DIR $PRJ_DIR
        breaksw
    case 4:
        #echo "Not ready to be shared, Contact Ali Zeinolabedin ..."
        setenv PROJECT "BCI-HW-ASIC-BONSAI-V1.x:NEURALACE_VER1"
        echo "Navigating to Mini-Tapeout: FEP4x4 ..."
        setenv PRJ_DIR "/home/$USER/project/BCI-HW-ASIC-MT-FEP4x4"
        cd $PRJ_DIR
        setenv ICPRO_DIR $PRJ_DIR
        breaksw
    case 5:
        echo "Not ready to be shared, Contact Ali Zeinolabedin ..."
        #echo "Navigating to Mini-Tapeout: FEP4x4 ..."
        #setenv PRJ_DIR "/home/$USER/project/BCI-HW-ASIC-MT-FEP4x4"
        #cd $PRJ_DIR
        #setenv ICPRO_DIR $PRJ_DIR
        breaksw
    case q:
        echo "Exiting without changing directories."
        breaksw
    default:
        echo "Invalid selection. Exiting."
        breaksw
endsw

# Bold green escape codes
set boldgreen = "%{\033[1;32m%}"
set reset     = "%{\033[0m%}"

if ( ! $?OLDHOME ) setenv OLDHOME "$HOME"
setenv HOME "$PRJ_DIR"

set prompt = "[${boldgreen}$PROJECT${reset}] %~ %# "
