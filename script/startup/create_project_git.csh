#!/bin/csh
# ======================================================
# Script Name: create_project_git.csh
# Author: Ali Zeinolabedin
# Created: 2025-08-11
# Description: `create_project_git` 
# Version 1.0: 
# Connect a local project to Git (local or GitHub) and push if remote is given.
# ======================================================
# Usage:
#   connect_repo.csh <local_project_path> [github_repo_url]

if ( $#argv < 1 || $#argv > 2 ) then
    echo "Usage: $0 <local_project_path> [github_repo_url]"
    exit 1
endif

set PROJECT_PATH = $argv[1]
set REPO_URL = ""
if ( $#argv == 2 ) then
    set REPO_URL = $argv[2]
endif

if ( ! -d $PROJECT_PATH ) then
    echo "ERROR: Project path $PROJECT_PATH does not exist."
    exit 1
endif

cd $PROJECT_PATH

# Initialize if not already a git repo
if ( ! -d .git ) then
    echo "Initializing new git repository in $PROJECT_PATH"
    git init
endif

# Ensure main branch exists
set CURRENT_BRANCH = `git symbolic-ref --short HEAD >& /dev/null`
if ( "$CURRENT_BRANCH" != "main" ) then
    git branch -M main
endif

# If repo has no commits, do initial commit
git rev-parse --quiet --verify HEAD >& /dev/null
if ( $status != 0 ) then
    git add -A
    git commit -m "Initial commit"
else
    echo "Git repo already has commits."
endif

# If a remote is provided, wire it and push
if ( "$REPO_URL" != "" ) then
    git remote get-url origin >& /dev/null
    if ( $status == 0 ) then
        git remote set-url origin $REPO_URL
    else
        git remote add origin $REPO_URL
    endif

    echo "Pushing main branch to $REPO_URL ..."
    git push -u origin main
else
    echo "No remote provided. Local git repository is ready at $PROJECT_PATH"
endif
