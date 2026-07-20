#!/usr/bin/env python3
"""
Diagnostic helper for diagnose-architect.yml.

Searches the downloaded .claude.json for any 'remoteEnabled' key at
any depth, and prints the full parent object it belongs to. This was
extracted from inline YAML because embedding multi-line Python inside
a bash double-quoted string (python3 -c "...") in a GitHub Actions
run: block is fragile — bash and YAML both interpret quotes and
special characters that can silently break the script. A standalone
.py file avoids all of that.

Usage: python3 find_remote_enabled.py /path/to/claude.json
"""
import json
import sys


def find_remote_enabled(obj, path=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            newpath = f"{path}.{k}" if path else k
            if k == "remoteEnabled":
                print(f"{newpath} = {v}")
                print(f"  Parent object: {json.dumps(obj, indent=2)}")
            find_remote_enabled(v, newpath)
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            find_remote_enabled(item, f"{path}[{i}]")


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 find_remote_enabled.py <path-to-claude.json>", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    try:
        with open(path) as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"  ⚠️  File not found: {path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"  ⚠️  Could not parse JSON: {e}", file=sys.stderr)
        sys.exit(1)

    find_remote_enabled(data)


if __name__ == "__main__":
    main()
