#!/usr/bin/env python3
"""kiro-merge.py

Lightweight smart-merge helper used by kiro-spec-bootstrap.sh.

Behavior:
- If dest does not exist: copy src -> dest
- If dest exists: create a timestamped backup dest.bak.<ts>
- If both files are text, append only lines from src that are not already present in dest (preserve order).
- If binary or non-text, skip merge and report action.

This is intentionally conservative: it avoids destructive overwrites and keeps backups.
"""
import sys
import shutil
import os
from datetime import datetime
import subprocess
import tempfile


def is_text_file(path):
    try:
        with open(path, 'rb') as f:
            sample = f.read(4096)
        # attempt decode
        sample.decode('utf-8')
        return True
    except Exception:
        return False


def timestamp():
    return datetime.now().strftime('%Y%m%dT%H%M%S')


def main():
    args = sys.argv[1:]
    if not (2 <= len(args) <= 3):
        print('Usage: kiro-merge.py src dest [--dry-run]', file=sys.stderr)
        return 2
    src = args[0]
    dest = args[1]
    dry = False
    if len(args) == 3 and args[2] == '--dry-run':
        dry = True

    if not os.path.exists(src):
        print(f'ERROR: src not found: {src}', file=sys.stderr)
        return 3

    if not os.path.exists(dest):
        if dry:
            print(f'[dry-run] would copy: {src} -> {dest}')
            return 0
        os.makedirs(os.path.dirname(dest) or '.', exist_ok=True)
        shutil.copy2(src, dest)
        print(f'Copied: {dest}')
        return 0

    # dest exists -> backup
    bkup = dest + '.bak.' + timestamp()
    if dry:
        print(f'[dry-run] would backup: {dest} -> {bkup}')
    else:
        shutil.copy2(dest, bkup)
        print(f'Backed up: {dest} -> {bkup}')

    # decide merge behavior
    # First, prefer a git-based 3-way merge when possible (destination inside a git repo and git available).
    try:
        dest_dir = os.path.dirname(dest) or '.'
        # find git root for dest
        git_root = None
        try:
            proc = subprocess.run(['git', '-C', dest_dir, 'rev-parse', '--show-toplevel'], check=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
            git_root = proc.stdout.strip()
        except Exception:
            git_root = None

        if git_root and shutil.which('git'):
            relpath = os.path.relpath(dest, git_root)
            # Check whether file is tracked in git
            try:
                subprocess.run(['git', '-C', git_root, 'ls-files', '--error-unmatch', relpath], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                tracked = True
            except Exception:
                tracked = False

            if tracked:
                # Perform an actual 3-way merge using HEAD as the base (git merge-file)
                if dry:
                    print(f'[dry-run] would perform git 3-way merge (HEAD base) for {relpath} in repo {git_root}')
                    return 0
                tmp = tempfile.mkdtemp(prefix='kiro_merge_')
                try:
                    base_path = os.path.join(tmp, 'base')
                    current_path = os.path.join(tmp, 'current')
                    other_path = os.path.join(tmp, 'other')
                    # write base from HEAD
                    try:
                        base_blob = subprocess.run(['git', '-C', git_root, 'show', f'HEAD:{relpath}'], check=True, stdout=subprocess.PIPE)
                        with open(base_path, 'wb') as bf:
                            bf.write(base_blob.stdout)
                    except Exception as e:
                        print(f'Could not read base from HEAD for {relpath}: {e}; falling back')
                        raise

                    # copy current dest and other (src)
                    shutil.copy2(dest, current_path)
                    shutil.copy2(src, other_path)

                    # run git merge-file: modifies current_path in place
                    merge_proc = subprocess.run(['git', 'merge-file', current_path, base_path, other_path], cwd=tmp, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    # move merged result back to dest (overwriting)
                    shutil.copy2(current_path, dest)
                    if merge_proc.returncode == 0:
                        print(f'Applied git 3-way merge for: {dest}')
                    else:
                        print(f'Applied git 3-way merge with conflicts for: {dest} (conflict markers may be present)')
                        if merge_proc.stdout:
                            print(merge_proc.stdout)
                        if merge_proc.stderr:
                            print(merge_proc.stderr)
                    return 0
                except Exception:
                    # fallthrough to fallback unique-append
                    pass
                finally:
                    try:
                        shutil.rmtree(tmp)
                    except Exception:
                        pass

    except Exception as e:
        # any unexpected error in git-merge attempt -> fallback to simple merge
        print(f'Git-based merge attempt raised: {e}; falling back to unique-line append')

    # Fallback: if both are text, append only unique lines as a conservative merge strategy
    if is_text_file(src) and is_text_file(dest):
        if dry:
            print(f'[dry-run] would smart-merge (unique lines) {src} -> {dest}')
            return 0
        # read dest lines into a set for quick membership
        with open(dest, 'r', encoding='utf-8', errors='ignore') as f:
            dest_lines = f.read().splitlines()
        dest_set = set(dest_lines)
        to_append = []
        with open(src, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                ln = line.rstrip('\n')
                if ln not in dest_set:
                    to_append.append(line)
        if not to_append:
            print(f'No new unique lines to append: {src} -> {dest}')
            return 0
        with open(dest, 'a', encoding='utf-8', errors='ignore') as f:
            f.write('\n\n# --- MERGE APPEND (unique lines) from: {} ---\n'.format(src))
            for line in to_append:
                f.write(line)
        print(f'Merged (unique-append): {src} -> {dest} (appended {len(to_append)} lines)')
        return 0
    else:
        print(f'Skipped merge (binary or non-text): {dest}')
        return 0


if __name__ == '__main__':
    raise SystemExit(main())
