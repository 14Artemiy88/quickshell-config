#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/settings/sections/SettingsTimersSection.qml" <<'PYCODE'
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

needle = 'heading: "Иконки таймера и будильника"'
assert source.count(needle) == 1, "Expected one explicit timer icon frame heading"
assert 'text: "Иконки таймера и будильника"' not in source, "Old nested title still exists"
start = source.find("SettingsGroup {", source.find(needle) - 200)
# Locate the group which owns the heading, then validate its frame and existing controls.
pos = source.find("SettingsGroup {")
group = None
while pos >= 0:
    opening = source.find("{", pos)
    end = matching_brace(source, opening)
    candidate = source[pos:end+1]
    if needle in candidate:
        group = candidate
        break
    pos = source.find("SettingsGroup {", end+1)
assert group is not None, "Heading must belong to a SettingsGroup"
assert "showFrame: true" in group, "Timer icon heading must be attached to a visible frame"
assert "host.currentOtherSubTab === 2" in group, "Existing tab visibility guard was lost"
for marker in ('"Иконка"', '"Размер"', '"X"', '"Y"', 'Config.timerIcon', 'Config.timerAlarmIcon'):
    assert marker in group, f"Existing timer icon controls/table columns missing: {marker}"
print("Timer icon explicit frame heading: OK (heading moved to frame; controls preserved)")
PYCODE
