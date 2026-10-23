#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/settings/sections/SettingsCalendarSection.qml" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text(encoding="utf-8")

def matching_brace(text, opening):
    depth = 0
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    i = opening
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if line_comment:
            if ch == "\n": line_comment = False
            i += 1; continue
        if block_comment:
            if ch == "*" and nxt == "/": block_comment = False; i += 2
            else: i += 1
            continue
        if quote:
            if escaped: escaped = False
            elif ch == "\\": escaped = True
            elif ch == quote: quote = None
            i += 1; continue
        if ch == "/" and nxt == "/": line_comment = True; i += 2; continue
        if ch == "/" and nxt == "*": block_comment = True; i += 2; continue
        if ch in ('"', "'"): quote = ch
        elif ch == "{": depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0: return i
        i += 1
    raise AssertionError("unclosed QML block")

def groups(text):
    result = []
    pos = 0
    while True:
        start = text.find("SettingsGroup {", pos)
        if start < 0: break
        opening = text.find("{", start)
        end = matching_brace(text, opening)
        result.append(text[start:end + 1])
        pos = end + 1
    return result

expected = {
    "Стрелки навигации": "host.currentOtherSubTab === 0",
    "Выходные и отмеченные дни": "host.currentOtherSubTab === 1",
    "Прошедшие дни": "host.currentOtherSubTab === 1",
    "Анимация": "host.currentOtherSubTab === 3",
}
all_groups = groups(source)
for heading, guard in expected.items():
    key = f'heading: "{heading}"'
    matches = [group for group in all_groups if key in group]
    assert len(matches) == 1, f"Expected one explicit Calendar frame heading {heading!r}; got {len(matches)}"
    group = matches[0]
    assert "showFrame: true" in group, f"{heading!r} must be attached to a framed group"
    assert guard in group and "visible:" in group, f"{heading!r} must retain the existing tab visibility condition"
    assert f'text: "{heading}"' not in group, f"Duplicate old title remains inside the {heading!r} group"
    print(f"OK: {heading} uses an explicit frame legend")
print(f"Calendar explicit frame headings: OK ({len(expected)} headings)")
PY
