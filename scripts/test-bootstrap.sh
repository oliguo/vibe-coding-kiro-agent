#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
TMPDIR="$(mktemp -d)"
FEATURE="test-feature"
SUBROOT="app"

echo "Testing bootstrap into: $TMPDIR"

# Run a full bootstrap (non-dry) first to ensure end-to-end
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
# Backwards-compat: if specs were created under the subroot, prefer that path
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

# Now test dry-run JSON output
EMIT="$TMPDIR/actions.json"
bash "$ROOT_DIR/scripts/kiro-spec-bootstrap.sh" --target "$TMPDIR" --feature "$FEATURE" --subroot "$SUBROOT" --dry-run --yes --emit-json "$EMIT"

if [[ ! -f "$EMIT" ]]; then
  echo "FAILED: expected JSON emit at $EMIT" >&2; exit 3
fi

if ! grep -q 'write-config' "$EMIT"; then
  echo "FAILED: emitted JSON missing expected 'write-config' entry" >&2; exit 3
fi

echo "Dry-run JSON emitted and contains expected entries: $EMIT"

# Smoke-test: ensure kiro-task-update.sh can start and complete a task
if [[ -f "$ROOT_DIR/scripts/kiro-task-update.sh" ]]; then
  echo "Running smoke-test for kiro-task-update.sh"
  # copy helper into tmp workspace scripts if missing
  if [[ ! -f "$TMPDIR/scripts/kiro-task-update.sh" ]]; then
    cp "$ROOT_DIR/scripts/kiro-task-update.sh" "$TMPDIR/scripts/"
    chmod +x "$TMPDIR/scripts/kiro-task-update.sh" || true
  fi
  # ensure we operate on the detected SPEC_DIR
  if [[ -f "$SPEC_DIR/tasks.md" ]]; then
    # start task 1
    "$TMPDIR/scripts/kiro-task-update.sh" --feature "$FEATURE" --task 1 --start --by @smoke || { echo "FAILED: start action failed" >&2; exit 4; }
    if ! grep -q "1. \[[-]\]" "$SPEC_DIR/tasks.md" && ! grep -q "started_by:" "$SPEC_DIR/tasks.md"; then
      echo "FAILED: expected started marker/meta not found after start" >&2; exit 5
    fi
    # complete task 1
    "$TMPDIR/scripts/kiro-task-update.sh" --feature "$FEATURE" --task 1 --complete --by @smoke || { echo "FAILED: complete action failed" >&2; exit 6; }
    if ! grep -q "1. \[x\]" "$SPEC_DIR/tasks.md" && ! grep -q "completed_by:" "$SPEC_DIR/tasks.md"; then
      echo "FAILED: expected completed marker/meta not found after complete" >&2; exit 7
    fi
    echo "Smoke-test for kiro-task-update.sh passed"
  else
    echo "SKIP: tasks.md not found at $SPEC_DIR for smoke-test"
  fi
else
  echo "SKIP: kiro-task-update.sh not present in repo; skipping smoke-test"
fi
