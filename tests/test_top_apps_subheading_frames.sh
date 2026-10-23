#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/settings/sections/SettingsCpuRamSection.qml" <<'PY'
import re
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
            if ch == "\n":
                line_comment = False
            i += 1
            continue
        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue
        if quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
            i += 1
            continue
        if ch == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue
        if ch in ('"', "'"):
            quote = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise AssertionError("unclosed QML block")

def direct_objects(body):
    objects = []
    depth = 0
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    i = 0
    while i < len(body):
        ch = body[i]
        nxt = body[i + 1] if i + 1 < len(body) else ""
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
        if ch in ('"', "'"): quote = ch; i += 1; continue
        if depth == 0:
            match = re.match(r"\s*([A-Za-z_][\w.]*)\s*\{", body[i:])
            if match:
                name = match.group(1)
                brace = i + match.end() - 1
                end = matching_brace(body, brace)
                objects.append((name, body[i:end + 1]))
                i = end + 1
                continue
        if ch == "{": depth += 1
        elif ch == "}": depth -= 1
        i += 1
    return objects

def groups(text):
    found = []
    for match in re.finditer(r"SettingsGroup\s*\{", text):
        opening = text.find("{", match.start())
        end = matching_brace(text, opening)
        found.append(text[opening + 1:end])
    return found

expected = {
    "Заголовки": "Config.topAppsShowHeaders",
    "Положение и размер полос": "Config.topAppsShowBars",
    "Цвета полос нагрузки": "Config.topAppsShowBars",
    "Строка «Система/прочее»": "Config.topAppsShowSystemRemainder",
    "Список приложений": "host.currentOtherTab === 5",
}
all_groups = groups(source)
for title, guard in expected.items():
    candidates = [block for block in all_groups if f'heading: "{title}"' in block]
    assert len(candidates) == 1, f"Expected exactly one explicit legend for {title!r}, found {len(candidates)}"
    block = candidates[0]
    assert "showFrame: true" in block, f"{title!r} must use a visible frame"
    first_visibility = next((line.strip() for line in block.splitlines() if re.match(r"\s*visible:", line)), "")
    if title == "Цвета полос нагрузки":
        assert "Config.topAppsShowBars" in first_visibility, "Color frame must remain conditional on bars being enabled"
    else:
        assert "host.currentOtherTab === 5" in first_visibility and "topAppsShowHeaders" not in first_visibility and "topAppsShowSystemRemainder" not in first_visibility and "topAppsShowBars" not in first_visibility, f"Frame/legend {title!r} must remain visible while its feature is disabled"
    assert f'text: "{title}"' not in block, f"{title!r} remains duplicated as an in-frame Text instead of using the explicit legend"
    print(f"OK: {title} uses an explicit, stable frame legend")

# Explicit SettingsGroup.heading must drive rendering without adopting a child Text.
primitive = (Path(sys.argv[1]).parents[1] / "primitives" / "SettingsGroup.qml")
component = primitive.read_text(encoding="utf-8")
assert 'property string heading: ""' in component
assert 'readonly property string renderedHeading:' in component
assert 'text: root.renderedHeading' in component
assert 'if (root.heading.trim().length > 0)' in component, "Explicit headings must bypass child-order inference"
assert 'root.heading.trim().length > 0' in component, "Explicit headings must be visible independent of a child checkbox"

# Bar geometry and colors remain separate frames, with color options hidden when bars are disabled.
geometry = next(g for g in all_groups if 'heading: "Положение и размер полос"' in g)
colors = next(g for g in all_groups if 'heading: "Цвета полос нагрузки"' in g)
assert geometry != colors
assert "showFrame: true" in geometry and "showFrame: true" in colors
assert re.search(r"visible:\s*host\s*&&.*Config\.topAppsShowBars", colors), "Bar-colour frame must disappear with bars disabled"
print("Top Apps explicit frame legends: OK")
PY
