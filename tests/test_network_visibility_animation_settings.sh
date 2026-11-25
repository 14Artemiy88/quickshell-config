#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
defaults = (root / "js/settings/SettingsDefaults.js").read_text(encoding="utf-8")
persist = (root / "js/settings/SettingsPersistence.js").read_text(encoding="utf-8")
apply = (root / "js/settings/SettingsApplyBehaviour.js").read_text(encoding="utf-8")
resets = (root / "js/settings/SettingsResets.js").read_text(encoding="utf-8")
profiles = (root / "js/settings/SettingsProfiles.js").read_text(encoding="utf-8")
nav = (root / "components/settings/SettingsNavigationController.qml").read_text(encoding="utf-8")
section = (root / "components/settings/sections/SettingsNetworkSection.qml").read_text(encoding="utf-8")
shell = (root / "shell.qml").read_text(encoding="utf-8")
check = (root / "CHECK.sh").read_text(encoding="utf-8")

for source in (config, defaults):
    assert 'animationNetworkVisibilityStyle: "fade"' in source
    assert 'animationNetworkVisibilityDuration: 250' in source
assert 'animationNetworkVisibilityStyle: config.animationNetworkVisibilityStyle' in persist
assert 'animationNetworkVisibilityDuration: config.animationNetworkVisibilityDuration' in persist
assert '"animationNetworkVisibilityStyle"' in apply
assert '["animationNetworkVisibilityDuration", 0, 5000]' in apply
assert 'animationNetworkVisibilityStyle' in nav and 'animationNetworkVisibilityDuration' in nav
assert '"animationNetworkVisibilityStyle", "animationNetworkVisibilityDuration"' in resets
assert 'network: ["network", "systemMonitor", "animationNetwork"]' in profiles
assert 'visible: root.host && root.host.currentPageId === "network"' in section
assert 'root.host.currentPageSubTabIndex === 2 && !Config.networksAlwaysVisible' in section
assert 'heading: "Появление модуля"' in section
assert 'property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]' in section
assert 'targetProperty: "animationNetworkVisibilityDuration"' in section
assert 'animationStyle: Config.animationNetworkVisibilityStyle' in shell
assert 'duration: Config.animationNetworkVisibilityDuration' in shell
assert 'shown: Config.networksAlwaysVisible || shell.networksVisible || shell.layoutEditMode' in shell
assert 'test_network_visibility_animation_settings.sh' in check
print("Networks module visibility animation schema, profile/reset and UI integration: OK")
PY
node - "$ROOT/js/settings/SettingsApplyBehaviour.js" <<'NODE'
const fs = require('fs')
const vm = require('vm')
const assert = require('assert')
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma\s+library\s*;?\s*/m, '')
const context = {}
vm.runInNewContext(source, context)
const config = new Proxy({}, {
    get: (target, key) => target[key],
    set: (target, key, value) => (target[key] = value, true)
})
context.apply(config, { animationNetworkVisibilityStyle: 'slideUp', animationNetworkVisibilityDuration: 777 })
assert.strictEqual(config.animationNetworkVisibilityStyle, 'slideUp')
assert.strictEqual(config.animationNetworkVisibilityDuration, 777)
context.apply(config, { animationNetworkVisibilityStyle: 'invalid', animationNetworkVisibilityDuration: 9000 })
assert.strictEqual(config.animationNetworkVisibilityStyle, 'slideUp', 'invalid style must not overwrite the last valid style')
assert.strictEqual(config.animationNetworkVisibilityDuration, 5000, 'duration should clamp to 5000 ms')
console.log('Networks visibility animation settings normalization: OK')
NODE
