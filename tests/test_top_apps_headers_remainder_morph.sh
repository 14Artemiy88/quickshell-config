#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsCpuRamSection.qml"
fail() { echo "Top Apps headers/remainder MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "../../primitives"' "$QML" || fail "shared MorphGeometry import missing"
python3 - "$QML" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding="utf-8")

def block_for(identifier):
    marker = f"id: {identifier}"
    pos = s.find(marker)
    assert pos >= 0, f"{identifier} missing"
    start = s.rfind("MorphGeometry {", 0, pos)
    assert start >= 0, f"{identifier} is not inside MorphGeometry"
    opening = s.find("{", start)
    depth = 0
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    i = opening
    while i < len(s):
        c = s[i]
        n = s[i + 1] if i + 1 < len(s) else ""
        if line_comment:
            if c == "\n": line_comment = False
            i += 1; continue
        if block_comment:
            if c == "*" and n == "/": block_comment = False; i += 2
            else: i += 1
            continue
        if quote:
            if escaped: escaped = False
            elif c == "\\": escaped = True
            elif c == quote: quote = None
            i += 1; continue
        if c == "/" and n == "/": line_comment = True; i += 2; continue
        if c == "/" and n == "*": block_comment = True; i += 2; continue
        if c in ('"', "'"): quote = c
        elif c == "{": depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0: return s[start:i + 1]
        i += 1
    raise AssertionError(f"{identifier} block is not balanced")

specs = [
    ("topAppsHeadersMorph", "topAppsHeadersContent", "topAppsShowHeaders", [
        "CPU", "Память", "Основной заголовок", "Подзаголовок",
        "Размер основного заголовка", "Размер подзаголовка",
        "topAppsCpuHeaderTitleField", "topAppsCpuHeaderSubtitleField",
        "topAppsRamHeaderTitleField", "topAppsRamHeaderSubtitleField",
        "topAppsHeaderTitleFontSize", "topAppsHeaderSubtitleFontSize",
    ]),
    ("topAppsSystemRemainderMorph", "topAppsSystemRemainderContent", "topAppsShowSystemRemainder", [
        "Название строки остатка", "topAppsSystemRemainderLabelField", "topAppsSystemRemainderLabel",
    ]),
]
for morph_id, content_id, toggle, contents in specs:
    b = block_for(morph_id)
    for token in (
        f"id: {morph_id}", f"id: {content_id}",
        "fromGeometry: Qt.rect(0, 0, parent.width, 0)",
        f"toGeometry: Qt.rect(0, 0, parent.width, {content_id}.implicitHeight)",
        f"progress: Config.{toggle} ? 1 : 0",
        'animationDuration: Config.animationDuration(180, "appearance")',
        f'animationEasing: Config.animationEasingType("standard", Config.{toggle} ? "enter" : "exit")',
        "normalizedProgress > 0.001",
    ):
        assert token in b, f"{morph_id}: missing {token}"
    for token in contents:
        assert token in b, f"{morph_id}: dependent setting {token!r} missing from morph content"
    assert "visible: Config." + toggle not in b, f"{morph_id}: children must remain alive during exit morph"

# The two groups keep their own frame/title and toggle controls outside the morph.
for heading, toggle_text, assignment in (
    ("Заголовки", "Показывать заголовки CPU и памяти", "Config.topAppsShowHeaders = checked; settings.save()"),
    ("Строка «Система/прочее»", "Показывать строку «Система/прочее»", "Config.topAppsShowSystemRemainder = checked; settings.save()"),
):
    assert f'heading: "{heading}"' in s, f"{heading} frame title changed"
    group_start = s.rfind("SettingsGroup {", 0, s.index(f'heading: "{heading}"'))
    morph_pos = s.index("MorphGeometry {", group_start)
    prefix = s[group_start:morph_pos]
    assert f'text: "{toggle_text}"' in prefix, f"{heading} toggle was moved inside the morph"
    assert assignment in prefix, f"{heading} toggle save action changed"

# No old immediate-visibility guards may remain on the individual dependent rows.
assert 'visible: Config.topAppsShowHeaders && host.currentPageId === "cpuRam"' not in s, "header controls still use immediate visibility"
assert 'visible: Config.topAppsShowSystemRemainder && host.currentPageId === "cpuRam"' not in s, "remainder row still uses immediate visibility"
print("Top Apps headers and System/Other row MorphGeometry integration: OK")
PY
