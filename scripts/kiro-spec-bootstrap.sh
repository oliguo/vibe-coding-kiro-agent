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
  --interactive         Force interactive prompts even when other flags are provided
  --yes, -y             Skip final confirmation (CI / automated runs)
  --dry-run             Show what would be done without making changes
  --no-install          Do not attempt to install VS Code extensions even if --install-extensions is present
  --output-log <file>   Write an actions log (plain text) to <file>
  --emit-json <file>    Write machine-readable JSON describing planned actions to <file> (dry-run or real run)
  --log <file>          Convenience: write both plain log and JSON to <file> and <file>.json
HELP
}

TARGET="$(pwd)"
FEATURE=""
INCLUDE_EXT=0
FORCE=0
INSTALL_EXT=0
SUBROOT=""
INTERACTIVE=0
SKIP_CONFIRM=0
DRY_RUN=0
NO_INSTALL=0
OUTPUT_LOG=""
EMIT_JSON=""
LOG_FILE=""

# Remember original arg count to decide whether to run interactive prompts
ORIGINAL_ARGC="$#"

prompt_yes_no() {
  # prompt_yes_no "Question?" default
  local prompt="$1" default="$2" ans
  while :; do
    if [[ "$default" == "Y" || "$default" == "y" ]]; then
      read -rp "$prompt [Y/n]: " ans
      ans="${ans:-Y}"
    else
      read -rp "$prompt [y/N]: " ans
      ans="${ans:-N}"
    fi
    case "$ans" in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer y or n.";;
    esac
  done
}

# Logging helpers
LOG_LINES=()
JSON_ENTRIES=()
log() {
  local msg="$1"
  LOG_LINES+=("$msg")
  if [[ -n "$OUTPUT_LOG" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] $msg" >> "$OUTPUT_LOG"
    else
      echo "$msg" >> "$OUTPUT_LOG"
    fi
  fi
  if [[ -n "$LOG_FILE" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      echo "[dry-run] $msg" >> "$LOG_FILE"
    else
      echo "$msg" >> "$LOG_FILE"
    fi
  fi
  echo "$msg"
}
log_json() {
  local typ="${1:-}" detail="${2:-}" src="${3:-}" dest="${4:-}"
  local ts
  ts=$(date --iso-8601=seconds 2>/dev/null || python3 -c "from datetime import datetime, timezone; print(datetime.now(timezone.utc).isoformat())")
  # produce JSON object with fields: type, detail, src, dest, timestamp, dry_run
  local obj
  obj=$(printf '{"type":"%s","detail":"%s","src":"%s","dest":"%s","timestamp":"%s","dry_run":%s}' "$typ" "$detail" "${src:-}" "${dest:-}" "$ts" "$([[ $DRY_RUN -eq 1 ]] && echo true || echo false)")
  JSON_ENTRIES+=("$obj")
  # stream to file if requested
  if [[ -n "$EMIT_JSON" ]]; then
    echo "$obj" >> "$EMIT_JSON"
  fi
  if [[ -n "$LOG_FILE" ]]; then
    echo "$obj" >> "${LOG_FILE}.json"
  fi
}

interactive_fill() {
  echo "No arguments provided — entering interactive setup. Press Enter to accept a default shown in brackets."
  read -rp "Target workspace root (absolute path) [${TARGET}]: " t
  if [[ -n "$t" ]]; then
    TARGET="$t"
  fi
  # normalize
  if [[ -d "$TARGET" ]]; then
    TARGET="$(cd "$TARGET" && pwd)"
  else
    # create parent if necessary
    mkdir -p "$TARGET"
    TARGET="$(cd "$TARGET" && pwd)"
  fi

  read -rp "Seed a starter feature name (kebab-case) (leave empty to skip): " f
  if [[ -n "$f" ]]; then
    FEATURE="$f"
  fi

  read -rp "Subroot folder name (e.g. app) (leave empty to skip): " s
  if [[ -n "$s" ]]; then
    SUBROOT="$s"
  fi

  if prompt_yes_no "Auto-install recommended VS Code extensions?" N; then
    INSTALL_EXT=1
  else
    INSTALL_EXT=0
  fi

  if prompt_yes_no "Force overwrite existing files (dangerous)?" N; then
    FORCE=1
  else
    FORCE=0
  fi

  echo
  echo "Configuration summary:" 
  echo "  Target: $TARGET"
  echo "  Feature: ${FEATURE:-<none>}"
  echo "  Subroot: ${SUBROOT:-<none>}"
  echo "  Install extensions: $([[ $INSTALL_EXT -eq 1 ]] && echo yes || echo no)"
  echo "  Force overwrite: $([[ $FORCE -eq 1 ]] && echo yes || echo no)"
  echo
  if [[ $SKIP_CONFIRM -eq 1 ]]; then
    echo "Skip-confirm enabled; proceeding without final prompt."
  else
    if ! prompt_yes_no "Proceed with the above configuration?" Y; then
      echo "Aborted by user."; exit 1
    fi
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2;;
  --feature) FEATURE="$2"; shift 2;;
  --subroot) SUBROOT="$2"; shift 2;;
  --install-extensions) INSTALL_EXT=1; shift;;
  --interactive) INTERACTIVE=1; shift;;
  --yes|-y) SKIP_CONFIRM=1; shift;;
  --dry-run) DRY_RUN=1; shift;;
  --no-install) NO_INSTALL=1; shift;;
  --output-log) OUTPUT_LOG="$2"; shift 2;;
  --emit-json) EMIT_JSON="$2"; shift 2;;
  --log) LOG_FILE="$2"; shift 2;;
    --force) FORCE=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

# If the script was run with no arguments, or the user passed --interactive, run interactive prompt to collect settings
if [[ "$ORIGINAL_ARGC" -eq 0 || "$INTERACTIVE" -eq 1 ]]; then
  interactive_fill
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
SRC_GITHUB="$ROOT_DIR/.github"
SRC_VSCODE="$ROOT_DIR/.vscode"
SRC_SCRIPTS="$ROOT_DIR/scripts"

# Announce local tool version and check remote
if [[ -f "$ROOT_DIR/VERSION" ]]; then
  LOCAL_VERSION=$(cat "$ROOT_DIR/VERSION" | tr -d ' \n\r')
  log "Kiro tooling version: $LOCAL_VERSION"
  REMOTE_VERSION_URL="https://raw.githubusercontent.com/oliguo/vibe-coding-kiro-agent/refs/heads/main/VERSION"
  REMOTE_V=""
  if command -v curl >/dev/null 2>&1; then
    REMOTE_V=$(curl -fsSL "$REMOTE_VERSION_URL" 2>/dev/null || echo "")
  elif command -v wget >/dev/null 2>&1; then
    REMOTE_V=$(wget -qO- "$REMOTE_VERSION_URL" 2>/dev/null || echo "")
  fi
  REMOTE_V=$(echo "$REMOTE_V" | tr -d ' \n\r')
  if [[ -n "$REMOTE_V" ]]; then
    if [[ "$REMOTE_V" != "$LOCAL_VERSION" ]]; then
      log "Remote version available: $REMOTE_V (local: $LOCAL_VERSION). Run scripts/kiro-self-update.sh to upgrade (asks before overwrite)."
      log_json "version-check" "remote_newer" "$LOCAL_VERSION" "$REMOTE_V"
    else
      log "You have the latest version: $LOCAL_VERSION"
      log_json "version-check" "up-to-date" "$LOCAL_VERSION" "$REMOTE_V"
    fi
  else
    log "Could not fetch remote VERSION from $REMOTE_VERSION_URL"
  fi
fi

ensure_dir() {
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[dry-run] ensure_dir: $1"
  else
    mkdir -p "$1"
    log "ensure_dir: $1"
  fi
}

copy_smart() {
  local src="$1" dest="$2"
  if [[ -e "$dest" && $FORCE -eq 0 ]]; then
    log "Skip (exists): $dest"; return 0
  fi
  ensure_dir "$(dirname "$dest")"
  if [[ $DRY_RUN -eq 1 ]]; then
  log "[dry-run] would copy: $src -> $dest"
  log_json "copy" "copy" "$src" "$dest"
  else
  cp -R "$src" "$dest"
  log "Copied: $dest"
  log_json "copy" "copy" "$src" "$dest"
  fi
}

copy_tree() {
  local src_dir="$1" rel="$2" dest_rel="$3"
  if [[ -d "$src_dir/$rel" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
  log "[dry-run] would rsync: $src_dir/$rel/ -> $TARGET/$dest_rel/"
  log_json "rsync" "rsync" "$src_dir/$rel/" "$TARGET/$dest_rel/"
    else
  rsync -a $( [[ $FORCE -eq 1 ]] && echo "--delete" ) "$src_dir/$rel/" "$TARGET/$dest_rel/"
  log "Synced: $dest_rel/"
  log_json "rsync" "rsync" "$src_dir/$rel/" "$TARGET/$dest_rel/"
    fi
  fi
}

log "Bootstrapping Kiro spec into: $TARGET"

# If a subroot is requested, ensure it exists and record it in .kiro/kiro-config.json
if [[ -n "$SUBROOT" ]]; then
  log "Creating subroot: $SUBROOT"
  ensure_dir "$TARGET/$SUBROOT"
  ensure_dir "$TARGET/.kiro"
  if [[ $DRY_RUN -eq 1 ]]; then
  log "[dry-run] would write: $TARGET/.kiro/kiro-config.json (with subroot: $SUBROOT)"
  log_json "write-config" "write-config" "" "$TARGET/.kiro/kiro-config.json"
  else
    cat > "$TARGET/.kiro/kiro-config.json" <<JSON
{
  "subroot": "$SUBROOT"
}
JSON
  log "Wrote: $TARGET/.kiro/kiro-config.json"
  log_json "write-config" "write-config" "" "$TARGET/.kiro/kiro-config.json"
  fi
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
copy_smart "$SRC_SCRIPTS/kiro-task-update.sh" "$TARGET/scripts/kiro-task-update.sh" || true
copy_smart "$ROOT_DIR/VERSION" "$TARGET/VERSION" || true
copy_smart "$SRC_SCRIPTS/kiro-version.sh" "$TARGET/scripts/kiro-version.sh" || true
copy_smart "$SRC_SCRIPTS/kiro-bump-version.sh" "$TARGET/scripts/kiro-bump-version.sh" || true
copy_smart "$SRC_SCRIPTS/kiro-self-update.sh" "$TARGET/scripts/kiro-self-update.sh" || true
if [[ $DRY_RUN -eq 1 ]]; then
  log "[dry-run] would chmod +x $TARGET/scripts/kiro-spec-validate*.sh"
  log_json "chmod" "chmod" "" "$TARGET/scripts/kiro-spec-validate*.sh"
else
  chmod +x "$TARGET/scripts/kiro-spec-validate.sh" "$TARGET/scripts/kiro-spec-validate-latest.sh" "$TARGET/scripts/kiro-task-update.sh" "$TARGET/scripts/kiro-version.sh" "$TARGET/scripts/kiro-bump-version.sh" "$TARGET/scripts/kiro-self-update.sh" || true
  log "chmod +x $TARGET/scripts/kiro-spec-validate*.sh and kiro-task-update.sh and kiro-version.sh and bump/self-update"
  log_json "chmod" "chmod" "" "$TARGET/scripts/kiro-spec-validate*.sh,$TARGET/scripts/kiro-task-update.sh,$TARGET/scripts/kiro-version.sh,$TARGET/scripts/kiro-bump-version.sh,$TARGET/scripts/kiro-self-update.sh"
fi

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
if [[ $DRY_RUN -eq 1 ]]; then
  log "[dry-run] would update settings: $TARGET/.vscode/settings.json"
  log_json "update-settings" "update-settings" "" "$TARGET/.vscode/settings.json"
else
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
  log_json "update-settings" "$TARGET/.vscode/settings.json"
fi

# 4b) Optional: auto-install recommended extensions (requires `code` CLI)
if [[ $INSTALL_EXT -eq 1 && $NO_INSTALL -eq 0 ]]; then
  if command -v code >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      log "[dry-run] would install extensions: GitHub.copilot, GitHub.copilot-chat"
      log_json "install-extensions" "install-extensions" "" "GitHub.copilot,GitHub.copilot-chat"
    else
      log "Installing recommended VS Code extensions via code CLI"
      code --install-extension GitHub.copilot || true
      code --install-extension GitHub.copilot-chat || true
      log_json "install-extensions" "install-extensions" "" "GitHub.copilot,GitHub.copilot-chat"
    fi
  else
    log "VS Code 'code' CLI not found. Skipping auto-install of extensions."
    log "Tip: In VS Code, run 'Shell Command: Install 'code' command in PATH' from the Command Palette."
  fi
fi

# 5) (Removed) dev-only extension support

# 6) Optional: seed a starter spec from templates
if [[ -n "$FEATURE" ]]; then
  # Place seeded specs under the repository root `.kiro` so Kiro-aware IDEs
  # will detect them immediately. The optional project subroot (if present)
  # is still recorded in `.kiro/kiro-config.json` but specs themselves live
  # at top-level `.kiro/specs`.
  SPEC_DIR="$TARGET/.kiro/specs/$FEATURE"
  ensure_dir "$SPEC_DIR"
  for f in requirements design tasks; do
    src_tmpl="$SRC_GITHUB/templates/kiro-$f-template.md"
    dest="$SPEC_DIR/$f.md"
    if [[ -f "$src_tmpl" ]]; then
      if [[ -f "$dest" && $FORCE -eq 0 ]]; then
        log "Skip (exists): $dest"
      else
        if [[ $DRY_RUN -eq 1 ]]; then
          log "[dry-run] would seed: $dest (from $src_tmpl)"
          log_json "seed" "seed" "$src_tmpl" "$dest"
        else
          sed "s/\[feature_name\]/$FEATURE/g" "$src_tmpl" > "$dest"
          log "Seeded: $dest"
          log_json "seed" "seed" "$src_tmpl" "$dest"
        fi
      fi
    fi
  done
  # Seed implementation plan
  src_plan="$SRC_GITHUB/templates/implementation-plan-template.md"
  dest_plan="$SPEC_DIR/IMPLEMENTATION_PLAN.md"
  if [[ -f "$src_plan" ]]; then
    if [[ -f "$dest_plan" && $FORCE -eq 0 ]]; then
      log "Skip (exists): $dest_plan"
    else
        if [[ $DRY_RUN -eq 1 ]]; then
          log "[dry-run] would seed: $dest_plan (from $src_plan)"
          log_json "seed" "seed" "$src_plan" "$dest_plan"
        else
          sed "s/\[feature_name\]/$FEATURE/g" "$src_plan" > "$dest_plan"
          log "Seeded: $dest_plan"
          log_json "seed" "seed" "$src_plan" "$dest_plan"
        fi
    fi
  fi
  if [[ -f "$TARGET/scripts/kiro-spec-validate.sh" ]]; then
    bash "$TARGET/scripts/kiro-spec-validate.sh" "$FEATURE" all || true
  fi
fi

log "Done. Next steps:"
log "- Open $TARGET in VS Code. You'll be prompted to install recommended extensions (Copilot & Chat)."
log "- Tasks available: Run Task → Kiro: Validate Spec / Validate Latest Spec"
if [[ -n "$SUBROOT" ]]; then
  log "- Project program files should be generated under subroot: $SUBROOT when appropriate. Keep that folder as your project root in VS Code if desired."
  log "- Spec documents are stored at repository root: .kiro/specs (so editor integrations detect them immediately)."
fi
log "- Copilot Chat: 'Kiro-Spec-Agent' chat mode should be available automatically."
log "- Use the gated prompts to create requirements/design/tasks files (or edit the seeded ones)."

# If requested, write machine-readable JSON file with the accumulated actions
if [[ -n "$EMIT_JSON" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[dry-run] would emit JSON to $EMIT_JSON"
  else
    log "Emitting JSON to $EMIT_JSON"
  fi
  # assemble JSON array
  printf "%s\n" "[${JSON_ENTRIES[*]}]" | sed 's/}{/},{/g' > "$EMIT_JSON"
fi

if [[ -n "$OUTPUT_LOG" ]]; then
  log "Wrote actions log: $OUTPUT_LOG"
fi
