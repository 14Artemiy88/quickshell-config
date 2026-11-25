#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplyCore.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"
fail() { echo "Settings search sidebar: FAIL: $*" >&2; exit 1; }

# Search is owned by the extracted sidebar component, immediately above grouped page navigation.
python3 - "$WIDGET" "$NAV" <<'PY'
from pathlib import Path
import sys
widget = Path(sys.argv[1]).read_text()
nav = Path(sys.argv[2]).read_text()
search = nav.index('id: settingsSearchInput')
groups = nav.index('id: mainSettingsTabs')
assert search < groups, 'search field is not placed above sidebar navigation'
assert 'id: settingsSearchContainer' in nav, 'animated sidebar search container is missing'
assert 'height: Config.settingsSearchVisible ? 30 : 0' in nav, 'hidden search does not release sidebar height'
assert 'opacity: Config.settingsSearchVisible ? 1 : 0' in nav, 'sidebar search does not fade with visibility changes'
assert 'Behavior on height' in nav and 'Behavior on opacity' in nav, 'sidebar search collapse/fade animations are missing'
assert 'spacing: Config.settingsSearchVisible ? 8 : 0' in nav, 'sidebar gap does not collapse with the search row'
assert 'function clearSettingsSearchQuery()' in widget, 'query cleanup helper is missing'
assert 'settingsNavigation.searchInput.text = ""' in widget, 'hiding search does not clear stale hidden query'
assert 'Math.max(0, parent.width - settingsNavigation.width - settingsBody.spacing)' in widget, 'page content width does not account for the responsive extracted sidebar'
header = widget[widget.index('Row {\n            width: parent.width\n            height: 28'):widget.index('id: settingsBody')]
assert 'settingsSearchInput' not in header, 'search field is still in the top header'
PY

grep -Fq 'property bool settingsSearchVisible: true' "$CONFIG" || fail 'Config default is missing'
grep -Fq 'settingsSearchVisible: true' "$DEFAULTS" || fail 'settings defaults are missing'
grep -Fq 'if (o.settingsSearchVisible !== undefined)' "$APPLY" || fail 'settings loader does not restore search visibility'
grep -Fq 'settingsSearchVisible: config.settingsSearchVisible' "$PERSIST" || fail 'settings snapshot omits search visibility'
grep -Fq '"settingsSearchVisible"' "$RESETS" || fail 'settings-window reset omits search visibility'
grep -Fq 'if (profile.settingsSearchVisible === undefined)' "$RESETS" || fail 'legacy profiles do not default search visibility to enabled'
grep -Fq '"settingsSearchVisible"' "$PROFILES" || fail 'search visibility is outside settings-window profile scope'
grep -Fq 'text: "Показывать поиск в боковой панели"' "$WINDOW" || fail 'visibility checkbox is missing'
grep -Fq 'host.clearSettingsSearchQuery()' "$WINDOW" || fail 'disabling search does not clear the query'
grep -Fq 'settingsSearchVisible' "$WINDOW" || fail 'settings-window dirty tracking omits search visibility'

echo 'settings search sidebar placement, visibility toggle and profile persistence: OK'

node - "$APPLY" "$PERSIST" "$PROFILES" "$RESETS" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
function load(path, extra = {}) {
  const source = fs.readFileSync(path, 'utf8')
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/gm, '');
  const sandbox = { ...extra };
  vm.runInNewContext(source, sandbox, { filename: path });
  return sandbox;
}
const schema = {
  normalizeSavedColor: (value, fallback) => typeof value === 'string' ? value : fallback,
  normalizeSettingsNavigationCollapsedGroups: (value, fallback) => value || fallback
};
const apply = load(process.argv[2], { Schema: schema });
const config = { settingsSearchVisible: true };
apply.apply({}, config, { settingsSearchVisible: false });
assert.strictEqual(config.settingsSearchVisible, false, 'settings loading applies hidden state');
apply.apply({}, config, { settingsSearchVisible: true });
assert.strictEqual(config.settingsSearchVisible, true, 'settings loading restores visible state');
const persistence = load(process.argv[3]);
const snapshot = persistence.snapshotObject({ moduleNames: [], colorNames: [], weatherToken: '' }, config);
assert.strictEqual(snapshot.settingsSearchVisible, true, 'settings snapshot retains visibility');
config.settingsSearchVisible = false;
const hiddenSnapshot = persistence.snapshotObject({ moduleNames: [], colorNames: [], weatherToken: '' }, config);
assert.strictEqual(hiddenSnapshot.settingsSearchVisible, false, 'settings snapshot retains hidden state');
const profiles = load(process.argv[4]);
assert.strictEqual(profiles.profileSavePathMatches({}, 'settingsWindow', null, ['settingsSearchVisible']), true,
  'visibility belongs to the settings-window profile scope');
const resets = load(process.argv[5]);
const resetConfig = { settingsSearchVisible: false, monitorName: 'primary' };
const owner = {
  activeProfile: 'active', profiles: { active: { settingsSearchVisible: true } },
  defaultConfig: { settingsSearchVisible: true },
  moduleBlurEnabled: { settings: true }, defaultModuleBlurEnabled: { settings: true },
  save() {}, resetUnavailable() {},
};
resets.resetSettingsWindowFromProfile(owner, resetConfig);
assert.strictEqual(resetConfig.settingsSearchVisible, true, 'window reset restores profile visibility');
owner.profiles.active = {};
resetConfig.settingsSearchVisible = false;
resets.resetSettingsWindowFromProfile(owner, resetConfig);
assert.strictEqual(resetConfig.settingsSearchVisible, true, 'legacy profile without the key defaults to visible');
console.log('settings search visibility load/save/profile/reset round-trip: OK');
NODE
