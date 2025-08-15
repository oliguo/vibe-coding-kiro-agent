#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
SPECS_DIR="$ROOT_DIR/.kiro/specs"
PHASE="${1:-all}"

if [[ ! -d "$SPECS_DIR" ]]; then
  echo "No specs directory found at $SPECS_DIR" >&2
  exit 1
fi

FEATURE="$(ls -1t "$SPECS_DIR" | head -1 || true)"
if [[ -z "${FEATURE:-}" ]]; then
  echo "No spec features found in $SPECS_DIR" >&2
  exit 1
fi

"$ROOT_DIR/scripts/kiro-spec-validate.sh" "$FEATURE" "$PHASE"
