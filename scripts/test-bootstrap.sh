#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
TMPDIR="$(mktemp -d)"
FEATURE="test-feature"
SUBROOT="app"

echo "Testing bootstrap into: $TMPDIR"

bash "$ROOT_DIR/scripts/kiro-spec-bootstrap.sh" --target "$TMPDIR" --feature "$FEATURE" --subroot "$SUBROOT" --force

# Check config
if [[ ! -f "$TMPDIR/.kiro/kiro-config.json" ]]; then
  echo "FAILED: .kiro/kiro-config.json missing" >&2; exit 2
fi

if ! grep -q "\"subroot\": \"$SUBROOT\"" "$TMPDIR/.kiro/kiro-config.json"; then
  echo "FAILED: subroot not set correctly in config" >&2; exit 2
fi

# Check subroot dir exists
if [[ ! -d "$TMPDIR/$SUBROOT" ]]; then
  echo "FAILED: subroot directory $TMPDIR/$SUBROOT not created" >&2; exit 2
fi

# Check seeded spec files path depending on subroot
SPEC_DIR="$TMPDIR/.kiro/specs/$FEATURE"
if [[ -d "$TMPDIR/$SUBROOT/.kiro/specs/$FEATURE" ]]; then
  SPEC_DIR="$TMPDIR/$SUBROOT/.kiro/specs/$FEATURE"
fi

if [[ ! -d "$SPEC_DIR" ]]; then
  echo "FAILED: spec dir missing at $SPEC_DIR" >&2; exit 2
fi

for f in requirements.md design.md tasks.md IMPLEMENTATION_PLAN.md; do
  if [[ ! -f "$SPEC_DIR/$(basename "$f")" ]]; then
    echo "FAILED: expected seeded file $f missing in $SPEC_DIR" >&2; exit 2
  fi
done

# Run validator
bash "$TMPDIR/scripts/kiro-spec-validate.sh" "$FEATURE" all || true

# Success
echo "Bootstrap test completed successfully: $TMPDIR"

# Keep the tmp dir printed so user can inspect manually
echo "$TMPDIR"
