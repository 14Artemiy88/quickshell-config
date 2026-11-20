#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/settings/sections/mopidy/SettingsMopidySection.qml" "$ROOT/components/settings/sections/mopidy/SettingsMopidyTimeSection.qml" "$ROOT/components/settings/sections/mopidy/SettingsMopidyAnimationSection.qml" <<'PYCODE'
from pathlib import Path
import sys


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
        if ch in ('"', "'", "`"): quote = ch
        elif ch == "{": depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0: return i
        i += 1
    raise AssertionError(f"unclosed QML block at offset {opening}")


def qml_blocks(text, marker):
    found = []
    pos = 0
    while True:
        start = text.find(marker, pos)
        if start < 0: break
        opening = text.find("{", start)
        end = matching_brace(text, opening)
        found.append(text[start:end + 1])
        pos = end + 1
    return found

expected_by_file = {
    sys.argv[1]: {
        "Поведение": "id: toggleWithPlayerCheckBox",
        "Внешний вид": 'targetProperty: "mopidyBackground"',
        "Очередь": "id: trackNumbersCheckBox",
        "Громкость": "id: volumePercentCheckBox",
    },
    sys.argv[2]: {
        "Время очереди": "id: showQueueTimeCheckBox",
        "Время треков и альбомов": "id: showTrackRemainingCheckBox",
        "Название и исполнитель": "id: trackArtistDisplayModeCombo",
        "Шрифты очереди": 'SettingsFontField {',
    },
    sys.argv[3]: {
        "Появление модуля": "id: animationMopidyVisibilityBox",
    },
}

# The shared animation group now owns its internal frame and reusable controls.
primitive_path = Path(sys.argv[3]).parents[2] / "primitives" / "SettingsAnimationGroup.qml"
primitive = primitive_path.read_text(encoding="utf-8")
section = Path(sys.argv[3]).read_text(encoding="utf-8")
assert 'SettingsAnimationGroup {' in section and 'heading: "Внутренние переходы"' in section
assert 'heading: root.heading' in primitive and 'SettingsNumberField {' in primitive
assert 'SettingsCheckBox {' not in primitive and 'id: enabledCheckBox' not in primitive
assert 'id: profileComboBox' in primitive

count = 0
for filename, expected in expected_by_file.items():
    source = Path(filename).read_text(encoding="utf-8")
    groups = qml_blocks(source, "SettingsGroup {")
    for heading, related_control in expected.items():
        key = f'heading: "{heading}"'
        matches = [group for group in groups if key in group]
        assert len(matches) == 1, f"{filename}: expected one explicit heading {heading!r}, got {len(matches)}"
        group = matches[0]
        assert "showFrame: true" in group, f"{heading!r} is not framed"
        assert ('visible: root.host && root.host.currentPageId === \"mopidy\" && root.host.currentPageSubTabIndex === 4' in group
                if filename == sys.argv[3] else 'visible: host && host.currentPageId === \"mopidy\"' in group), f"{heading!r} lost its tab visibility guard"
        assert related_control in group, f"{heading!r} lost related control {related_control!r}"
        if heading == "Шрифты очереди":
            for font_key in ("mopidyAlbumFont", "mopidyTrackFont", "mopidyArtistFont", "mopidyDurationFont"):
                assert f'targetProperty: "{font_key}"' in group, f"{heading!r} lost {font_key} binding"
        assert f'text: "{heading}"' not in group, f"{heading!r} still has a duplicate legacy title"
        count += 1
print(f"Mopidy explicit settings frame headings: OK ({count} local headings plus shared animation group; controls and visibility retained)")
PYCODE
