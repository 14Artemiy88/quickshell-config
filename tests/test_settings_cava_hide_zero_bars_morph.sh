#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsCavaSection.qml"

grep -Fq 'import "../../primitives"' "$QML"
grep -Fq 'id: cavaHideZeroBarsMorph' "$QML"
grep -Fq 'visible: Config.cavaHideWhenSilent || normalizedProgress > 0.001' "$QML"
grep -Fq 'fromGeometry: Qt.rect(0, 0, parent.width, 0)' "$QML"
grep -Fq 'toGeometry: Qt.rect(0, 0, parent.width, cavaHideZeroBarsContent.implicitHeight)' "$QML"
grep -Fq 'progress: Config.cavaHideWhenSilent ? 1 : 0' "$QML"
grep -Fq 'animationDuration: Config.animationDuration(180, "appearance")' "$QML"
grep -Fq 'animationEasing: Config.animationEasingType("standard", Config.cavaHideWhenSilent ? "enter" : "exit")' "$QML"

python3 - "$QML" <<'PYTEST'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
start = s.index('id: cavaHideZeroBarsMorph')
end = s.index('\n        SettingsRow {\n            id: cavaFramerateField', start)
block = s[start:end]
assert block.count('visible:') == 1, 'only MorphGeometry should control the row visibility'
assert 'id: cavaHideZeroBarsContent' in block
assert 'id: cavaHideZeroBarsCheckBox' in block
assert 'Config.cavaHideZeroBars = checked' in block
assert 'settings.save()' in block
PYTEST

printf 'CAVA hide-zero-bars MorphGeometry integration: OK\n'
