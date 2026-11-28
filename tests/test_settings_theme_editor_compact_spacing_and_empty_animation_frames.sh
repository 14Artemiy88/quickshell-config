#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
colors = (root / "components/settings/sections/SettingsColorsSection.qml").read_text(encoding="utf-8")
group = (root / "components/settings/primitives/SettingsGroup.qml").read_text(encoding="utf-8")
field = (root / "components/settings/primitives/SettingsColorField.qml").read_text(encoding="utf-8")
description = (root / "components/settings/primitives/SettingsDescription.qml").read_text(encoding="utf-8")
assert 'padding: 8' in colors and 'contentSpacing: 5' in colors
assert 'headingContentGap: 6' not in colors
assert 'height: 30' in colors
assert 'fieldHeight: 26' in colors and 'swatchSize: 22' in colors
assert 'height: visible ? implicitHeight : 0' in colors, "hidden optional copy must not reserve a row"
assert 'property real headingContentGap: 8' in group
assert 'root.padding + (root.hasHeading ? root.headingContentGap : 0)' in group
assert '(root.hasHeading ? root.headingContentGap : 0)' in group
assert 'headingActions: Component {' in colors
assert 'headingActionsLoader.width + 8' in group, "legend must reserve space for Save/Reset icons"
assert 'visible: Config.settingsShowDescriptions && root.descriptionConditionVisible' in description

# Every "What is controlled" informational frame must disappear with its own description.
paths = [
    "components/settings/sections/SettingsCavaSection.qml",
    "components/settings/sections/SettingsCalendarSection.qml",
    "components/settings/sections/SettingsNetworkSection.qml",
    "components/settings/sections/SettingsCpuRamSection.qml",
    "components/settings/sections/SettingsWeatherAnimationSection.qml",
    "components/settings/sections/SettingsPlayerAnimationSection.qml",
]
for relative in paths:
    source = (root / relative).read_text(encoding="utf-8")
    marker = 'heading: "Что управляется"'
    index = source.find(marker)
    assert index >= 0, f"missing informational frame in {relative}"
    block = source[max(0, index - 600):index]
    assert 'Config.settingsShowDescriptions' in block, f"empty informational frame can remain visible in {relative}"
print("Theme editor compact frame header, collapsed hidden descriptions, and all six animation explainer frames: OK")
PY
