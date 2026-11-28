#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
FONT_FIELD="$ROOT/components/settings/primitives/SettingsFontField.qml"

# Empty/reset font overrides must resolve to Qt's generic UI family, not an
# alphabetically first installed font (which can be an icon-only Arrows face).
grep -Fq 'readonly property string settingsFontFamily:' "$CONFIG"
grep -Fq 'function resolveFontFamily(overrideFamily)' "$CONFIG"
grep -Fq 'return family.length > 0 ? family : "Sans Serif"' "$CONFIG"
grep -Fq 'readonly property string settingsFontFamily: resolveFontFamily(settingsFont)' "$CONFIG"
grep -Fq 'property string settingsFont: "JetBrainsMono Nerd Font"' "$CONFIG"
grep -Fq 'onClicked: root.commit("")' "$FONT_FIELD"
! grep -Eq 'families\(\)\s*\[\s*0\s*\]|availableFamilies\(\)\s*\[\s*0\s*\]|"Arrows"' "$CONFIG" "$FONT_FIELD"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
qml = list((root / 'components').rglob('*.qml'))
old = []
new = 0
for path in qml:
    source = path.read_text(encoding='utf-8', errors='ignore')
    if 'font.family: Config.settingsFont\n' in source or 'font.family: Config.settingsFont;' in source:
        old.append(str(path.relative_to(root)))
    new += source.count('font.family: Config.settingsFontFamily')
assert not old, 'Settings UI still binds raw settingsFont: ' + ', '.join(old)
assert new >= 300, f'Expected shared generic-family binding across settings UI, found {new}'
# Every optional override that previously relied on an empty family or Qt.application.font
# now resolves through the generic desktop family. LED-specific Weather/Clock fallbacks
# remain intentional and are not part of this scan.
checks = {
    'components/notifications/Notifications.qml': [
        'Config.resolveFontFamily(Config.notificationsAppNameFont)',
        'Config.resolveFontFamily(Config.notificationsSummaryFont)',
        'Config.resolveFontFamily(Config.notificationsBodyFont)',
    ],
    'components/launcher/Launcher.qml': [
        'Config.resolveFontFamily(Config.launcherTitleFont)',
        'Config.resolveFontFamily(Config.launcherSearchFont)',
    ],
    'components/TopApps.qml': ['Config.resolveFontFamily(Config.topAppsFont)'],
    'components/NetworkStatRow.qml': ['Config.resolveFontFamily(Config.networkFont)'],
    'components/Volumes.qml': ['Config.resolveFontFamily(Config.volumeStreamLabelFont)'],
    'components/primitives/StyledTextButton.qml': ['Config.resolveFontFamily(root.textFontFamily)'],
}
for relative, fragments in checks.items():
    source = (root / relative).read_text(encoding='utf-8')
    for fragment in fragments:
        assert fragment in source, f'{relative} does not resolve empty font override: {fragment}'
assert 'Qt.application.font.family' not in (root / 'components/TopApps.qml').read_text()
assert 'Qt.application.font.family' not in (root / 'components/NetworkStatRow.qml').read_text()
assert 'Qt.application.font.family' not in (root / 'components/Volumes.qml').read_text()

print(f'System font fallback uses Qt generic Sans Serif; {new} settings bindings and optional module overrides: OK')
PY

echo 'Settings system font fallback: OK'


node - "$CONFIG" <<'NODE'
const fs = require('fs');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8');
const match = source.match(/function resolveFontFamily\(overrideFamily\) \{([\s\S]*?)\n    \}/);
assert(match, 'shared font resolver function is missing');
const resolveFontFamily = new Function('overrideFamily', match[1]);
assert.strictEqual(resolveFontFamily(''), 'Sans Serif', 'empty override resolves to generic system UI font');
assert.strictEqual(resolveFontFamily('   \n\t'), 'Sans Serif', 'whitespace override resolves to generic system UI font');
assert.strictEqual(resolveFontFamily(null), 'Sans Serif', 'null override resolves to generic system UI font');
assert.strictEqual(resolveFontFamily('  Noto Sans  '), 'Noto Sans', 'explicit family is normalized but preserved');
assert.strictEqual(resolveFontFamily('Arrows'), 'Arrows', 'explicit user choice is never silently replaced');
console.log('Font-family resolver behavior: empty/null => Sans Serif; explicit override preserved: OK');
NODE
