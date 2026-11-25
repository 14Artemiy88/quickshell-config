#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const read = name => fs.readFileSync(`${root}/${name}`, 'utf8');
const modules = read('components/settings/sections/SettingsModulesSection.qml');
const notificationsTab = read('components/settings/sections/SettingsNotificationsSection.qml');
const runtime = read('components/notifications/Notifications.qml');
const applySource = read('js/settings/SettingsApplyState.js').replace(/^\.pragma library\s*$/gm, '').replace(/^\.import .*$/gm, '');
const applyContext = {
  Schema: { normalizeCustomThemes: value => value || {}, normalizeSavedColor: (value, fallback) => value === undefined ? fallback : value },
  Profiles: { SPARSE_FORMAT: 'sparse-v1' },
  Themes: { builtinThemeNames: ['14 Theme'], palette: () => ({}) }
};
vm.createContext(applyContext);
vm.runInContext(applySource + '\nthis.apply = apply;', applyContext);
const owner = {
  geometry: { notifications: [30, 45, 380, 240] }, profiles: {}, customThemes: {}, activeProfile: '',
  activeTheme: '14 Theme', themeStateRevision: 0, loaded: false,
  rebuildProfileList() {}, changed() {}
};
const Config = { notificationsCardWidth: 460 };
applyContext.apply(owner, Config, { geometry: { notifications: [30, 45, 380, 240] } }, [], {}, {}, [], {});
assert.deepStrictEqual(Array.from(owner.geometry.notifications), [30, 45, 460, 240], 'legacy scalar width is promoted into the module geometry while custom height is retained');
assert(modules.includes('moduleRow.moduleName === "notifications"') && modules.includes('modulesSection.notificationsGeometryValue(index)'), 'notification dimensions use the same shared module geometry row as other modules');
assert(modules.includes('index === 2 ? 280') && modules.includes('index === 2 ? 600'), 'notification width remains bounded in the shared geometry editor');
assert(modules.includes('Максимальная высота окна; 0 — автоматически по содержимому'), 'height field documents automatic sizing');
assert(modules.includes('model: settings.moduleNames.filter(function(name) { return name !== \"dashboard\" })'), 'Notifications appears in the common Modules row repeater');
assert(!notificationsTab.includes('Ширина карточки') && !notificationsTab.includes('notificationsCardWidth'), 'width is no longer edited on Notifications content tab');
assert(runtime.includes('notificationMaxHeight') && runtime.includes('root.notificationMaxHeight > 0'), 'runtime applies the optional queue-height limit');
assert(runtime.includes('notificationCardWidth') && runtime.includes('Settings.geometry'), 'runtime reads the width from module geometry');
console.log('Notifications module size controls, legacy width migration, and runtime sizing: OK');
JS
