#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'HELP'
Kiro Spec Bootstrap

Install Kiro spec workflow assets (Copilot instructions, chatmode, prompts, templates, tasks, validators)
into a target workspace.

Usage:
  kiro-spec-bootstrap.sh [--target <path>] [--feature <name>] [--subroot <dir>] [--install-extensions] [--force]

Options:
  --target <path>       Target workspace root (default: current directory)
  --feature <name>      Optional: seed a starter spec under .kiro/specs/<name>
  --subroot <dir>       Optional: create a named sub-root (e.g. 'app') and record it in .kiro/kiro-config.json so generated code is placed under it
  --install-extensions  Use VS Code `code` CLI to install recommended extensions (optional)
  --force               Overwrite existing files
HELP
}

TARGET="$(pwd)"
FEATURE=""
INCLUDE_EXT=0
FORCE=0
INSTALL_EXT=0
SUBROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2;;
  --feature) FEATURE="$2"; shift 2;;
  --subroot) SUBROOT="$2"; shift 2;;
  --install-extensions) INSTALL_EXT=1; shift;;
    --force) FORCE=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
SRC_GITHUB="$ROOT_DIR/.github"
SRC_VSCODE="$ROOT_DIR/.vscode"
SRC_SCRIPTS="$ROOT_DIR/scripts"

ensure_dir() { mkdir -p "$1"; }

copy_smart() {
  local src="$1" dest="$2"
  if [[ -e "$dest" && $FORCE -eq 0 ]]; then
    echo "Skip (exists): $dest"; return 0
  fi
  ensure_dir "$(dirname "$dest")"
  cp -R "$src" "$dest"
  echo "Copied: $dest"
}

copy_tree() {
  local src_dir="$1" rel="$2" dest_rel="$3"
  if [[ -d "$src_dir/$rel" ]]; then
    rsync -a $( [[ $FORCE -eq 1 ]] && echo "--delete" ) "$src_dir/$rel/" "$TARGET/$dest_rel/"
    echo "Synced: $dest_rel/"
  fi
}

echo "Bootstrapping Kiro spec into: $TARGET"

# If a subroot is requested, ensure it exists and record it in .kiro/kiro-config.json
if [[ -n "$SUBROOT" ]]; then
  echo "Creating subroot: $SUBROOT"
  ensure_dir "$TARGET/$SUBROOT"
  ensure_dir "$TARGET/.kiro"
  cat > "$TARGET/.kiro/kiro-config.json" <<JSON
{
  "subroot": "$SUBROOT"
}
JSON
  echo "Wrote: $TARGET/.kiro/kiro-config.json"
fi

# 1) .github content (instructions, chatmodes, prompts, templates, workflow doc)
copy_tree "$SRC_GITHUB" "instructions" ".github/instructions"
copy_tree "$SRC_GITHUB" "chatmodes" ".github/chatmodes"
copy_tree "$SRC_GITHUB" "prompts" ".github/prompts"
copy_tree "$SRC_GITHUB" "templates" ".github/templates"
copy_smart "$SRC_GITHUB/kiro-spec-workflow.md" "$TARGET/.github/kiro-spec-workflow.md" || true
if [[ -f "$ROOT_DIR/COPILOT.md" ]]; then
  copy_smart "$ROOT_DIR/COPILOT.md" "$TARGET/COPILOT.md" || true
fi

# 2) Validator scripts
ensure_dir "$TARGET/scripts"
copy_smart "$SRC_SCRIPTS/kiro-spec-validate.sh" "$TARGET/scripts/kiro-spec-validate.sh"
copy_smart "$SRC_SCRIPTS/kiro-spec-validate-latest.sh" "$TARGET/scripts/kiro-spec-validate-latest.sh"
chmod +x "$TARGET/scripts/kiro-spec-validate.sh" "$TARGET/scripts/kiro-spec-validate-latest.sh" || true

# 3) VS Code tasks
if [[ -f "$SRC_VSCODE/tasks.json" ]]; then
  ensure_dir "$TARGET/.vscode"
  copy_smart "$SRC_VSCODE/tasks.json" "$TARGET/.vscode/tasks.json"
fi

# 3b) VS Code recommended extensions (Copilot + Copilot Chat)
if [[ -f "$SRC_VSCODE/extensions.json" ]]; then
  ensure_dir "$TARGET/.vscode"
  copy_smart "$SRC_VSCODE/extensions.json" "$TARGET/.vscode/extensions.json"
fi

# 4) Workspace settings: enable Copilot instruction files
ensure_dir "$TARGET/.vscode"
python3 - "$TARGET/.vscode/settings.json" <<'PY'
import json, os, sys
path = sys.argv[1]
data = {}
if os.path.exists(path):
  try:
    with open(path) as f: data = json.load(f)
  except Exception:
    data = {}
data.setdefault('github.copilot.chat.codeGeneration.useInstructionFiles', True)
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w') as f:
  json.dump(data, f, indent=2)
print(f"Updated settings: {path}")
PY

# 4b) Optional: auto-install recommended extensions (requires `code` CLI)
if [[ $INSTALL_EXT -eq 1 ]]; then
  if command -v code >/dev/null 2>&1; then
    code --install-extension GitHub.copilot || true
    code --install-extension GitHub.copilot-chat || true
  else
    echo "VS Code 'code' CLI not found. Skipping auto-install of extensions." >&2
    echo "Tip: In VS Code, run 'Shell Command: Install 'code' command in PATH' from the Command Palette." >&2
  fi
fi

# 5) (Removed) dev-only extension support

# 6) Optional: seed a starter spec from templates
if [[ -n "$FEATURE" ]]; then
  # Determine where to place seeded specs. If SUBROOT was provided, put specs under it so code and specs live together.
  if [[ -n "$SUBROOT" ]]; then
    SPEC_DIR="$TARGET/$SUBROOT/.kiro/specs/$FEATURE"
  else
    SPEC_DIR="$TARGET/.kiro/specs/$FEATURE"
  fi
  ensure_dir "$SPEC_DIR"
  for f in requirements design tasks; do
    src_tmpl="$SRC_GITHUB/templates/kiro-$f-template.md"
    dest="$SPEC_DIR/$f.md"
    if [[ -f "$src_tmpl" ]]; then
      if [[ -f "$dest" && $FORCE -eq 0 ]]; then
        echo "Skip (exists): $dest"
      else
        sed "s/\[feature_name\]/$FEATURE/g" "$src_tmpl" > "$dest"
        echo "Seeded: $dest"
      fi
    fi
  done
  # Seed implementation plan
  src_plan="$SRC_GITHUB/templates/implementation-plan-template.md"
  dest_plan="$SPEC_DIR/IMPLEMENTATION_PLAN.md"
  if [[ -f "$src_plan" ]]; then
    if [[ -f "$dest_plan" && $FORCE -eq 0 ]]; then
      echo "Skip (exists): $dest_plan"
    else
      sed "s/\[feature_name\]/$FEATURE/g" "$src_plan" > "$dest_plan"
      echo "Seeded: $dest_plan"
    fi
  fi
  if [[ -f "$TARGET/scripts/kiro-spec-validate.sh" ]]; then
    bash "$TARGET/scripts/kiro-spec-validate.sh" "$FEATURE" all || true
  fi
fi

echo "Done. Next steps:"
echo "- Open $TARGET in VS Code. You'll be prompted to install recommended extensions (Copilot & Chat)."
echo "- Tasks available: Run Task → Kiro: Validate Spec / Validate Latest Spec"
if [[ -n "$SUBROOT" ]]; then
  echo "- Project files should be generated under subroot: $SUBROOT. Keep that folder as your project root in VS Code if desired."
fi
echo "- Copilot Chat: 'Kiro-Spec-Agent' chat mode should be available automatically."
echo "- Use the gated prompts to create requirements/design/tasks files (or edit the seeded ones)."
