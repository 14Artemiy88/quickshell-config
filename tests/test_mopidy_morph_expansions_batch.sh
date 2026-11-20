#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE_BROWSER="$ROOT/components/mopidy/MopidyFileBrowser.qml"
TOP_PANEL="$ROOT/components/mopidy/MopidyTopPanel.qml"
fail() { echo "Mopidy MorphGeometry batch: FAIL: $*" >&2; exit 1; }

for file in "$FILE_BROWSER" "$TOP_PANEL"; do
    grep -Fq 'import "../primitives" as Primitives' "$file" || fail "shared primitive import missing in ${file##*/}"
done

python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
root = Path(sys.argv[1])
file_browser = (root / "components/mopidy/MopidyFileBrowser.qml").read_text(encoding="utf-8")
top_panel = (root / "components/mopidy/MopidyTopPanel.qml").read_text(encoding="utf-8")

# Lightweight QML delimiter validation (ignores comments and quoted strings).
def validate_delimiters(source: str, name: str) -> None:
    stack = []
    pairs = {"}": "{", ")": "(", "]": "["}
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    i = 0
    line = 1
    while i < len(source):
        c = source[i]
        n = source[i + 1] if i + 1 < len(source) else ""
        if c == "\n":
            line += 1
            line_comment = False
            i += 1
            continue
        if line_comment:
            i += 1
            continue
        if block_comment:
            if c == "*" and n == "/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue
        if quote:
            if escaped:
                escaped = False
            elif c == "\\":
                escaped = True
            elif c == quote:
                quote = None
            i += 1
            continue
        if c == "/" and n == "/":
            line_comment = True
            i += 2
            continue
        if c == "/" and n == "*":
            block_comment = True
            i += 2
            continue
        if c in ("'", '"'):
            quote = c
        elif c in "{([":
            stack.append((c, line))
        elif c in "})]":
            assert stack and stack[-1][0] == pairs[c], f"{name}: unexpected {c} at line {line}"
            stack.pop()
        i += 1
    assert not quote and not block_comment, f"{name}: unterminated string/comment"
    assert not stack, f"{name}: unclosed delimiter {stack[-1]}"

for name, source in (("MopidyFileBrowser.qml", file_browser), ("MopidyTopPanel.qml", top_panel)):
    validate_delimiters(source, name)

morph = (root / "components/primitives/MorphGeometry.qml")
assert morph.is_file(), "shared MorphGeometry source file missing"

# File browser filter: its 31px slot (27px field + 4px trailing space) grows
# while the ListView loses exactly the same amount of height.
for token in (
    'id: fileFilterMorph',
    'visible: controller.fileFilterOpen || normalizedProgress > 0.001',
    'fromGeometry: Qt.rect(0, 0, parent.width, 0)',
    'toGeometry: Qt.rect(0, 0, parent.width, 31)',
    'progress: controller.fileFilterOpen ? 1 : 0',
    'animationPhase: controller.fileFilterOpen ? \"enter\" : \"exit\"',
    'animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")',
    'animationProfile: Config.animationMopidyMorphProfile',
    'height: Math.max(0, parent.height - 26 - fileFilterMorph.geometryHeight)',
    'height: 27',
    'placeholderText: "Фильтр файлов…"',
    'onTextChanged: controller.fileFilterQuery = text',
    'controller.closeFileFilter(true)',
    'controller.closeFileFilter(false)',
):
    assert token in file_browser, f"file filter morph missing behavior: {token}"
assert 'Column {\n        anchors.fill: parent\n        spacing: 0' in file_browser, "file browser must use the explicit fixed-gap layout"
assert 'visible: controller.fileFilterOpen\n' not in file_browser, "old instant filter-row visibility binding remains"
assert 'controller.fileFilterOpen ? 57 : 26' not in file_browser, "list height must follow animated geometry"

# Hidden top panel: only hover reveal is animated; the wrapper's layout height
# and all button actions remain the same. Static mode must not animate at load.
for token in (
    'id: topPanelRevealMorph',
    'visible: topPanelWrapper.topPanelRevealed || normalizedProgress > 0.001',
    'fromGeometry: Qt.rect(0, 0, parent.width, 0)',
    'toGeometry: Qt.rect(0, 0, parent.width, 24)',
    'progress: topPanelWrapper.topPanelRevealed ? 1 : 0',
    'animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled && Config.mopidyHideTopPanel, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")',
    'animationProfile: Config.animationMopidyMorphProfile',
    'animationPhase: topPanelWrapper.topPanelRevealed ? "enter" : "exit"',
    'controller.toggleSearch()',
    'controller.stopPlayback()',
    'controller.clearQueue()',
):
    assert token in top_panel, f"top panel morph missing behavior: {token}"
assert 'height: Config.mopidyHideTopPanel ? Config.mopidyTopPanelOffsetY : (24 + Config.mopidyTopPanelOffsetY)' in top_panel, "top-panel layout-height contract changed"
import re
assert re.search(r'id: topPanelRow\s+width: parent\.width\s+height: 24\s+readonly property var normalizedTopIconOrder', top_panel), "top-panel row must retain its fixed 24px content size"
assert 'visible: topPanelWrapper.topPanelRevealed\n' not in top_panel, "old instant top-panel row visibility binding remains"

# Ensure the test is part of the main suite.
check = (root / "CHECK.sh").read_text(encoding="utf-8")
assert 'run_test "$ROOT/tests/test_mopidy_morph_expansions_batch.sh"' in check, "batch test is not registered in CHECK.sh"
print("Mopidy file-filter and top-panel MorphGeometry batch: OK")
PYTEST
