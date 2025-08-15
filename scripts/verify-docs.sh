#!/usr/bin/env bash
# Simple smoke-test for docs and editor helpers
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "Workspace root: $ROOT_DIR"

missing=0
check_file(){
  local f="$1"
  if [[ -f "$f" ]]; then
    echo "OK: $f"
  else
    echo "MISSING: $f" >&2
    missing=$((missing+1))
  fi
}

echo "Checking docs and scripts..."
check_file "$ROOT_DIR/docs/scripts.md"
check_file "$ROOT_DIR/README.md"
check_file "$ROOT_DIR/scripts/kiro-spec-bootstrap.sh"
check_file "$ROOT_DIR/scripts/kiro-spec-validate.sh"
check_file "$ROOT_DIR/scripts/kiro-task-update.sh"
check_file "$ROOT_DIR/scripts/kiro-version.sh"
check_file "$ROOT_DIR/.vscode/kiro-commands.code-snippets"
check_file "$ROOT_DIR/.vscode/tasks.json"

echo "Validating JSON files (.vscode)..."
python3 -m json.tool "$ROOT_DIR/.vscode/kiro-commands.code-snippets" >/dev/null && echo "OK: snippets JSON" || { echo "INVALID: snippets JSON" >&2; missing=$((missing+1)); }
python3 -m json.tool "$ROOT_DIR/.vscode/tasks.json" >/dev/null && echo "OK: tasks.json" || { echo "INVALID: tasks.json" >&2; missing=$((missing+1)); }

if [[ $missing -eq 0 ]]; then
  echo "VERIFY: PASS"
  exit 0
else
  echo "VERIFY: FAIL ($missing problems)" >&2
  exit 2
fi
