#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "unknown"
  exit 1
fi

cat "$VERSION_FILE"
