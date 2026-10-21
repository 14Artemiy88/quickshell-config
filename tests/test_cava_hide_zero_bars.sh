#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CAVA zero-height bar visibility: FAIL: $*" >&2; exit 1; }

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
files = {
    'config': root / 'Config.qml',
    'defaults': root / 'js/settings/SettingsDefaults.js',
    'apply': root / 'js/settings/SettingsApplyWeather.js',
    'persist': root / 'js/settings/SettingsPersistence.js',
    'resets': root / 'js/settings/SettingsResets.js',
    'settings': root / 'components/settings/sections/SettingsCavaSection.qml',
    'cava': root / 'components/Cava.qml',
    'primitive': root / 'components/primitives/SegmentBarGraph.qml',
}
s = {key: path.read_text(encoding='utf-8') for key, path in files.items()}
def need(ok, message):
    if not ok:
        raise SystemExit('CAVA zero-height bar visibility: FAIL: ' + message)

need('property bool cavaHideZeroBars: false' in s['config'], 'Config property/default is missing')
need('cavaHideZeroBars: false' in s['defaults'], 'built-in reset default is missing')
need('if (o.cavaHideZeroBars !== undefined) Config.cavaHideZeroBars = !!o.cavaHideZeroBars' in s['apply'], 'saved value is not restored')
need('cavaHideZeroBars: config.cavaHideZeroBars' in s['persist'], 'setting is not persisted')
need(s['resets'].count('"cavaHideZeroBars"') == 2, 'CAVA profile reset lists must include the new setting')

ui = s['settings']
need('text: "Скрывать пустые полоски"' in ui, 'checkbox label is missing')
need('visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 0 && Config.cavaHideWhenSilent' in ui,
     'checkbox must only be shown when hide-when-silent is enabled')
need('checked: Config.cavaHideZeroBars' in ui and 'Config.cavaHideZeroBars = checked' in ui and 'settings.save()' in ui,
     'checkbox must read, update, and save the setting')

cava = s['cava']
expected_binding = 'hideZeroBars: Config.cavaHideWhenSilent && Config.cavaHideZeroBars'
need(cava.count(expected_binding) == 4, 'all four CAVA graph regions must honor the option')

primitive = s['primitive']
need('property bool hideZeroBars: false' in primitive, 'shared renderer must preserve default behaviour')
need('if (root.hideZeroBars && percent <= 0) return 0' in primitive,
     'zero/invalid values must calculate to zero height only when option is enabled')
need('visible: !root.hideZeroBars || height > 0' in primitive,
     'zero-height rectangles must be hidden when option is enabled')
need('return Math.max(1, Math.min(availableHeight, percent * availableHeight / 100))' in primitive,
     'non-zero bars must keep their 1px minimum height')

# Model the intended rule: old/default mode preserves a 1px zero bar, while
# the opt-in mode yields no height for zero/invalid samples and still renders
# any positive sample with the established 1px minimum.
def bar_height(value, available_height, hide_zero):
    try: percent = float(value)
    except (TypeError, ValueError): percent = 0.0
    if not (percent == percent and abs(percent) != float('inf')): percent = 0.0
    if hide_zero and percent <= 0: return 0
    return max(1, min(available_height, percent * available_height / 100))
need(bar_height(0, 40, False) == 1, 'default behavior changed for other graph users')
need(bar_height(0, 40, True) == 0, 'zero CAVA sample should have zero height')
need(bar_height(None, 40, True) == 0, 'invalid/empty CAVA sample should be hidden')
need(bar_height(0.1, 40, True) == 1, 'positive low-level signal should still remain visible')
need(bar_height(50, 40, True) == 20, 'normal positive signal height changed')
print('CAVA zero-height bar visibility: OK')
PY
