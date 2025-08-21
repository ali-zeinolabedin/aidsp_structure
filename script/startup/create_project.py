#!/usr/bin/env python3.6

# ======================================================
# Script Name: create_project.py
# Author: Ali Zeinolabedin
# Created: 2025-08-12
# Description: Select a project from a YAML file and create the project
# Version: 1.0
#    - Should be only run by the admin not everyone, to provide the right access to the git of the project too
# ======================================================

#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-
"""
Scaffold or update a project structure from a declarative YAML file.
"""

import argparse
import os
import sys
import shutil
from pathlib import Path
from textwrap import dedent

# ---------- Colors ----------
RED   = "\033[91m"
GREEN = "\033[92m"
RESET = "\033[0m"

# ---------- Help examples ----------
EXAMPLES = dedent("""
Examples
========

Basic
-----
1) Preview (no changes):
   create_project --yaml structure.yaml -p Demo --dry-run

2) Create a project (root + README only):
   create_project --yaml structure.yaml -p Demo

Enable Optional Components
--------------------------
3) Add optional directories when creating:
   create_project --yaml structure.yaml -p Demo \
     --enable global_src,units,env.simulation --vars sim=cdssim

4) Create simulation with gtkwave:
   create_project --yaml structure.yaml -p Demo \
     --enable env.simulation --vars sim=gtkwave

5) Create simulation with vivado (requires YAML entry; see below):
   create_project --yaml structure.yaml -p Demo \
     --enable env.simulation --vars sim=vivado

Update Existing Project (non-destructive)
-----------------------------------------
6) Later add 'units' to an existing Demo:
   create_project --yaml structure.yaml -p Demo \
     --add --enable units

7) Add multiple components at once:
   create_project --yaml structure.yaml -p Demo \
     --add --enable units,env.python,env.icglue

8) Preview what --add would do:
   create_project --yaml structure.yaml -p Demo \
     --add --enable units --dry-run

Overwrites & Safety
-------------------
9) Overwrite existing files intentionally:
   create_project --yaml structure.yaml -p Demo \
     --enable env.simulation --vars sim=gtkwave --force

10) Add new stuff but keep current files intact (default add-mode behavior):
    create_project --yaml structure.yaml -p Demo --add --enable units

11) add the vivado file to the exisiting env.simulation folder
    create_project --yaml structure.yaml -p Demo --add --enable env.simulation --vars sim=modelsim

Template Files Location
-----------------------
12) If your template files live beside the YAML (default), nothing to do.
    If they live elsewhere, set template root:
    create_project --yaml structure.yaml -p Demo \
      --enable env.simulation --vars sim=cdssim \
      --template-root /path/to/templates

YAML Structure Preview
----------------------
13) Show help + a tree preview of the YAML:
    create_project -h --yaml structure.yaml

Vars & Tokens
-------------
14) Pass extra substitutions (used in {{TOKENS}} inside files/paths/content):
    create_project --yaml structure.yaml -p Demo \
      --vars AUTHOR=$USER LICENSE=Proprietary

Common Pitfalls
---------------
- --enable takes DIRECTORY IDS (e.g., env.simulation), not file names.
- If a conditional file doesn't appear, check:
  * you enabled its parent directory id
  * the 'only_if: var=value' matches your --vars
  * the template file exists under --template-root (when using 'from:')

Vivado Example (YAML Snippet)
-----------------------------
Add this under the 'env.simulation.files' list in your YAML:

  - name: "Makefile.project.vivado"
    from: "_files/env/simulation/Makefile.project.vivado"
    only_if: "sim=vivado"

Then run:
  create_project --yaml structure.yaml -p Demo \
    --enable env.simulation --vars sim=vivado

csh Alias (bake in YAML path)
-----------------------------
Put this in ~/.cshrc (one logical line; the backslash continues the line):
  alias create_project 'python3.6 /path/to/create_project.py \
  --yaml /path/to/structure.yaml \!*'
  rehash

Now you can run simply:
  create_project -p Demo --enable env.simulation --vars sim=gtkwave
""")

# ---------- Optional dependency ----------
try:
    import yaml  # PyYAML
except Exception:
    sys.stderr.write(f"{RED}ERROR: PyYAML is required (pip install pyyaml){RESET}\n")
    sys.exit(2)


# ---------- Colored argparse ----------
class ColorArgParser(argparse.ArgumentParser):
    """ArgumentParser that prints errors in RED and shows help."""
    def error(self, message):
        sys.stderr.write(f"{RED}ERROR: {message}{RESET}\n\n")
        self.print_help(sys.stderr)
        sys.exit(2)


# ---------- Utilities ----------
def epath(p: str) -> Path:
    """Expand ~ and $VARS and return a resolved Path."""
    return Path(os.path.expanduser(os.path.expandvars(str(p)))).resolve()

def load_yaml(path: Path) -> dict:
    """Load YAML file as dict (empty dict if file is empty)."""
    with open(path, "r") as f:
        return yaml.safe_load(f) or {}

def parse_vars(kvs):
    """Parse KEY=VAL pairs from CLI into a dict (expands env vars in values)."""
    out = {}
    for kv in kvs or []:
        if "=" not in kv:
            raise ValueError(f"Invalid KEY=VAL: {kv!r}")
        k, v = kv.split("=", 1)
        out[k.strip()] = os.path.expandvars(v)
    return out

def render(s, vars_):
    """Replace {{VAR}} tokens in string s with vars_[VAR]."""
    out = str(s)
    for k, v in vars_.items():
        out = out.replace(f"{{{{{k}}}}}", str(v))
    return out

def is_text_file(path: Path, n=4096) -> bool:
    """Heuristic: True if likely UTF-8 text, else False."""
    try:
        with open(path, "rb") as f:
            f.read(n).decode("utf-8")
        return True
    except Exception:
        return False

def copy_rendered(src: Path, dst: Path, vars_: dict):
    """Copy src→dst; render {{TOKENS}} if text, else copy binary."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if is_text_file(src):
        text = src.read_text()
        dst.write_text(render(text, vars_))
    else:
        shutil.copy2(str(src), str(dst))

def should_include(node: dict, enabled_set: set) -> bool:
    """Include node if not optional; or optional+id present in enabled_set."""
    if node.get("optional") and node.get("id"):
        return node["id"] in enabled_set
    return True

def cond_pass(only_if: str, vars_: dict) -> bool:
    """Evaluate only_if 'var=value' against vars_ (True if matches or not set)."""
    if not only_if:
        return True
    if "=" not in only_if:
        raise ValueError(f"only_if must be var=value, got {only_if!r}")
    k, v = only_if.split("=", 1)
    return str(vars_.get(k.strip(), "")) == v.strip()


# ---------- Tree rendering for help (no duplicate headers) ----------
def _tree_node_header(node: dict) -> str:
    """Header text for a directory node: dir [id=..., optional]."""
    label = node.get("dir", "(unnamed)")
    bits = []
    if node.get("id"):
        bits.append(f"id={node['id']}")
    if node.get("optional"):
        bits.append("optional")
    if bits:
        label += " [" + ", ".join(bits) + "]"
    return label

def _format_file_entry(f: dict) -> str:
    """One-line description of a file entry for tree view."""
    name = f.get("name", "(unnamed)")
    cond = f.get("only_if")
    src  = f.get("from")
    if src and cond:
        return f"{name} <- {src}  (only_if: {cond})"
    if src:
        return f"{name} <- {src}"
    if cond:
        return f"{name}  (only_if: {cond})"
    return name

def _walk_tree_lines(node: dict, prefix: str = "", is_root: bool = False, is_last: bool = True) -> list:
    """
    Produce ascii-tree lines for directories and files defined in YAML,
    without double-printing headers and with proper connectors.
    Structural preview only (does not evaluate conditions/tokens).
    """
    lines = []

    # Print this node's header
    if is_root:
        lines.append(_tree_node_header(node))
        next_prefix = ""  # root starts flush-left
    else:
        connector = "└── " if is_last else "├── "
        lines.append(prefix + connector + _tree_node_header(node))
        next_prefix = prefix + ("    " if is_last else "│   ")

    # Files at this level
    files = node.get("files") or []
    children = node.get("children") or []
    for i, f in enumerate(files):
        last_file = (i == len(files) - 1) and not children
        f_conn = "└── " if last_file else "├── "
        lines.append(next_prefix + f_conn + _format_file_entry(f))

    # Recurse into child directories
    for idx, child in enumerate(children):
        child_last = (idx == len(children) - 1)
        lines.extend(_walk_tree_lines(child, next_prefix, is_root=False, is_last=child_last))

    return lines


# ---------- Core traversal ----------
def walk(node: dict, cwd: Path, vars_: dict, template_root: Path, enabled_set: set,
         *, force=False, dry_run=False, add=False, created=None):
    """
    Recursively create directories/files per YAML spec; collect actions in `created`.

    add: when True, existing files are *skipped* (unless force=True), so you can
         extend an existing project without errors.
    """
    created = created or []

    name = node.get("dir")
    if name is None:
        raise ValueError("Each node must define 'dir'")
    dir_path = cwd / render(name, vars_)

    if should_include(node, enabled_set):
        # directory
        if dry_run:
            created.append(("DIR", str(dir_path)))
        else:
            dir_path.mkdir(parents=True, exist_ok=True)

        # files in this dir
        for f in (node.get("files") or []):
            if "name" not in f:
                raise ValueError(f"A file entry under '{dir_path}' is missing 'name'")
            fname = render(f["name"], vars_)
            dst = dir_path / fname

            if not cond_pass(f.get("only_if"), vars_):
                continue

            if dry_run:
                src_info = f.get("from")
                created.append(("FILE", f"{dst}" + (f" <- {template_root / src_info}" if src_info else "")))
            else:
                # --- key change: --add skips existing files unless --force ---
                if dst.exists():
                    if add and not force:
                        continue
                    if not force:
                        raise FileExistsError(f"Exists: {dst} (use --force to overwrite)")

                if "content" in f:
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    dst.write_text(render(f["content"], vars_))
                elif "from" in f:
                    src = template_root / f["from"]
                    if not src.exists():
                        raise FileNotFoundError(f"Missing template file: {src}")
                    copy_rendered(src, dst, vars_)
                else:
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    dst.touch()

        # children
        for child in (node.get("children") or []):
            if not should_include(child, enabled_set):
                continue
            walk(child, dir_path, vars_, template_root, enabled_set,
                 force=force, dry_run=dry_run, add=add, created=created)

    return created


# ---------- Main ----------
def main():
    # Custom help to allow "-h --yaml ..." tree preview; keep formatting with RawTextHelpFormatter
    ap = ColorArgParser(
        add_help=False,
        description="Scaffold/update a project from a YAML structure file.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    ap.add_argument("--yaml", required=False, help="[required] Path to structure.yaml definition (include with -h to preview tree)")
    ap.add_argument("--project", "-p", required=False, help="[required] Project name used to substitute {{PROJECT}}")
    ap.add_argument("--dest", "-d", default=".", help="[optional] Destination directory (default: current working directory)")
    ap.add_argument("--vars", nargs="*", metavar="KEY=VAL", help="[optional] Extra substitutions (e.g., sim=gtkwave AUTHOR=$USER)")
    ap.add_argument("--enable", help="[optional] Comma-separated component ids to include (e.g., global_src,env.simulation)")
    ap.add_argument("--template-root", help="[optional] Directory where 'from:' files are looked up (default: YAML file's directory)")
    ap.add_argument("--add", action="store_true", help="[optional] Update/add missing items (non-destructive, skips existing files unless --force)")
    ap.add_argument("--force", action="store_true", help="[optional] Overwrite files if they already exist")
    ap.add_argument("--dry-run", action="store_true", help="[optional] Preview actions without creating/updating files)")
    ap.add_argument("-h", "--help", action="store_true", help="[optional] Show help (if --yaml is provided, also show YAML tree)")

    # attach examples to help epilog
    ap.epilog = EXAMPLES

    args, unknown = ap.parse_known_args()

    # Help path (optionally render tree if --yaml provided)
    if args.help:
        ap.print_help()
        if args.yaml:
            try:
                spec_path = epath(args.yaml)
                spec = load_yaml(spec_path)
                root = spec.get("root")
                if not root:
                    sys.stderr.write(f"{RED}\nERROR: YAML must contain 'root' mapping to render tree{RESET}\n")
                else:
                    print(f"\n{GREEN}YAML structure preview: {spec_path}{RESET}")
                    for line in _walk_tree_lines(root, is_root=True):
                        print(line)
                    print(f"\n{GREEN}Tip:{RESET} Entries with [id=..., optional] can be toggled via --enable <id1,id2,...>")
            except Exception as e:
                sys.stderr.write(f"{RED}\nERROR: Failed to load YAML for help preview: {e}{RESET}\n")
        else:
            print(f"\n{GREEN}Tip:{RESET} Pass --yaml PATH together with -h to preview the structure tree.")
        return 0

    # Enforce required args now
    if not args.yaml or not args.project:
        ap.error("the following arguments are required: --yaml, --project")

    # 1) Load YAML spec
    spec_path = epath(args.yaml)
    try:
        spec = load_yaml(spec_path)
    except Exception as e:
        sys.stderr.write(f"{RED}ERROR: Failed to read YAML: {e}{RESET}\n")
        return 1

    # 2) Build variables (defaults + CLI + PROJECT)
    defaults = spec.get("defaults") or {}
    vars_ = dict(defaults)
    try:
        vars_.update(parse_vars(args.vars))
    except Exception as e:
        sys.stderr.write(f"{RED}ERROR: {e}{RESET}\n")
        return 1
    vars_["PROJECT"] = args.project

    # 3) Enabled ids
    enabled = set()
    if args.enable:
        enabled = set(s.strip() for s in args.enable.split(",") if s.strip())

    # 4) Paths
    dest_root = epath(args.dest)
    try:
        dest_root.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        sys.stderr.write(f"{RED}ERROR: Cannot create/access destination '{dest_root}': {e}{RESET}\n")
        return 1
    template_root = epath(args.template_root) if args.template_root else spec_path.parent

    # 5) Root node
    root = spec.get("root")
    if not root:
        sys.stderr.write(f"{RED}ERROR: YAML must contain 'root' mapping{RESET}\n")
        return 1

    # 6) Execute (or preview)
    try:
        created = walk(root, dest_root, vars_, template_root, enabled,
                       force=args.force, dry_run=args.dry_run, add=args.add)
    except (FileExistsError, FileNotFoundError, ValueError) as e:
        sys.stderr.write(f"{RED}ERROR: {e}{RESET}\n")
        return 1
    except Exception as e:
        sys.stderr.write(f"{RED}ERROR: Unexpected failure: {e}{RESET}\n")
        return 1

    # 7) Report
    if args.dry_run:
        for kind, msg in created:
            print(f"[{kind}] {msg}")
    else:
        action = "Updated" if args.add else "Created/Updated"
        print(f"{GREEN}{action} project '{args.project}' at {dest_root}{RESET}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
