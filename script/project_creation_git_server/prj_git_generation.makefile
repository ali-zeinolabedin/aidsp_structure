# =============================================================================
# Makefile — Admin-only: create and verify a shared, bare Git repo on the server
# Author: Ali Zeinolabedin <azeinolabedin@blackrockneuro.com>
# Organization: Blackrock Neurotech
# Created: 2025-08-15
# Purpose: Create a bare repo and (optionally) harden it for SSH-only usage.
# Obsolete -> use git ab instead
# =============================================================================

# Use bash as the shell for all recipe commands (instead of /bin/sh).
SHELL := /bin/bash
# Ensure each recipe runs in a single shell so state (cd, vars) persists across lines.
.ONESHELL:
# Shell strictness: -e exit on error, -u undefined var is error, pipefail handles pipelines, -c executes string.
.SHELLFLAGS := -eu -o pipefail -c
# When running plain `make` with no target, default to the `create` target.
.DEFAULT_GOAL := create
# Hide implicit command echo; only explicit `echo/printf` output shows for these targets.
.SILENT: help create test fixperms ssh_only show_ssh

# ----- ANSI color escape sequences for pretty output -----
# Bright green text (PASS / success messages).
GREEN  := \033[1;32m
# Bright red text (FAIL / error messages).
RED    := \033[1;31m
# Bright yellow text (informational banners).
YELLOW := \033[1;33m
# Reset terminal colors to default.
RESET  := \033[0m

# Default repository name (override on the command line).
REPO_NAME       ?= myrepo
# Shared parent directory that will hold the bare repo (override as needed).
SHARE_DIR       ?= /projects/BCI-HW-ASIC/projects_git
# Unix group that should own/write the repo contents (all five users belong to this).
GROUP           ?= ctr
# Owning user for the repo directory and contents (can be you or a 'git' service account).
OWNER           ?= azeinolabedin
# The default branch name that HEAD should reference (e.g., master or main).
DEFAULT_BRANCH  ?= master
# Optional: set to 1 to auto-create GROUP (kept for parity; off by default).
CREATE_GROUP    ?= 0

# SSH settings (used to print the remote URL and for convenience).
# Hostname (or IP) of the Git server users will SSH into.
SSH_HOST        ?= brml-0071.i2smicro.com
# Default SSH user; by default use the current username detected by make.
SSH_USER        ?= $(shell id -un)

# If set to 1, 'create' will also call 'ssh_only' to strip 'others' perms.
ENFORCE_SSH_ONLY ?= 1

# Full path to the bare repo directory constructed from SHARE_DIR and REPO_NAME.
REMOTE_REPO := $(SHARE_DIR)/$(REPO_NAME).git

# Mark `help` as a phony target (not a file on disk).
.PHONY: help
# Print usage instructions and examples with minimal noise.
help:
	# Blank line for readability.
	printf '%b\n' ""
	# Section header.
	printf '%b\n' "Targets:"
	# Describe the `create` target behavior.
	printf '%b\n' "  create    - Create a shared bare repo; applies SSH-only perms if ENFORCE_SSH_ONLY=1"
	# Describe the `ssh_only` target behavior.
	printf '%b\n' "  ssh_only  - Harden filesystem perms (owner+GROUP only; strips 'others')"
	# Describe the `show_ssh` target behavior.
	printf '%b\n' "  show_ssh  - Print the SSH remote URL"
	# Describe the `test` target behavior.
	printf '%b\n' "  test      - Verify repo exists and print status (green PASS / red FAIL)"
	# Describe the `fixperms` target behavior.
	printf '%b\n' "  fixperms  - Re-apply ownership and permissions"
	# Spacer line.
	printf '%b\n' ""
	# Examples header.
	printf '%b\n' "Examples:"
	# Example `create` invocation with SSH convenience values.
	printf '%b\n' "  make create   REPO_NAME=myproject SHARE_DIR=$(SHARE_DIR) GROUP=$(GROUP) OWNER=$(OWNER) SSH_HOST=$(SSH_HOST) SSH_USER=$(SSH_USER)"
	# Example `ssh_only` invocation.
	printf '%b\n' "  make ssh_only REPO_NAME=myproject SHARE_DIR=$(SHARE_DIR) GROUP=$(GROUP) OWNER=$(OWNER)"
	# Example `show_ssh` invocation.
	printf '%b\n' "  make show_ssh REPO_NAME=myproject SHARE_DIR=$(SHARE_DIR) SSH_HOST=$(SSH_HOST) SSH_USER=$(SSH_USER)"
	# Trailing blank line.
	printf '%b\n' ""

# -----------------------------------------------------------------------------
# Create the shared bare repository. If it already exists, print once and exit.
# Optionally call 'ssh_only' to strip 'others' perms (ENFORCE_SSH_ONLY=1).
# -----------------------------------------------------------------------------

# Mark `create` as a phony target.
.PHONY: create
# Main creation flow with idempotent behavior and colored output.
create:
	# Ensure `git` exists in PATH; print red error and exit if missing.
	command -v git >/dev/null || { printf '%b\n' "$(RED)Error: git not found in PATH$(RESET)"; exit 1; }

	# Optionally create the group if requested (CREATE_GROUP=1).
	if [ "$(CREATE_GROUP)" = "1" ]; then
		getent group "$(GROUP)" >/dev/null || groupadd "$(GROUP)"
	fi

	# Ensure the parent directory exists with SGID so new dirs inherit the group.
	printf '%b\n' "$(YELLOW)>> Ensuring parent dir with SGID for group inheritance: $(SHARE_DIR)$(RESET)"
	install -d -m 2775 -o "$(OWNER)" -g "$(GROUP)" "$(SHARE_DIR)"

	# Guard: if the repo path exists but lacks a Git `config`, it's not a repo—abort with a red error.
	if [ -d "$(REMOTE_REPO)" ] && [ ! -f "$(REMOTE_REPO)/config" ]; then
		printf '%b\n' "$(RED)ERROR: $(REMOTE_REPO) exists but is not a git repo. Move/remove it, then re-run.$(RESET)"
		exit 2
	fi

	# Idempotency check: if it's already a Git repo, print one line and exit success.
	if git --git-dir="$(REMOTE_REPO)" rev-parse --git-dir >/dev/null 2>&1; then
		printf '%b\n' "$(YELLOW)>> Repository already exists at $(REMOTE_REPO)$(RESET)"
		# Optionally enforce SSH-only on existing repo too.
		if [ "$(ENFORCE_SSH_ONLY)" = "1" ]; then
			$(MAKE) --no-print-directory ssh_only REPO_NAME="$(REPO_NAME)" SHARE_DIR="$(SHARE_DIR)" GROUP="$(GROUP)" OWNER="$(OWNER)"
		fi
		# Show the SSH URL for convenience.
		$(MAKE) --no-print-directory show_ssh REPO_NAME="$(REPO_NAME)" SHARE_DIR="$(SHARE_DIR)" SSH_HOST="$(SSH_HOST)" SSH_USER="$(SSH_USER)"
		exit 0
	fi

	# Fresh initialization of the bare repo with group sharing.
	printf '%b\n' "$(YELLOW)>> Creating bare repo: $(REMOTE_REPO)$(RESET)"
	git init --bare --shared=group "$(REMOTE_REPO)"
	# Point HEAD to the default branch using a proper symbolic ref.
	git --git-dir="$(REMOTE_REPO)" symbolic-ref HEAD "refs/heads/$(DEFAULT_BRANCH)"

	# Apply ownership and group-writable permissions so collaborators can push.
	printf '%b\n' "$(YELLOW)>> Setting ownership and group-writable perms$(RESET)"
	# Recursively set OWNER:GROUP on the repo directory.
	chown -R "$(OWNER)":"$(GROUP)" "$(REMOTE_REPO)"
	# Ensure group write and SGID on directories (inherit group).
	chmod -R g+ws "$(REMOTE_REPO)"
	# Configure Git to create group-writable files going forward.
	git --git-dir="$(REMOTE_REPO)" config core.sharedRepository group

	# If requested, strip 'others' perms so only owner+group can access on the filesystem.
	if [ "$(ENFORCE_SSH_ONLY)" = "1" ]; then
		printf '%b\n' "$(YELLOW)>> Enforcing SSH-only: removing 'others' permissions$(RESET)"
		chmod -R o-rwx "$(REMOTE_REPO)"
	fi

	# Final success banner in green.
	printf '%b\n' "$(GREEN)>> Done. Central repo ready at: $(REMOTE_REPO)$(RESET)"
	# Print the SSH URL.
	$(MAKE) --no-print-directory show_ssh REPO_NAME="$(REPO_NAME)" SHARE_DIR="$(SHARE_DIR)" SSH_HOST="$(SSH_HOST)" SSH_USER="$(SSH_USER)"

# -----------------------------------------------------------------------------
# Harden filesystem perms so only owner+GROUP can access; removes 'others' perms.
# This helps steer usage to SSH pushes rather than direct edits via a shared mount.
# -----------------------------------------------------------------------------

# Mark `ssh_only` as a phony target.
.PHONY: ssh_only
# Harden the existing repo for SSH-oriented usage.
ssh_only:
	# Ensure git is available.
	command -v git >/dev/null || { printf '%b\n' "$(RED)Error: git not found in PATH$(RESET)"; exit 1; }
	# Verify the path points to a git repo.
	if ! git --git-dir="$(REMOTE_REPO)" rev-parse --git-dir >/dev/null 2>&1; then
		printf '%b\n' "$(RED)ERROR: not a git repo at $(REMOTE_REPO)$(RESET)"
		exit 1
	fi
	# Banner: applying hardening.
	printf '%b\n' "$(YELLOW)>> Applying SSH-only filesystem hardening on $(REMOTE_REPO)$(RESET)"
	# Ensure ownership matches the intended OWNER:GROUP.
	chown -R "$(OWNER)":"$(GROUP)" "$(REMOTE_REPO)"
	# Ensure group write and SGID on directories.
	chmod -R g+ws "$(REMOTE_REPO)"
	# Remove all 'others' permissions so non-group users on the share cannot access.
	chmod -R o-rwx "$(REMOTE_REPO)"
	# Keep Git creating group-writable files (shared repo semantics).
	git --git-dir="$(REMOTE_REPO)" config core.sharedRepository group
	# Success banner.
	printf '%b\n' "$(GREEN)>> SSH-only hardening applied.$(RESET)"
	# Show the SSH URL for quick copy/paste.
	$(MAKE) --no-print-directory show_ssh REPO_NAME="$(REPO_NAME)" SHARE_DIR="$(SHARE_DIR)" SSH_HOST="$(SSH_HOST)" SSH_USER="$(SSH_USER)"

# -----------------------------------------------------------------------------
# Print the SSH remote URL clients should use (informational).
# -----------------------------------------------------------------------------

# Mark `show_ssh` as a phony target.
.PHONY: show_ssh
# Display the SSH URL in a friendly format.
show_ssh:
	# Print a suggested SSH remote (edit SSH_HOST/SSH_USER as needed).
	printf '%b\n' "$(YELLOW)>> SSH remote URL:$(RESET) $(GREEN)$(SSH_USER)@$(SSH_HOST):$(REMOTE_REPO)$(RESET)"
	# Hint for configuring local remotes (non-fatal).
	printf '%b\n' "    To use: git remote add origin $(SSH_USER)@$(SSH_HOST):$(REMOTE_REPO)"

# -----------------------------------------------------------------------------
# Non-destructive verification of the created repo (colorized PASS/FAIL)
# -----------------------------------------------------------------------------

# Mark `test` as a phony target.
.PHONY: test
# Verify that the repo exists and print useful diagnostics with colors.
test:
	# Ensure `git` exists; bail out with red if not.
	command -v git >/dev/null || { printf '%b\n' "$(RED)Error: git not found in PATH$(RESET)"; exit 1; }

	# Print which repo we're checking.
	printf '%b\n' "$(YELLOW)>> Verifying repo at: $(REMOTE_REPO)$(RESET)"

	# Core existence check controls pass/fail.
	if git --git-dir="$(REMOTE_REPO)" rev-parse --git-dir >/dev/null 2>&1; then
		# Repo exists: print green PASS.
		printf '%b\n' "$(GREEN)>> PASS: repo exists$(RESET)"
	else
		# Not a repo: print red FAIL and exit with error.
		printf '%b\n' "$(RED)>> FAIL: not a git repo at $(REMOTE_REPO)$(RESET)"
		exit 1
	fi

	# (Informational) Print basic repo properties; these do not flip overall status.
	printf '%b\n' ""
	printf '%b\n' "== Basic properties =="
	# Is it bare? (expected: true)
	printf '%b'   "is bare?            "; git --git-dir="$(REMOTE_REPO)" rev-parse --is-bare-repository || true; printf '\n'
	# sharedRepository config value (expected: group)
	printf '%b'   "sharedRepository:   "; git --git-dir="$(REMOTE_REPO)" config --get core.sharedRepository || printf '(unset)\n'
	# Symbolic HEAD target (e.g., refs/heads/master or main)
	printf '%b'   "HEAD symbolic-ref:  "; git --git-dir="$(REMOTE_REPO)" symbolic-ref HEAD || printf '(none)\n'
	# Raw HEAD file first line (e.g., ref: refs/heads/master)
	printf '%b'   "HEAD file:          "; head -n1 "$(REMOTE_REPO)/HEAD" || true; printf '\n'

	# (Informational) Show directory permissions for a quick visual check.
	printf '%b\n' ""
	printf '%b\n' "== Permissions =="
	ls -ld "$(REMOTE_REPO)" "$(REMOTE_REPO)/objects" || true
	printf '%b\n' ""

	# Final success banner.
	printf '%b\n' "$(GREEN)>> Overall: TEST PASSED$(RESET)"

# -----------------------------------------------------------------------------
# Re-apply ownership/permissions without touching repository data
# -----------------------------------------------------------------------------

# Mark `fixperms` as a phony target.
.PHONY: fixperms
# Repair ownership and permissions on an existing repo (no content changes).
fixperms:
	# Ensure `git` exists; bail out with red if not.
	command -v git >/dev/null || { printf '%b\n' "$(RED)Error: git not found in PATH$(RESET)"; exit 1; }
	# Banner to indicate action.
	printf '%b\n' "$(YELLOW)>> Fixing ownership/permissions on $(REMOTE_REPO)$(RESET)"
	# Recursively set OWNER:GROUP to ensure the right ownership.
	chown -R "$(OWNER)":"$(GROUP)" "$(REMOTE_REPO)"
	# Ensure group write and SGID bit on directories for future files/dirs.
	chmod -R g+ws "$(REMOTE_REPO)"
	# Ensure Git itself keeps creating group-writable files.
	git --git-dir="$(REMOTE_REPO)" config core.sharedRepository group
	# Success banner in green.
	printf '%b\n' "$(GREEN)>> Perms refreshed.$(RESET)"
