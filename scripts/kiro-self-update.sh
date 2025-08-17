#!/usr/bin/env bash
#set -euo pipefail
# A lightweight self-update helper that fetches the remote VERSION and offers to pull the latest changes.
# It asks for confirmation before overwriting local files.

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
REMOTE_VERSION_URL="https://raw.githubusercontent.com/oliguo/vibe-coding-kiro-agent/refs/heads/main/VERSION"

current() { cat "$ROOT_DIR/VERSION" 2>/dev/null || echo "unknown"; }
remote() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REMOTE_VERSION_URL" || echo ""
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$REMOTE_VERSION_URL" || echo ""
  else
    echo ""
  fi
}

confirm() {
  read -rp "$1 [y/N]: " ans
  case "$ans" in
    [Yy]*) return 0;;
    *) return 1;;
  esac
}

CURR=$(current)
REMOTE_V=$(remote | tr -d ' \n\r')
if [[ -z "$REMOTE_V" ]]; then
  echo "Could not fetch remote VERSION from $REMOTE_VERSION_URL"
  exit 2
fi

if [[ "$CURR" == "$REMOTE_V" ]]; then
  echo "You already have the latest version: $CURR"
  exit 0
fi

echo "Local version: $CURR"
echo "Remote version: $REMOTE_V"
if confirm "Pull latest changes from remote and overwrite local files?"; then
  if [[ -d "$ROOT_DIR/.git" ]]; then
    echo "Fetching latest from origin/main..."
    (cd "$ROOT_DIR" && git fetch origin main && git merge --ff-only origin/main) || {
      echo "Automatic merge failed. Please run 'git pull' manually or resolve conflicts."; exit 3
    }
    echo "Updated to $REMOTE_V"
  else
    echo "No git repo found in $ROOT_DIR. As an alternative, this script will download the remote archive and overwrite files."
    if confirm "Overwrite local files with remote tarball (destructive)?"; then
      TMPDIR=$(mktemp -d)
      trap 'rm -rf "$TMPDIR"' EXIT
  echo "Downloading archive..."
  curl -fsSL "https://github.com/oliguo/vibe-coding-kiro-agent/archive/refs/heads/main.tar.gz" -o "$TMPDIR/main.tar.gz"
      mkdir -p "$TMPDIR/extract"
      tar -xzf "$TMPDIR/main.tar.gz" -C "$TMPDIR/extract"
      rootdir=$(find "$TMPDIR/extract" -maxdepth 1 -type d -name "vibe-coding-kiro-agent-*" | head -n1)
      if [[ -z "$rootdir" ]]; then
        echo "Failed to locate extracted archive"; exit 4
      fi
  # Preserve any local .kiro spec/config folder: do not overwrite user specs or config
  echo "Preserving local .kiro directory if present; it will NOT be overwritten by the remote archive."
  # Use rsync exclude to protect .kiro; exclude both the directory and its contents
  rsync -a --delete --exclude='.kiro/' --exclude='.kiro/**' "$rootdir/" "$ROOT_DIR/"
  echo "Overwritten local files with remote archive (local .kiro preserved). Updated to $REMOTE_V"
    else
      echo "Aborted by user. No changes made."
      exit 0
    fi
  fi
else
  echo "Update cancelled."
fi
