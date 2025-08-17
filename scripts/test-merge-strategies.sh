#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
TMPDIR="$(mktemp -d)"
echo "Creating test workspace at: $TMPDIR"

# Prepare an existing workspace with some files that conflict with the repo templates
mkdir -p "$TMPDIR/.github/instructions"
mkdir -p "$TMPDIR/scripts"
mkdir -p "$TMPDIR/.vscode"
mkdir -p "$TMPDIR/.kiro/specs/sample"

echo "EXISTING CONTENT" > "$TMPDIR/.github/instructions/EXISTING.md"
echo "old-settings: true" > "$TMPDIR/.vscode/settings.json"
echo "echo old" > "$TMPDIR/scripts/kiro-spec-validate.sh"
echo "OLD REQUIREMENTS" > "$TMPDIR/.kiro/specs/sample/requirements.md"

echo "-- Test: skip strategy (dry-run) --"
bash "$ROOT_DIR/scripts/kiro-spec-bootstrap.sh" --target "$TMPDIR" --feature sample --merge-strategy skip --dry-run --emit-json "$TMPDIR/skip_actions.json" || true
echo "skip actions logged: $TMPDIR/skip_actions.json"

echo "-- Test: merge strategy (dry-run) --"
bash "$ROOT_DIR/scripts/kiro-spec-bootstrap.sh" --target "$TMPDIR" --feature sample --merge-strategy merge --dry-run --emit-json "$TMPDIR/merge_actions.json" || true
echo "merge actions logged: $TMPDIR/merge_actions.json"

echo "-- Test: override strategy (dry-run) --"
bash "$ROOT_DIR/scripts/kiro-spec-bootstrap.sh" --target "$TMPDIR" --feature sample --merge-strategy override --dry-run --emit-json "$TMPDIR/override_actions.json" || true
echo "override actions logged: $TMPDIR/override_actions.json"

echo "-- Now run real merge to see modifications for merge strategy --"
bash "$ROOT_DIR/scripts/kiro-spec-bootstrap.sh" --target "$TMPDIR" --feature sample --merge-strategy merge --emit-json "$TMPDIR/merge_real_actions.json" || true
echo "merge real actions logged: $TMPDIR/merge_real_actions.json"

echo "Contents of requirements.md after real merge (head):"
sed -n '1,120p' "$TMPDIR/.kiro/specs/sample/requirements.md" || true

echo "Logs summary (merge real):"
grep -a 'merge\|override\|skip\|copy' "$TMPDIR/merge_real_actions.json" || true

echo "Test workspace retained at: $TMPDIR"

exit 0
