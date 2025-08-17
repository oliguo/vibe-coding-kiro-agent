#!/usr/bin/env python3
"""
Simple helper to mark a task in .kiro/specs/<feature>/tasks.md as started or completed.

Usage:
  scripts/kiro-task-update.sh --feature <name> --task <n> --start --by @me
  scripts/kiro-task-update.sh --feature <name> --task <n> --complete --by @me

Notes:
- Prefers specs location at repo-root `.kiro/specs/<feature>` but will use `$ROOT/<subroot>/.kiro/specs/<feature>` if present and configured.
- Updates the task marker ([ ] -> [-] or [x]) and inserts/updates metadata keys: started_by, started_at, completed_by, completed_at.
"""
import argparse
import json
import os
import re
import sys
from datetime import datetime


def iso_now():
    # Use local device timezone so timestamps match the user's VS Code/device settings.
    # datetime.now().astimezone() returns an aware datetime with local tzinfo and offset.
    return datetime.now().astimezone().isoformat()


def find_spec_dir(root, feature):
    # default repo-root .kiro/specs
    repo_spec = os.path.join(root, '.kiro', 'specs', feature)
    config = os.path.join(root, '.kiro', 'kiro-config.json')
    if os.path.isfile(config):
        try:
            subroot = json.load(open(config)).get('subroot','')
        except Exception:
            subroot = ''
        if subroot:
            sub_spec = os.path.join(root, subroot, '.kiro', 'specs', feature)
            if os.path.isdir(sub_spec):
                return sub_spec
    return repo_spec


def read_lines(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read().splitlines()


def write_lines(path, lines):
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')


def update_task(lines, task_num, action, by, at):
    # task header regex: optional indent, number, dot, space, marker [ ]/[x]/[-], rest
    header_re = re.compile(r'^(?P<indent>\s*)(?P<num>\d+)\.\s*\[(?P<mark>.| )\]\s*(?P<title>.*)$')
    out = []
    i = 0
    n = len(lines)
    found = False
    while i < n:
        line = lines[i]
        m = header_re.match(line)
        if m and int(m.group('num')) == task_num and not found:
            found = True
            indent = m.group('indent')
            title = m.group('title')
            # determine new marker
            new_mark = '-' if action == 'start' else 'x'
            out.append(f"{indent}{task_num}. [{new_mark}] {title}")
            # consume any following metadata lines (indented list items starting with '-')
            j = i + 1
            meta = {}
            meta_lines = []
            while j < n:
                nxt = lines[j]
                if nxt.strip().startswith('-') and (nxt.startswith(indent + '   ') or nxt.startswith(indent + '  ')):
                    # parse key: value
                    kv = nxt.strip().lstrip('-').strip()
                    if ':' in kv:
                        k, v = kv.split(':', 1)
                        meta[k.strip()] = v.strip()
                    else:
                        meta_lines.append(nxt)
                    j += 1
                else:
                    break
            # update metadata keys
            if action == 'start':
                meta['started_by'] = by
                meta['started_at'] = at
                # remove completed_* if present
                meta.pop('completed_by', None)
                meta.pop('completed_at', None)
            else:
                meta['completed_by'] = by
                meta['completed_at'] = at
            # write metadata back
            # keep an ordering that prefers owner, estimate, branch, started_by/at, completed_by/at, tests, notes
            order = ['owner','estimate','branch','started_by','started_at','completed_by','completed_at','tests','notes']
            for k in order:
                if k in meta:
                    out.append(f"{indent}   - {k}: {meta[k]}")
            # include any other meta keys
            for k in meta:
                if k not in order:
                    out.append(f"{indent}   - {k}: {meta[k]}")
            # continue from j
            i = j
            continue
        else:
            out.append(line)
            i += 1
    return found, out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--feature', '-f', required=True)
    parser.add_argument('--task', '-t', required=True, type=int)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--start', action='store_true')
    group.add_argument('--complete', action='store_true')
    parser.add_argument('--by', required=True, help='Actor (e.g. @me)')
    parser.add_argument('--at', help='ISO8601 timestamp (defaults to now UTC)')
    args = parser.parse_args()

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    spec_dir = find_spec_dir(root, args.feature)
    # Print local tool version and attempt to fetch remote VERSION for visibility
    try:
        local_version = open(os.path.join(root, '..', 'VERSION')).read().strip()
    except Exception:
        local_version = None
    if local_version:
        print(f"Kiro tooling version: {local_version}")
        try:
            import urllib.request
            url = 'https://raw.githubusercontent.com/oliguo/vibe-coding-kiro-agent/refs/heads/main/VERSION'
            with urllib.request.urlopen(url, timeout=3) as r:
                remote_v = r.read().decode('utf-8').strip()
            if remote_v and remote_v != local_version:
                print(f"Remote version available: {remote_v} (local: {local_version}). Run scripts/kiro-self-update.sh to upgrade (asks before overwrite).")
        except Exception:
            pass
    tasks_path = os.path.join(spec_dir, 'tasks.md')
    if not os.path.isdir(spec_dir):
        print(f"Spec directory not found: {spec_dir}", file=sys.stderr)
        sys.exit(2)
    if not os.path.isfile(tasks_path):
        print(f"tasks.md not found at: {tasks_path}", file=sys.stderr)
        sys.exit(3)

    lines = read_lines(tasks_path)
    action = 'start' if args.start else 'complete'
    at = args.at or iso_now()
    found, out = update_task(lines, args.task, action, args.by, at)
    if not found:
        print(f"Task #{args.task} not found in {tasks_path}", file=sys.stderr)
        sys.exit(4)
    # backup
    try:
        import shutil
        shutil.copy2(tasks_path, tasks_path + '.bak')
    except Exception:
        pass
    write_lines(tasks_path, out)
    print(f"Updated task #{args.task} ({action}) in {tasks_path}")


if __name__ == '__main__':
    main()
