#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Settings search match-count font size: FAIL: $*" >&2; exit 1; }

CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplyCore.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
WIDGET="$ROOT/components/settings/SettingsNavigation.qml"
TAB="$ROOT/components/settings/primitives/SettingsTabBase.qml"

for file in "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$PROFILES" "$RESETS" "$NAV" "$WINDOW" "$WIDGET" "$TAB"; do
    grep -Fq 'settingsSearchMatchCountFontSize' "$file" || fail "setting missing from ${file#$ROOT/}"
done

grep -Fq 'font.pixelSize: Config.settingsUiSize(Config.settingsSearchMatchCountFontSize)' "$TAB" || fail 'page/subtab badges ignore configured font size'
grep -Fq 'font.pixelSize: Config.settingsUiSize(Config.settingsSearchMatchCountFontSize)' "$WIDGET" || fail 'group/status counters ignore configured font size'
grep -Fq 'minimum: 6' "$WINDOW" || fail 'font size minimum is missing'
grep -Fq 'maximum: 12' "$WINDOW" || fail 'font size maximum is missing'

node - "$ROOT" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
function load(file, extra = {}) {
  const source = fs.readFileSync(path.join(root, file), 'utf8')
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/gm, '');
  const sandbox = { ...extra };
  vm.runInNewContext(source, sandbox, { filename: file });
  return sandbox;
}
const persistence = load('js/settings/SettingsPersistence.js');
const snapshot = persistence.snapshotObject({ moduleNames: [], colorNames: [], weatherToken: '' }, {
  settingsSearchMatchCountFontSize: 11
});
if (snapshot.settingsSearchMatchCountFontSize !== 11) throw new Error('settings snapshot lost count font size');
const schema = load('js/settings/SettingsSchema.js');
const apply = load('js/settings/SettingsApplyCore.js', { Schema: schema });
const config = { settingsSearchMatchCountFontSize: 8 };
apply.apply({}, config, { settingsSearchMatchCountFontSize: 12 });
if (config.settingsSearchMatchCountFontSize !== 12) throw new Error('saved count font size did not restore');
apply.apply({}, config, { settingsSearchMatchCountFontSize: 1 });
if (config.settingsSearchMatchCountFontSize !== 6) throw new Error('count font lower bound failed');
apply.apply({}, config, { settingsSearchMatchCountFontSize: 99 });
if (config.settingsSearchMatchCountFontSize !== 12) throw new Error('count font upper bound failed');
const resets = load('js/settings/SettingsResets.js');
const owner = {
  activeProfile: 'legacy', profiles: { legacy: {} }, expandedProfileData: () => ({}),
  defaultConfig: { settingsSearchMatchCountFontSize: 8 },
  settingsGeometry: [0, 0, 100, 100], settingsMonitorName: '',
  moduleBlurEnabled: {}, defaultModuleBlurEnabled: { settings: false },
  save() {}, resetUnavailable() {}
};
resets.resetSettingsWindowFromProfile(owner, config);
if (config.settingsSearchMatchCountFontSize !== 8) throw new Error('legacy profile did not fall back to default count font size');
console.log('Count font snapshot, restore, clamp and legacy profile reset: OK');
NODE

echo 'settings search match-count font size: OK'
