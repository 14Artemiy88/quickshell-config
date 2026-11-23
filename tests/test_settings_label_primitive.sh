#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
primitive = root / "components/settings/primitives/SettingsLabel.qml"
assert primitive.is_file(), "shared SettingsLabel primitive is missing"
source = primitive.read_text()
assert re.search(r"(?m)^Text\s*\{", source), "SettingsLabel must remain a Text-based primitive"
assert 'font.family: Config.settingsFont' in source, "shared settings font is not applied"
assert 'font.pixelSize: Config.settingsUiSize(root.settingsFontSize)' in source, "settings font scaling is not applied"
assert 'property real settingsFontSize: 11' in source, "default label size changed"
assert 'color: root.enabled ? Config.text : Config.textMuted' in source, "label must retain the default color and use muted color when disabled"
assert 'verticalAlignment: Text.AlignVCenter' in source, "default label alignment changed"

primitive_dir = root / "components/settings/primitives"
row_primitive = primitive_dir / "SettingsRow.qml"
assert row_primitive.is_file() and 'SettingsLabel {' in row_primitive.read_text(), "SettingsLabel is not reused by SettingsRow"

# Standard field primitives must delegate their visible labels to the same
# typography component, so font family/scale/alignment stay consistent.
for filename in (
    "SettingsNumberField.qml",
    "SettingsColorField.qml",
    "SettingsFontField.qml",
    "SettingsCheckBox.qml",
):
    source = (primitive_dir / filename).read_text()
    assert "SettingsLabel {" in source, f"{filename} does not use SettingsLabel"

# Search metadata and editable controls remain owned by their specialized
# wrappers; the shared label is presentation-only.
for filename in ("SettingsNumberField.qml", "SettingsColorField.qml", "SettingsFontField.qml"):
    source = (primitive_dir / filename).read_text()
    assert "property string settingsSearchLabel" in source, f"{filename} lost search metadata"
    assert "SettingsInputField {" in source, f"{filename} lost its editable input"

print("SettingsLabel primitive: shared by row and field controls: OK")
PY
