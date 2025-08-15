#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
PHASE="${1:-all}"

# Determine specs directory, prefer subroot if configured
CONFIG_JSON="$ROOT_DIR/.kiro/kiro-config.json"
SPECS_DIR="$ROOT_DIR/.kiro/specs"
if [[ -f "$CONFIG_JSON" ]]; then
  SUBROOT="$(python3 -c "import json
try:
  print(json.load(open('$CONFIG_JSON')).get('subroot',''))
except Exception:
  print('')
")"
  if [[ -n "$SUBROOT" && -d "$ROOT_DIR/$SUBROOT/.kiro/specs" ]]; then
    SPECS_DIR="$ROOT_DIR/$SUBROOT/.kiro/specs"
  fi
fi

if [[ ! -d "$SPECS_DIR" ]]; then
  echo "No specs directory found at $SPECS_DIR" >&2
  exit 1
fi

FEATURE="$(ls -1t "$SPECS_DIR" | head -1 || true)"
if [[ -z "$FEATURE" ]]; then
  echo "No spec features found in $SPECS_DIR" >&2
  exit 1
fi

echo "Validating latest spec: $FEATURE (phase: $PHASE) in $SPECS_DIR"
"$ROOT_DIR/scripts/kiro-spec-validate.sh" "$FEATURE" "$PHASE"
