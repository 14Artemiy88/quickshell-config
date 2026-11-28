#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/components/settings/primitives/SettingsGroup.qml" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding='utf-8')
assert 'anchors.topMargin: root.hasHeading ? 8 : 0' in s, 'framed top edge must move under the legend'
assert 'id: headingBorderCutout' in s, 'legend needs an explicit border cutout'
assert 'x: headingLabel.x - 5' in s, 'cutout must extend beyond the text bounds'
assert 'y: 8 - root.borderWidth' in s, 'cutout must cover the top border stroke'
assert 'color: root.headingBackgroundColor' in s, 'cutout must use the surrounding surface color'
assert 'property color headingBackgroundColor:' in s, 'surface color must be overridable for non-default frames'
assert 'y: 2' in s, 'legend remains inside item geometry instead of overflowing above the frame'
print('SettingsGroup title interrupts the top border and remains within layout bounds: OK')
PY
