#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path
import sys

failed = False
for path in Path(".").rglob("*.md"):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    for idx, line in enumerate(lines, start=1):
        if "\t" in line:
            print(f"Tabs are not allowed: {path}:{idx}")
            failed = True
        if line.rstrip(" ") != line:
            print(f"Trailing whitespace found: {path}:{idx}")
            failed = True

if failed:
    print("Markdown lint failed.")
    sys.exit(1)

print("Markdown lint passed.")
PY
