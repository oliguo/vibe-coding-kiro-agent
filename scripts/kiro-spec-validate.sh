#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <feature_name> [phase]" >&2
  echo "  phase: requirements|design|tasks|all (default: all)" >&2
}

if [[ ${1:-} == "" ]]; then
  usage; exit 2
fi
FEATURE="$1"
PHASE="${2:-all}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
SPEC_DIR="$ROOT_DIR/.kiro/specs/$FEATURE"

failures=()
passes=()

check_requirements() {
  local f="$SPEC_DIR/requirements.md"
  if [[ ! -f "$f" ]]; then failures+=("requirements: missing file"); return; fi
  local score=0; local total=5
  grep -Eqi '^##[[:space:]]+1\.?[[:space:]]+Introduction' "$f" && ((score++)) || true
  grep -Eqi '^##[[:space:]]+2\.?[[:space:]]+Functional Requirements' "$f" && ((score++)) || true
  grep -Eqi 'As a .* I want .* so that' "$f" && ((score++)) || true
  grep -Eqi '\b(WHEN|IF)\b.*\bTHEN\b.*\bSHALL\b' "$f" && ((score++)) || true
  grep -Eqi '(^##[[:space:]]+3\.?[[:space:]]+Non-Functional Requirements)|(^##[[:space:]]+4\.?[[:space:]]+Edge Cases)' "$f" && ((score++)) || true
  if (( score >= 4 )); then passes+=("requirements: PASS ($score/$total checks)"); else failures+=("requirements: weak content ($score/$total)"); fi
}

check_design() {
  local f="$SPEC_DIR/design.md"
  if [[ ! -f "$f" ]]; then failures+=("design: missing file"); return; fi
  local score=0; local total=6
  grep -Eqi '^##[[:space:]]+Overview' "$f" && ((score++)) || true
  grep -Eqi '^##[[:space:]]+Architecture' "$f" && ((score++)) || true
  grep -Eqi '^##[[:space:]]+Components' "$f" && ((score++)) || true
  grep -Eqi '^##[[:space:]]+Data Models' "$f" && ((score++)) || true
  grep -Eqi '^##[[:space:]]+Error Handling' "$f" && ((score++)) || true
  grep -Eqi '^##[[:space:]]+Testing Strategy' "$f" && ((score++)) || true
  if (( score >= 5 )); then passes+=("design: PASS ($score/$total checks)"); else failures+=("design: weak content ($score/$total)"); fi
}

check_tasks() {
  local f="$SPEC_DIR/tasks.md"
  if [[ ! -f "$f" ]]; then failures+=("tasks: missing file"); return; fi
  local score=0; local total=4
  grep -Eqi '^\s*[0-9]+\.' "$f" && ((score++)) || true
  grep -Eqi '\brefs?:\s*([0-9]+(\.[0-9]+)*)' "$f" && ((score++)) || true
  grep -Eqi 'Tests?:' "$f" && ((score++)) || true
  grep -Eqi '\b(coding|implement|create|modify|write)\b' "$f" && ((score++)) || true
  if (( score >= 3 )); then passes+=("tasks: PASS ($score/$total checks)"); else failures+=("tasks: weak content ($score/$total)"); fi
}

case "$PHASE" in
  requirements) check_requirements ;;
  design) check_design ;;
  tasks) check_tasks ;;
  all) check_requirements; check_design; check_tasks ;;
  *) usage; exit 2 ;;
 esac

if (( ${#failures[@]} == 0 )); then
  # Use safe parameter expansion to avoid unbound variable errors under 'set -u'
  echo "Quality Gates: content validation PASS — ${passes[*]:-}"; exit 0
else
  echo "Quality Gates: content validation FAIL — ${failures[*]:-} | ${passes[*]:-}"; exit 1
fi
