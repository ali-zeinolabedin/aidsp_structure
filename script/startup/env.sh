#!/bin/csh
# ======================================================
# Script Name: env.sh
# Author: Ali Zeinolabedin
# Created: 2025-08-11
# Description: Defining Global variables and aliases and sourcing all the commands
# Version1.0
# ======================================================
set cuser = `whoami`

# Define the function to select a project
alias aidsp 'source /projects/BCI-HW-ASIC/AIDSP/script/aidsp.csh'
alias pexit 'source /projects/BCI-HW-ASIC/AIDSP/script/pexit.csh'

alias cdp    'cd /home/$USER/project/{$PRJ_DIR}/'
alias cds    'cd /projects/'
alias cdu    'cd ${PRJ_DIR}/units'
alias cdi    'cd ${PRJ_DIR}'
alias cdr    'cd ${PRJ_DIR}/regressions'
alias ll     'ls -la'
alias rpl    'set temp=__tmp_swap && mv \!:1 $temp && mv \!:2 \!:1 && mv $temp \!:2'
# Git-rleated aliases
alias gits   'git status'
alias gita   'git add'
alias gitc   'git commit'
alias gitl   'git log'
alias gitlr  'git fetch & git log main..origin/main'
alias gitsh  'git show'
alias gitm   'git difftool'
alias lcad   'lmstat -c /tools/cadence/license_file -f'
alias lsim   'lmstat -c /tools/siemens/license_file -f' 

# system-level aliases
# find a folder in the current directory
alias findfl 'find . -type d -name'
# find a file in the current directory
alias findf  'find . -type f -name'
alias subl   'sublime_text'




