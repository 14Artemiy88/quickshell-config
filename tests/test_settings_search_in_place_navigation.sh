#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
PAGE_HOST="$ROOT/components/settings/SettingsPageHost.qml"
GROUP="$ROOT/components/settings/primitives/SettingsGroup.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
fail() { echo "Settings search in-place navigation: FAIL: $*" >&2; exit 1; }

# Search highlights the entire path and leaves the query active while navigating.
grep -Fq 'root.host.settingsSearchNavigationGroupHasMatches(modelData.id)' "$NAV" || fail 'navigation group matching outline is missing'
grep -Fq 'settingsSearchMatched: root.host.settingsSearchPageHasMatches(parent.modelData.id)' "$NAV" || fail 'page matching outline is missing'
grep -Fq 'settingsSearchMatched: root.host && root.host.settingsSearchSubTabHasMatches(root.host.currentPageId, index)' "$PAGE_HOST" || fail 'subtab matching outline is missing'
grep -Fq 'root.settingsSearchQuery = String(query === undefined || query === null ? "" : query)' "$CONTROLLER" || fail 'query state is not retained'
grep -Fq 'root.host.currentPageId = entry.pageId' "$CONTROLLER" || fail 'search result does not route to its stable page ID'
NAV_BLOCK="$(sed -n '/function openSettingsSearchResult(entry)/,/function handleSettingsSearchKey(event)/p' "$CONTROLLER")"
! grep -Fq 'settingsSearchQuery = ""' <<<"$NAV_BLOCK" || fail 'page navigation clears the active search query'
grep -Fq 'root.host.currentPageSubTabIndex = subTabIndex' <<<"$NAV_BLOCK" || fail 'search result does not open the matching inner subtab'
grep -Fq 'Qt.callLater(function()' <<<"$NAV_BLOCK" || fail 'subtab navigation is not deferred until the page is loaded'
grep -Fq 'root.host.currentPageId === pageId' <<<"$NAV_BLOCK" || fail 'deferred subtab navigation is not guarded against page changes'
! grep -Fq 'settingsSearchPopup' "$WIDGET" || fail 'floating result popup is still present'

# Searchable controls and their ancestor groups have a persistent outline while the query is active.
for primitive in SettingsInputField SettingsCheckBox SettingsComboBox SettingsNumberField SettingsColorField SettingsFontField; do
    grep -Fq 'settingsSearchHighlighted' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive cannot show an in-place match outline"
done
grep -Fq 'property bool settingsSearchHighlighted: false' "$GROUP" || fail 'section frame is not searchable by ancestry'
grep -Fq 'settingsSearchSubTabIndex:' "$GROUP" || fail 'section frames do not store subtab routing metadata'

# The outline color is a real Settings Window preference, not a hard-coded accent.
grep -Fq 'settingsSearchHighlightColor' "$ROOT/Config.qml" || fail 'Config has no search highlight color'
grep -Fq 'settingsSearchHighlightColor:' "$ROOT/js/settings/SettingsDefaults.js" || fail 'default search highlight color is missing'
grep -Fq 'settingsSearchHighlightColor: String(config.settingsSearchHighlightColor)' "$ROOT/js/settings/SettingsPersistence.js" || fail 'search highlight color is not persisted'
grep -Fq 'settingsSearchHighlightColor' "$ROOT/js/settings/SettingsApplyCore.js" || fail 'search highlight color is not restored'
grep -Fq 'settingsSearchHighlightColor' "$ROOT/js/settings/SettingsProfiles.js" || fail 'settings-window profiles do not own search highlight color'
grep -Fq 'settingsSearchHighlightColor' "$ROOT/js/settings/SettingsResets.js" || fail 'settings-window profile reset does not restore search highlight color'
grep -Fq 'Цвет рамки совпадений поиска' "$WINDOW" || fail 'color selector is missing from Settings Window'
grep -Fq 'settingsSearchHighlightBorderWidth' "$ROOT/Config.qml" || fail 'Config has no search highlight border width'
grep -Fq 'settingsSearchHighlightBorderWidth:' "$ROOT/js/settings/SettingsDefaults.js" || fail 'default search highlight border width is missing'
grep -Fq 'settingsSearchHighlightBorderWidth: config.settingsSearchHighlightBorderWidth' "$ROOT/js/settings/SettingsPersistence.js" || fail 'search highlight border width is not persisted'
grep -Fq 'settingsSearchHighlightBorderWidth' "$ROOT/js/settings/SettingsApplyCore.js" || fail 'search highlight border width is not restored'
grep -Fq 'settingsSearchHighlightBorderWidth' "$ROOT/js/settings/SettingsProfiles.js" || fail 'settings-window profiles do not own search highlight border width'
grep -Fq 'settingsSearchHighlightBorderWidth' "$ROOT/js/settings/SettingsResets.js" || fail 'settings-window profile reset does not restore search highlight border width'
grep -Fq 'Толщина рамки совпадений' "$WINDOW" || fail 'border width selector is missing from Settings Window'
for primitive in SettingsCheckBox SettingsNumberField SettingsColorField SettingsFontField SettingsGroup; do
    grep -Fq 'SettingsSearchHighlight {' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive does not use the shared configurable outline"
done
for primitive in SettingsInputField SettingsComboBox SettingsTabBase; do
    grep -Fq 'Config.settingsSearchHighlightBorderWidth' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive does not use the configurable search border width"
done
grep -Fq 'Config.settingsSearchHighlightBorderWidth' "$ROOT/components/settings/primitives/SettingsSearchHighlight.qml" || fail 'shared search outline ignores the configurable border width'
grep -Fq 'Config.settingsSearchHighlightBorderWidth' "$NAV" || fail 'navigation group outlines do not use configurable border width'

MOPIDY_ICONS="$ROOT/components/settings/sections/mopidy/SettingsMopidyIconsSection.qml"
grep -Fq 'property int settingsSearchSubTabIndex: 2' "$MOPIDY_ICONS" || fail 'Mopidy Icons section has no subtab search index'
for icon_id in stopIconField refreshIconField openAddIconField addIconField shuffleIconField repeatIconField switchPlaylistIconField playlistDeleteIconField moveUpIconField moveDownIconField volumeIconField mutedIconField clearIconField; do
    grep -Fq "settingsSearchLabel: \"Иконка:" "$MOPIDY_ICONS" || fail 'Mopidy icon column is missing searchable labels'
done
[ "$(grep -c 'settingsSearchLabel: \"Иконка:' "$MOPIDY_ICONS")" -eq 13 ] || fail 'not all Mopidy icon fields have explicit search labels'

node - "$ROOT" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
function load(file, extra = {}) {
  let source = fs.readFileSync(path.join(root, file), 'utf8')
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/gm, '');
  const sandbox = { ...extra };
  vm.runInNewContext(source, sandbox, { filename: file });
  return sandbox;
}
const profiles = load('js/settings/SettingsProfiles.js');
if (!profiles.profileSavePathMatches({}, 'settingsWindow', null, ['settingsSearchHighlightColor', 'settingsSearchHighlightBorderWidth']))
  throw new Error('settings-window profile scope does not include search highlight preferences');
const persistence = load('js/settings/SettingsPersistence.js');
const snapshot = persistence.snapshotObject({ moduleNames: [], colorNames: [], weatherToken: '' }, {
  settingsSearchHighlightColor: '#42a5f5',
  settingsSearchHighlightBorderWidth: 4
});
if (snapshot.settingsSearchHighlightColor !== '#42a5f5')
  throw new Error('search highlight color did not survive the settings snapshot');
if (snapshot.settingsSearchHighlightBorderWidth !== 4)
  throw new Error('search highlight border width did not survive the settings snapshot');
const schema = load('js/settings/SettingsSchema.js');
const apply = load('js/settings/SettingsApplyCore.js', { Schema: schema });
const config = { settingsSearchHighlightColor: '#ffbf47', settingsSearchHighlightBorderWidth: 2 };
apply.apply({}, config, { settingsSearchHighlightColor: '#42a5f5', settingsSearchHighlightBorderWidth: 4 });
if (config.settingsSearchHighlightColor !== '#42a5f5')
  throw new Error('search highlight color did not restore from persisted settings');
if (config.settingsSearchHighlightBorderWidth !== 4)
  throw new Error('search highlight border width did not restore from persisted settings');
apply.apply({}, config, { settingsSearchHighlightBorderWidth: 99 });
if (config.settingsSearchHighlightBorderWidth !== 5)
  throw new Error('search highlight border width was not clamped to 5');
apply.apply({}, config, { settingsSearchHighlightBorderWidth: 0 });
if (config.settingsSearchHighlightBorderWidth !== 1)
  throw new Error('search highlight border width was not clamped to 1');
const resets = load('js/settings/SettingsResets.js');
const owner = {
  activeProfile: 'legacy', profiles: { legacy: {} },
  expandedProfileData: () => ({}),
  defaultConfig: { settingsSearchHighlightColor: '#ffbf47', settingsSearchHighlightBorderWidth: 2 },
  settingsGeometry: [1,2,3,4], settingsMonitorName: '',
  moduleBlurEnabled: {}, defaultModuleBlurEnabled: { settings: false },
  save() {}, resetUnavailable() {}
};
config.settingsSearchHighlightColor = '#42a5f5';
config.settingsSearchHighlightBorderWidth = 5;
resets.resetSettingsWindowFromProfile(owner, config);
if (config.settingsSearchHighlightColor !== '#ffbf47')
  throw new Error('legacy profile reset does not fall back to the default search highlight color');
if (config.settingsSearchHighlightBorderWidth !== 2)
  throw new Error('legacy profile reset does not fall back to the default search highlight border width');
console.log('Search path outlines, profile persistence, restore and legacy reset: OK');
NODE

echo 'settings search in-place navigation: OK'
