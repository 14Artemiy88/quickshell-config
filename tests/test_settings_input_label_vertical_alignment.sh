#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/settings/sections" "$ROOT/components/settings/primitives/SettingsNumberField.qml" "$ROOT/components/settings/primitives/SettingsColorField.qml" "$ROOT/components/settings/primitives/SettingsFontField.qml" <<'PY'
from pathlib import Path
import re
import sys

sections = Path(sys.argv[1])
number_primitive = Path(sys.argv[2]).read_text()
color_primitive = Path(sys.argv[3]).read_text()
font_primitive = Path(sys.argv[4]).read_text()
row_primitive = (sections.parent / "primitives" / "SettingsRow.qml").read_text()
interactive = (
    "SettingsTextField", "SettingsInputField", "SettingsNumberField",
    "SettingsColorField", "SettingsComboBox", "SettingsCheckBox",
    "TextField", "ComboBox",
    "SpinBox", "CheckBox",
)

def blocks(source: str, name: str):
    """Return QML object blocks while ignoring braces inside strings/comments."""
    result = []
    for match in re.finditer(r"\b" + re.escape(name) + r"\s*\{", source):
        opening = source.find("{", match.start(), match.end())
        depth = 0
        state = "normal"
        i = opening
        while i < len(source):
            ch = source[i]
            nxt = source[i + 1] if i + 1 < len(source) else ""
            if state == "normal":
                if ch == "/" and nxt == "/":
                    state = "line-comment"; i += 2; continue
                if ch == "/" and nxt == "*":
                    state = "block-comment"; i += 2; continue
                if ch in ("'", '"'):
                    state = ch; i += 1; continue
                if ch == "{": depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        result.append((match.start(), i + 1, source[match.start():i + 1]))
                        break
                i += 1
            elif state == "line-comment":
                if ch == "\n": state = "normal"
                i += 1
            elif state == "block-comment":
                if ch == "*" and nxt == "/": state = "normal"; i += 2
                else: i += 1
            else:
                if ch == "\\": i += 2
                elif ch == state: state = "normal"; i += 1
                else: i += 1
    return result

def structural_depth(fragment: str) -> int:
    depth = 0
    state = "normal"
    i = 0
    while i < len(fragment):
        ch = fragment[i]
        nxt = fragment[i + 1] if i + 1 < len(fragment) else ""
        if state == "normal":
            if ch == "/" and nxt == "/": state = "line-comment"; i += 2; continue
            if ch == "/" and nxt == "*": state = "block-comment"; i += 2; continue
            if ch in ("'", '"'): state = ch; i += 1; continue
            if ch == "{": depth += 1
            elif ch == "}": depth -= 1
            i += 1
        elif state == "line-comment":
            if ch == "\n": state = "normal"
            i += 1
        elif state == "block-comment":
            if ch == "*" and nxt == "/": state = "normal"; i += 2
            else: i += 1
        else:
            if ch == "\\": i += 2
            elif ch == state: state = "normal"; i += 1
            else: i += 1
    return depth

checked = 0
violations = []
for path in sorted(sections.rglob("*.qml")):
    source = path.read_text()
    for row_start, _, row in blocks(source, "Row"):
        if not any(re.search(r"\b" + re.escape(component) + r"\s*\{", row) for component in interactive):
            continue
        for label_start, _, label in blocks(row, "Text"):
            if structural_depth(row[:label_start]) != 1:
                continue
            if not re.search(r"\bwidth\s*:", label):
                continue
            font_size = re.search(r"font\.pixelSize\s*:\s*Config\.settingsUiSize\((\d+)\)", label)
            if not font_size or int(font_size.group(1)) > 12:
                continue
            # These are decorative headings/buttons rather than form labels.
            if any(marker in label for marker in (
                "root.currentPageTitle", "modelData.title", "profileSavedMark",
                "Сбросить все настройки", "Модули и их расположение",
            )):
                continue
            height = re.search(r"\bheight\s*:\s*([^;\n]+)", label)
            line = source.count("\n", 0, row_start) + 1
            checked += 1
            if not height or height.group(1).strip() != "30":
                label_line = source.count("\n", 0, row_start + label_start) + 1
                violations.append(f"{path.name}:{label_line}: expected label height: 30 (row at {line})")

# SettingsRow owns the label box for rows migrated to the reusable primitive.
# Count these labels explicitly and verify they inherit the full row height.
for path in sorted(sections.rglob("*.qml")):
    source = path.read_text()
    for row_start, _, row in blocks(source, "SettingsRow"):
        label = re.search(r"(?m)^\s*label\s*:\s*\"", row)
        if not label:
            continue
        row_height = re.search(r"\bheight\s*:\s*30(?:\s*[;\n])", row)
        explicit_label_height = re.search(r"(?m)^\s*labelHeight\s*:\s*30\b", row)
        line = source.count("\n", 0, row_start) + 1
        checked += 1
        if not row_height and not explicit_label_height and "property real labelHeight: 30" not in row_primitive:
            violations.append(f"{path.name}:{line}: SettingsRow must retain a centered 30px label box")

assert checked >= 190, f"Audit covered too few inline setting labels: {checked}"
assert not violations, "Misaligned settings labels:\n" + "\n".join(violations)
assert re.search(r"SettingsLabel\s*\{[^}]*height\s*:\s*root\.height", number_primitive, re.S), \
    "SettingsNumberField must use a shared label matching the control height"
assert re.search(r"SettingsLabel\s*\{[^}]*height\s*:\s*root\.fieldHeight", color_primitive, re.S), \
    "SettingsColorField must use a shared label matching the control height"
assert re.search(r"SettingsLabel\s*\{[^}]*height\s*:\s*root\.fieldHeight", font_primitive, re.S), \
    "SettingsFontField must use a shared label matching the control height"
print(f"settings input-label vertical alignment: OK ({checked} labels, shared 30px label boxes)")
PY
