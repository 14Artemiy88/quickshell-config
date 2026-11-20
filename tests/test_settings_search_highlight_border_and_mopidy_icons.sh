#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Settings search border width and Mopidy icons: FAIL: $*" >&2; exit 1; }

CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplyCore.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
MOPIDY_ICONS="$ROOT/components/settings/sections/mopidy/SettingsMopidyIconsSection.qml"

# The preference is wired into every visible search outline, not just section frames.
grep -Fq 'property int settingsSearchHighlightBorderWidth: 2' "$CONFIG" || fail 'Config default is missing'
grep -Fq 'settingsSearchHighlightBorderWidth: 2' "$DEFAULTS" || fail 'settings defaults do not include the border width'
grep -Fq 'settingsSearchHighlightBorderWidth: config.settingsSearchHighlightBorderWidth' "$PERSIST" || fail 'border width is not persisted'
grep -Fq 'Config.settingsSearchHighlightBorderWidth = Math.max(1, Math.min(5, Math.round(searchBorderWidth)))' "$APPLY" || fail 'border width is not clamped on restore'
grep -Fq 'settingsSearchHighlightBorderWidth' "$PROFILES" || fail 'border width is not part of settings-window profiles'
grep -Fq 'settingsSearchHighlightBorderWidth' "$RESETS" || fail 'border width is not restored by profile reset'
grep -Fq 'Толщина рамки совпадений' "$WINDOW" || fail 'border width control is missing'
grep -Fq 'minimum: 1' "$WINDOW" || fail 'border width minimum is not 1'
grep -Fq 'maximum: 5' "$WINDOW" || fail 'border width maximum is not 5'

# Controls with an overlay share the same highlight primitive; fields that paint
# their own border retain the configured width in their background.
for primitive in SettingsCheckBox SettingsNumberField SettingsColorField SettingsFontField SettingsGroup; do
    grep -Fq 'SettingsSearchHighlight {' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive does not use the shared highlight primitive"
done
for primitive in SettingsInputField SettingsComboBox SettingsTabBase; do
    grep -Fq 'Config.settingsSearchHighlightBorderWidth' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive ignores the configured border width"
done
grep -Fq 'Config.settingsSearchHighlightBorderWidth' "$ROOT/components/settings/primitives/SettingsSearchHighlight.qml" || fail 'shared highlight primitive ignores the configured border width'
grep -Fq 'Config.settingsSearchHighlightBorderWidth' "$ROOT/components/settings/SettingsNavigation.qml" || fail 'navigation group outline ignores the configured border width'

# Mopidy's Icons panel is subtab 2. Every icon input must carry searchable metadata,
# rather than letting the neighbouring size/X/Y number fields stand in for it.
grep -Fq 'property int settingsSearchSubTabIndex: 2' "$MOPIDY_ICONS" || fail 'Mopidy Icons subtab index is missing'
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const qml = fs.readFileSync(path.join(root, 'components/settings/sections/mopidy/SettingsMopidyIconsSection.qml'), 'utf8');
const expected = [
  'stopIconField', 'refreshIconField', 'openAddIconField', 'addIconField',
  'shuffleIconField', 'repeatIconField', 'switchPlaylistIconField',
  'playlistDeleteIconField', 'moveUpIconField', 'moveDownIconField',
  'volumeIconField', 'mutedIconField', 'clearIconField'
];
const entries = [];
for (const id of expected) {
  const at = qml.indexOf(`id: ${id};`);
  if (at < 0) throw new Error(`missing Mopidy icon field ${id}`);
  const block = qml.slice(at, at + 560);
  const label = block.match(/settingsSearchLabel:\s*"([^"]+)"/);
  const keywords = block.match(/settingsSearchKeywords:\s*"([^"]+)"/);
  if (!label || !keywords) throw new Error(`${id} has no explicit icon search metadata`);
  entries.push({
    id,
    label: label[1],
    pageId: 'mopidy',
    pageLabel: 'Mopidy',
    searchText: `${label[1]} ${keywords[1]} Mopidy Иконки`,
    keyTerms: keywords[1],
    subTabIndex: 2
  });
}
let source = fs.readFileSync(path.join(root, 'js/settings/SettingsSearch.js'), 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const search = {};
vm.runInNewContext(source, search, { filename: 'SettingsSearch.js' });
const matches = search.search(entries, 'Иконки', entries.length);
if (matches.length !== expected.length)
  throw new Error(`search for Иконки matched ${matches.length}/${expected.length} icon-column fields`);
if (matches.some(item => item.subTabIndex !== 2))
  throw new Error('icon-column result is not routed to Mopidy → Icons subtab');
console.log('Mopidy icon-column search coverage: 13/13');
NODE

# Verify setting snapshot/apply/profile legacy fallback.
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
  settingsSearchHighlightBorderWidth: 4
});
if (snapshot.settingsSearchHighlightBorderWidth !== 4) throw new Error('snapshot lost highlight border width');
const schema = load('js/settings/SettingsSchema.js');
const apply = load('js/settings/SettingsApplyCore.js', { Schema: schema });
const config = { settingsSearchHighlightBorderWidth: 2 };
apply.apply({}, config, { settingsSearchHighlightBorderWidth: 5 });
if (config.settingsSearchHighlightBorderWidth !== 5) throw new Error('persisted border width did not restore');
apply.apply({}, config, { settingsSearchHighlightBorderWidth: 0 });
if (config.settingsSearchHighlightBorderWidth !== 1) throw new Error('border width lower bound failed');
apply.apply({}, config, { settingsSearchHighlightBorderWidth: 99 });
if (config.settingsSearchHighlightBorderWidth !== 5) throw new Error('border width upper bound failed');
const resets = load('js/settings/SettingsResets.js');
const owner = {
  activeProfile: 'legacy', profiles: { legacy: {} }, expandedProfileData: () => ({}),
  defaultConfig: { settingsSearchHighlightBorderWidth: 2 },
  settingsGeometry: [0, 0, 100, 100], settingsMonitorName: '',
  moduleBlurEnabled: {}, defaultModuleBlurEnabled: { settings: false },
  save() {}, resetUnavailable() {}
};
resets.resetSettingsWindowFromProfile(owner, config);
if (config.settingsSearchHighlightBorderWidth !== 2) throw new Error('legacy profile did not fall back to default border width');
console.log('Border-width snapshot, restore, clamp and legacy profile reset: OK');
NODE

echo 'settings search border width and Mopidy icons: OK'
