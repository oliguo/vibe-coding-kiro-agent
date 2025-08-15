#!/usr/bin/env bash
set -euo pipefail

usage(){
  cat <<'USAGE'
Usage: kiro-bump-version.sh [--set MAJOR.MINOR.PATCH] [--patch]

Options:
  --set VERSION   Set the VERSION file to the explicit value
  --patch         Increment patch version (x.y.PATCH -> x.y.(PATCH+1))
  --help          Show this help
USAGE
}

if [[ ${#@} -eq 0 ]]; then
  usage; exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
VF="$ROOT_DIR/VERSION"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --set) NEWV="$2"; shift 2;;
    --patch) PATCH=1; shift;;
    --help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

if [[ ! -f "$VF" ]]; then
  echo "0.0.0" > "$VF"
fi

CURR=$(cat "$VF" | tr -d ' \n\r')
if [[ -n "${NEWV:-}" ]]; then
  echo "$NEWV" > "$VF"
  echo "Updated VERSION: $CURR -> $NEWV"
  exit 0
fi

if [[ ${PATCH:-0} -eq 1 ]]; then
  IFS='.' read -r MAJ MIN PAT <<< "$CURR"
  PAT=${PAT:-0}
  NEW=$MAJ.$MIN.$((PAT+1))
  echo "$NEW" > "$VF"
  echo "Bumped VERSION: $CURR -> $NEW"
  exit 0
fi

usage
