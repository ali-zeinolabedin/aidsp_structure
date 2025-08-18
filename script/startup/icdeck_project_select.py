#!/usr/bin/env python3.6
# ======================================================
# Script Name: aidsp_project_select.py
# Author: Ali Zeinolabedin
# Created: 2025-08-12
# Description: Select a project from a YAML file and emit csh env exports
# Version: 1.3
#    - Adding function print_banner
#    - Updating function print_menu to create a table for the project selection
# ======================================================
from __future__ import print_function

import argparse
import os
import sys

# Try to import PyYAML for YAML parsing. Exit with a clear error if not installed.
try:
    import yaml
except Exception as e:
    sys.stderr.write("ERROR: PyYAML is required (pip install pyyaml)\n")
    sys.exit(2)

def print_banner(color_name='cyan'):
    """
    Print the ICDECK ASCII banner from 'icdeck.txt' with color,
    and add the version & author signature underneath.
    """
    _, tout = _tty_streams()
    banner_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'icdeck.txt')
    color = resolve_color(color_name, 'cyan')
    reset = COLOR_ANSI['reset']

    try:
        with open(banner_path, 'r') as f:
            for line in f:
                print(f"{color}{line.rstrip()}{reset}", file=tout)
    except Exception:
        pass  # Ignore if banner is missing

    # Add signature block below the banner
    print(f"{color}  ICDECK v1.2a — Integrated Circuit Design & Engineering Collaboration  {reset}", file=tout)
    print(f"{color}                   (C) 2025 Blackrock Neurotech                         {reset}", file=tout)
    print(f"{color}        Author/Maintainer/Point of Contact: Ali Zeinolabedin            {reset}", file=tout)


# ---------- terminal helpers ----------
def _tty_streams():
    """
    Return (tin, tout) file-like objs bound to the user's terminal (/dev/tty).
    This ensures that UI prompts and input work even when stdout is being
    captured by the shell (e.g., under `eval`).
    Falls back to None for tin, and stderr for tout if unavailable.
    """
    tin = None
    tout = None
    try:
        tin = open('/dev/tty', 'r')  # Try to open terminal for input
    except Exception:
        pass
    try:
        tout = open('/dev/tty', 'w')  # Try to open terminal for output
    except Exception:
        tout = sys.stderr  # Fallback to stderr if /dev/tty is not available
    return tin, tout

def ui_print(msg="", end="\n"):
    """
    Print user-facing text to the terminal (never stdout).
    This is for menu and error messages, not for shell variable output.
    """
    _, tout = _tty_streams()
    print(msg, end=end, file=tout, flush=True)

def ui_input(prompt):
    """
    Prompt and read from the terminal (so it still works under backticks).
    Ensures the prompt is visible and input is readable even when the
    script's stdout is being redirected.
    """
    tin, _ = _tty_streams()
    ui_print(prompt, end="")
    if tin is None:
        # Fallback to stdin (may be empty under `eval`)
        return sys.stdin.readline().strip()
    return tin.readline().strip()

# ---------- quoting / safety ----------
def csh_quote(value):
    """
    Quote a value safely for csh setenv.
    Use double quotes; escape embedded backslashes and double quotes.
    """
    s = "" if value is None else str(value)
    s = s.replace("\\", "\\\\").replace('"', '\\"')
    return '"%s"' % s

# ---------- config loading ----------
def load_config(yaml_path):
    """
    Load and validate the YAML configuration file.
    Ensures the file exists, is valid YAML, and contains a 'projects' list.
    """
    if not os.path.isfile(yaml_path):
        ui_print("ERROR: projects.yaml not found at: %s" % yaml_path)
        sys.exit(1)
    try:
        with open(yaml_path, 'r') as f:
            config = yaml.safe_load(f)
    except Exception as e:
        ui_print("ERROR: Failed to read YAML: %s" % e)
        sys.exit(1)

    if not isinstance(config, dict) or 'projects' not in config:
        ui_print("ERROR: YAML must contain a top-level 'projects' list.")
        sys.exit(1)

    projects = config.get('projects') or []
    if not isinstance(projects, list) or not projects:
        ui_print("ERROR: No projects defined under 'projects'.")
        sys.exit(1)

    return config, projects

# ---------- colors for UI ----------
# ANSI color codes for menu display
COLOR_ANSI = {
    'green': '\033[1;32m',
    'yellow': '\033[1;33m',
    'blue': '\033[1;34m',
    'red': '\033[1;31m',
    'purple': '\033[1;35m',
    'cyan': '\033[1;36m',
    'white': '\033[1;37m',
    'reset': '\033[0m',
}

def resolve_color(name, fallback):
    """
    Get the ANSI color code for a color name, or fallback if not found.
    """
    return COLOR_ANSI.get(name, COLOR_ANSI.get(fallback, COLOR_ANSI['green']))

# ---------- UI ----------
def print_menu(projects, default_color_name, quit_color_name):
    """
    Print the interactive menu of projects using a wide ASCII table.
    Simply bumps widths so alignment looks clean without fancy ANSI handling.
    """
    reset = COLOR_ANSI['reset']
    default_color = resolve_color(default_color_name, 'green')
    quit_color = resolve_color(quit_color_name, 'blue')

    # Find the longest plain project name
    longest = max((len(p.get('name', '')) for p in projects), default=0)

    # Make the column generously wide: at least 64, or longest+8, capped at 100
    name_col_width = min(max(64, longest + 8), 100)

    # Header
    ui_print(f"╔════╤{'═' * name_col_width}═╗")
    ui_print(f"║ ID │ {'Project Name'.ljust(name_col_width)}║")
    ui_print(f"╟────┼{'─' * name_col_width}─╢")

    # Rows (color per row, padding done on the plain name)
    for idx, proj in enumerate(projects):
        name = proj.get('name', '(unnamed)')
        color_name = proj.get('color', default_color_name)
        color = resolve_color(color_name, default_color_name)

        line = f"║ {str(idx).ljust(2)} │ {name.ljust(name_col_width)}║"
        ui_print(f"{color}{line}{reset}")

    # Footer and quit
    ui_print(f"╚════╧{'═' * name_col_width}═╝")
    ui_print(f"{quit_color}q) Quit{reset}")



def interactive_select(projects, default_color_name, quit_color_name):
    """
    Show the menu, prompt for user selection, and return the chosen project dict.
    Exits if the user chooses 'q' or enters an invalid selection.
    """
    print_menu(projects, default_color_name, quit_color_name)
    choice = ui_input("Enter the project index you want to navigate to, or 'q' to quit: ").strip()
    if choice.lower() == 'q':
        # Quit silently: no stdout so eval does nothing
        sys.exit(0)
    try:
        idx = int(choice)
        ##print(len(projects))
        if idx < 0 or idx >= len(projects):
            raise ValueError
    except Exception:
        ui_print("Invalid selection. Exiting.")
        sys.exit(1)
    
    return projects[idx]

def select_by_name(projects, name):
    """
    Select a project by its name (case-insensitive).
    """
    for p in projects:
        if str(p.get('name', '')).strip().lower() == str(name).strip().lower():
            return p
    ui_print(f"ERROR: No project named '{name}'.")
    sys.exit(1)

def select_by_index(projects, index):
    """
    Select a project by its index in the list.
    """
    try:
        index = int(index)
    except Exception:
        ui_print("ERROR: --index must be an integer.")
        sys.exit(1)
    if index < 0 or index >= len(projects):
        ui_print(f"ERROR: --index out of range (0..{len(projects)-1}).")
        sys.exit(1)
    return projects[index]

# ---------- emit ONLY env to stdout ----------
def output_csh_vars(proj):
    """
    Print csh setenv commands for the selected project to stdout.
    This output is captured and executed by the calling csh script.
    """
    def csh_quote(value):
        s = "" if value is None else str(value)
        s = s.replace("\\", "\\\\").replace('"', '\\"')
        return '"%s"' % s

    name = proj.get('name')
    path = proj.get('path')
    git_url = proj.get('git_url')
    
    if not name or not path:
        ui_print("ERROR: Project entry must include 'name' and 'path'.")
        sys.exit(1)

    # append semicolons so multiple commands can live on one line
    print("setenv PROJECT %s;" % csh_quote(name))
    print("setenv PRJ_DIR %s;" % csh_quote(path))
    if git_url is not None:
        print("setenv GIT_URL %s;" % csh_quote(git_url))

# ---------- main ----------
def parse_args():
    """
    Parse command-line arguments for non-interactive use.
    """
    ap = argparse.ArgumentParser(
        description="Select a project and emit csh environment exports."
    )
    ap.add_argument(
        "--project", "-p",
        help="Select by project name (case-insensitive, bypasses interactive menu)."
    )
    ap.add_argument(
        "--index", "-i",
        help="Select by project index (bypasses interactive menu)."
    )
    ap.add_argument(
        "--yaml",
        help="Path to projects.yaml (default: alongside this script)."
    )
    return ap.parse_args()

def main():
    """
    Main entry point: parse args, load config, select project, emit csh vars.
    """
    print_banner('cyan')  # or 'green', 'yellow', etc.

    args = parse_args()
    
    # Locate YAML
    base_dir = os.path.dirname(os.path.realpath(__file__))
    yaml_path = args.yaml if args.yaml else os.path.join(base_dir, 'projects.yaml')

    config, projects = load_config(yaml_path)

    colors_cfg = config.get('colors', {}) if isinstance(config.get('colors', {}), dict) else {}
    default_color_name = colors_cfg.get('default', 'green')
    quit_color_name = colors_cfg.get('quit', 'blue')
    
    # Choose project
    if args.project:
        proj = select_by_name(projects, args.project)
    elif args.index is not None:
        proj = select_by_index(projects, args.index)
    else:
        proj = interactive_select(projects, default_color_name, quit_color_name)
    
    # Emit env to stdout (only)
    output_csh_vars(proj)

if __name__ == "__main__":
    main()
