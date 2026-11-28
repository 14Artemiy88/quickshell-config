#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PAGE="$ROOT/components/settings/sections/SettingsOsdSection.qml"
CONTENT="$ROOT/components/settings/SettingsPageContent.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"
PROFILE_SAVE="$ROOT/js/settings/SettingsProfiles.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
SETTINGS="$ROOT/Settings.qml"
CHECK="$ROOT/CHECK.sh"
for file in "$PAGE" "$CONTENT" "$REGISTRY" "$NAV" "$PROFILES" "$RESETS" "$SETTINGS" "$CHECK"; do
  test -f "$file" || { echo "OSD settings page test: missing $file" >&2; exit 1; }
done
python3 - "$ROOT" <<'PYCODE'
from pathlib import Path
import sys
root = Path(sys.argv[1])
page = (root / "components/settings/sections/SettingsOsdSection.qml").read_text(encoding="utf-8")
content = (root / "components/settings/SettingsPageContent.qml").read_text(encoding="utf-8")
registry = (root / "js/settings/SettingsPageRegistry.js").read_text(encoding="utf-8")
nav = (root / "components/settings/SettingsNavigationController.qml").read_text(encoding="utf-8")
settings = (root / "Settings.qml").read_text(encoding="utf-8")
player_page = (root / "components/settings/pages/SettingsPlayerPage.qml").read_text(encoding="utf-8")
volume = (root / "components/settings/sections/SettingsVolumeSection.qml").read_text(encoding="utf-8")
notifications = (root / "components/settings/sections/SettingsNotificationsSection.qml").read_text(encoding="utf-8")
check = (root / "CHECK.sh").read_text(encoding="utf-8")

keys = [
    "volumeOsdEnabled", "volumeOsdHideDelay", "volumeOsdAnimationDuration", "animationVolumeOsdMorphProfile",
    "playerOsdEnabled", "playerOsdHideDelay", "playerOsdAnimationDuration", "animationPlayerOsdMorphProfile",
    "notificationsDndOsdEnabled", "notificationsDndOsdHideDelay", "notificationsDndOsdAnimationDuration", "animationNotificationsDndOsdMorphProfile",
]
checks = {
    "OSD is a page in the Modules navigation group": '{ id: "osd", defaultLabel: "OSD", groupId: "modules"' in registry,
    "page has three clearly separated modes": 'subTabs: ["Громкость", "Плеер", "Не беспокоить"]' in registry and all(f'selectedMode === {i}' in page for i in range(3)),
    "page is wired into the shared settings content": 'SettingsOsdSection {' in content and 'settings-search-page:osd' in content,
    "page is searchable with mode-specific aliases": 'osd: [' in registry and all(k in registry for k in ["экранный индикатор громкости", "экранный индикатор плеера", "индикатор dnd"]),
    "old Player OSD settings are no longer duplicated": 'SettingsPlayerOsdSection' not in player_page and 'playerOsdEnabled' not in player_page,
    "old Volume OSD settings are no longer duplicated": 'volumeOsdEnabled' not in volume and 'volumeOsdHideDelay' not in volume,
    "old DND OSD settings are no longer duplicated": 'notificationsDndOsdEnabled' not in notifications and 'notificationsDndOsdHideDelay' not in notifications,
    "each OSD subtab tracks only its four OSD keys": '"osd": [' in nav and all(k in nav for k in keys),
    "OSD has a dedicated Reset action": 'case "osd": settings.resetOsdSettings(); break' in nav and 'function resetOsdSettings()' in settings,
    "OSD has an independent Save/Reset availability scope": 'if (scope === "osd")' in settings and 'hasPrefixed(["volumeOsd"' in settings and '"volume", "osd", "calendar"' in settings,
    "old page-level dirty scopes explicitly exclude moved OSD keys": all(k in settings for k in ['if (scope === "player")', 'if (scope === "volume")', 'if (scope === "notifications")', '"playerOsdEnabled"', '"volumeOsdEnabled"', '"notificationsDndOsdEnabled"']),
    "OSD audit test is registered in CHECK": 'test_osd_settings_page.sh' in check,
}
for label, ok in checks.items():
    if not ok:
        raise SystemExit(f"Missing OSD settings page behavior: {label}")
print("OSD settings page structure, routing, deduplication and shared controls: OK")
PYCODE
node - "$PROFILES" "$RESETS" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
function load(path, exportName, names) {
  const source = fs.readFileSync(path, 'utf8').replace(/^\.pragma library\s*/m, '');
  const context = {};
  vm.createContext(context);
  vm.runInContext(source + `\nthis.${exportName} = {${names.join(',')}};`, context);
  return context[exportName];
}
const profiles = load(process.argv[2], 'api', ['profileSavePathMatches', 'modulePathMatches']);
const matches = profiles.profileSavePathMatches;
const moduleMatches = profiles.modulePathMatches;
const owner = {};
const osdKeys = [
  'volumeOsdEnabled', 'volumeOsdHideDelay', 'volumeOsdAnimationDuration', 'animationVolumeOsdMorphProfile',
  'playerOsdEnabled', 'playerOsdHideDelay', 'playerOsdAnimationDuration', 'animationPlayerOsdMorphProfile',
  'notificationsDndOsdEnabled', 'notificationsDndOsdHideDelay', 'notificationsDndOsdAnimationDuration', 'animationNotificationsDndOsdMorphProfile',
];
for (const key of osdKeys) assert.strictEqual(matches(owner, 'osd', null, [key]), true, `${key} belongs to OSD Save scope`);
for (const key of ['volumeUpdateInterval', 'playerShowRemainingTime', 'notificationsDoNotDisturb', 'notificationsHistoryLimit'])
  assert.strictEqual(matches(owner, 'osd', null, [key]), false, `${key} must stay outside OSD Save scope`);
for (const [scope, osdKey, ordinaryKey] of [
  ['volume', 'volumeOsdEnabled', 'volumeUpdateInterval'],
  ['player', 'playerOsdEnabled', 'playerFont'],
  ['notifications', 'notificationsDndOsdEnabled', 'notificationsDoNotDisturb'],
]) {
  assert.strictEqual(matches(owner, scope, null, [osdKey]), false, `${osdKey} is no longer part of the ${scope} page Save scope`);
  assert.strictEqual(matches(owner, scope, null, [ordinaryKey]), true, `${ordinaryKey} remains in the ${scope} page Save scope`);
}
for (const [moduleName, osdKey, ordinaryKey] of [
  ['volumes', 'volumeOsdEnabled', 'volumeUpdateInterval'],
  ['player', 'playerOsdEnabled', 'playerFont'],
  ['notifications', 'notificationsDndOsdEnabled', 'notificationsDoNotDisturb'],
]) {
  assert.strictEqual(moduleMatches([osdKey], moduleName), false, `${osdKey} is no longer part of the ${moduleName} module reset scope`);
  assert.strictEqual(moduleMatches([ordinaryKey], moduleName), true, `${ordinaryKey} remains in the ${moduleName} module reset scope`);
}

const resets = load(process.argv[3], 'api', ['resetOsdSettings', 'resetVolumeSettings', 'resetPlayerSettings', 'resetNotificationsSettings']);
const profile = Object.fromEntries(osdKeys.map((key, i) => [key, i + 100]));
const config = Object.fromEntries(osdKeys.map(key => [key, -1]));
config.volumeUpdateInterval = 777;
let saveCount = 0;
const resetOwner = {
  activeProfile: 'main', profiles: { main: profile },
  expandedProfileData: () => profile,
  save: () => { saveCount++; },
  resetUnavailable: () => { throw new Error('unexpected unavailable profile'); },
};
resets.resetOsdSettings(resetOwner, config);
for (const key of osdKeys) assert.strictEqual(config[key], profile[key], `${key} restored from active profile`);
assert.strictEqual(config.volumeUpdateInterval, 777, 'non-OSD setting is not changed by OSD reset');
assert.strictEqual(saveCount, 1, 'reset persists once');

// Older or partial profile snapshots should restore the same OSD defaults
// through the dedicated OSD page rather than through source-module resets.
const fallbackDefaults = {
  volumeOsdEnabled: true, volumeOsdHideDelay: 1400, volumeOsdAnimationDuration: 180, animationVolumeOsdMorphProfile: 'ease-out',
  playerOsdEnabled: true, playerOsdHideDelay: 3200, playerOsdAnimationDuration: 220, animationPlayerOsdMorphProfile: 'ease-out',
  notificationsDndOsdEnabled: true, notificationsDndOsdHideDelay: 1800, notificationsDndOsdAnimationDuration: 180, animationNotificationsDndOsdMorphProfile: 'ease-out',
};
const partialProfile = { volumeOsdEnabled: false };
const fallbackConfig = Object.fromEntries(osdKeys.map(key => [key, 'changed']));
const fallbackOwner = {
  activeProfile: 'legacy', profiles: { legacy: partialProfile },
  expandedProfileData: () => partialProfile, defaultConfig: fallbackDefaults, save() {}, resetUnavailable() {},
};
resets.resetOsdSettings(fallbackOwner, fallbackConfig);
assert.strictEqual(fallbackConfig.volumeOsdEnabled, false, 'explicit false in a legacy profile remains authoritative');
for (const key of osdKeys.slice(1)) assert.strictEqual(fallbackConfig[key], fallbackDefaults[key], `${key} receives the default missing from a legacy profile`);

// Legacy source-page resets must leave the moved OSD settings untouched.
const mixedProfile = Object.assign({}, profile, { volumeUpdateInterval: 123, playerFont: 'Profile Player', notificationsDoNotDisturb: true });
const sharedOwner = {
  activeProfile: 'main', profiles: { main: mixedProfile }, expandedProfileData: () => mixedProfile,
  defaultConfig: Object.assign({}, profile), geometry: {}, save() {},
};
const volumeConfig = Object.assign({}, profile, { volumeOsdEnabled: 'osd-kept', volumeUpdateInterval: -5 });
resets.resetVolumeSettings(sharedOwner, volumeConfig);
assert.strictEqual(volumeConfig.volumeOsdEnabled, 'osd-kept', 'Volume reset leaves OSD state alone');
assert.strictEqual(volumeConfig.volumeUpdateInterval, 123, 'Volume reset still restores Volume-specific settings');
const playerConfig = Object.assign({}, profile, { playerOsdEnabled: 'osd-kept', playerFont: 'changed' });
resets.resetPlayerSettings(sharedOwner, playerConfig);
assert.strictEqual(playerConfig.playerOsdEnabled, 'osd-kept', 'Player reset leaves OSD state alone');
assert.strictEqual(playerConfig.playerFont, 'Profile Player', 'Player reset still restores Player-specific settings');
const notificationConfig = Object.assign({}, profile, { notificationsDndOsdEnabled: 'osd-kept', notificationsDoNotDisturb: false });
resets.resetNotificationsSettings(sharedOwner, notificationConfig);
assert.strictEqual(notificationConfig.notificationsDndOsdEnabled, 'osd-kept', 'Notifications reset leaves DND OSD state alone');
assert.strictEqual(notificationConfig.notificationsDoNotDisturb, true, 'Notifications reset still restores DND mode');
console.log('OSD profile Save scope, active-profile Reset isolation and legacy page-reset isolation: OK');
NODE
node - "$PAGE" "$CONTENT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
for (const file of process.argv.slice(2)) {
  const source = fs.readFileSync(file, 'utf8');
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let state = 'code', escaped = false;
  for (let i = 0; i < source.length; i++) {
    const c = source[i], n = source[i + 1];
    if (state === 'line') { if (c === '\n') state = 'code'; continue; }
    if (state === 'block') { if (c === '*' && n === '/') { state = 'code'; i++; } continue; }
    if (state === 'single' || state === 'double') {
      if (escaped) { escaped = false; continue; }
      if (c === '\\') { escaped = true; continue; }
      if ((state === 'single' && c === "'") || (state === 'double' && c === '"')) state = 'code';
      continue;
    }
    if (c === '/' && n === '/') { state = 'line'; i++; continue; }
    if (c === '/' && n === '*') { state = 'block'; i++; continue; }
    if (c === "'") { state = 'single'; continue; }
    if (c === '"') { state = 'double'; continue; }
    if ('([{'.includes(c)) stack.push(c);
    else if (pairs[c]) assert.strictEqual(stack.pop(), pairs[c], `${file}: unbalanced ${c}`);
  }
  assert.deepStrictEqual(stack, [], `${file}: unclosed QML delimiters`);
  assert.notStrictEqual(state, 'single', `${file}: unterminated single-quoted string`);
  assert.notStrictEqual(state, 'double', `${file}: unterminated double-quoted string`);
}
console.log('OSD QML component and page assembly delimiters: balanced');
NODE
