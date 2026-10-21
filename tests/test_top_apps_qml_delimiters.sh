#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/TopApps.qml" "$ROOT/components/Volumes.qml" <<'PYCODE'
from pathlib import Path
import sys

pairs = {')': '(', ']': '[', '}': '{'}
for name in sys.argv[1:]:
    path = Path(name)
    source = path.read_text(encoding="utf-8")
    stack = []
    state = "code"
    i = 0
    line = 1
    while i < len(source):
        c = source[i]
        n = source[i + 1] if i + 1 < len(source) else ""
        if c == "\n":
            line += 1
            if state == "line_comment":
                state = "code"
            i += 1
            continue
        if state == "line_comment":
            i += 1
            continue
        if state == "block_comment":
            if c == "*" and n == "/":
                state = "code"
                i += 2
            else:
                i += 1
            continue
        if state in ("single", "double", "template"):
            quote = {"single": "'", "double": '"', "template": '`'}[state]
            if c == "\\":
                i += 2
                continue
            if c == quote:
                state = "code"
            i += 1
            continue
        if c == "/" and n == "/":
            state = "line_comment"
            i += 2
            continue
        if c == "/" and n == "*":
            state = "block_comment"
            i += 2
            continue
        if c == "'":
            state = "single"
        elif c == '"':
            state = "double"
        elif c == '`':
            state = "template"
        elif c in "([{":
            stack.append((c, line))
        elif c in ")]}":
            if not stack or stack[-1][0] != pairs[c]:
                raise SystemExit(f"{path.name}: delimiter mismatch at line {line}: unexpected {c}")
            stack.pop()
        i += 1
    if state in ("single", "double", "template", "block_comment"):
        raise SystemExit(f"{path.name}: unterminated {state}")
    if stack:
        c, start_line = stack[-1]
        raise SystemExit(f"{path.name}: {c} opened at line {start_line} is not closed")
    print(f"{path.name} delimiters: OK")
PYCODE
