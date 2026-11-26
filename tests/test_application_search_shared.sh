#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];

function loadLibrary(relativePath, imports) {
  const source = fs.readFileSync(root + '/' + relativePath, 'utf8')
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/gm, '');
  const context = { ...imports };
  vm.createContext(context);
  vm.runInContext(source, context, { filename: relativePath });
  return context;
}

const keyboardLayout = loadLibrary('js/launcher/LauncherKeyboardLayout.js', {});
const keyboardApi = {
  scoreWithLayout: keyboardLayout.scoreWithLayout,
  alternateLayoutQuery: keyboardLayout.alternateLayoutQuery
};
const applicationSearch = loadLibrary('js/utils/ApplicationSearch.js', { KeyboardLayout: keyboardApi });
const launcherSearch = loadLibrary('js/launcher/LauncherAppSearch.js', { ApplicationSearch: applicationSearch });
const notificationAppCatalog = loadLibrary('js/notifications/NotificationAppCatalog.js', {});
const notificationsSearch = loadLibrary('js/notifications/NotificationAppSearch.js', { LauncherAppSearch: launcherSearch, NotificationAppCatalog: notificationAppCatalog });

const entries = [
  { id: 'org.mozilla.firefox.desktop', name: 'Firefox', genericName: 'Web Browser', comment: 'Browse the web', keywords: ['Internet', 'Browser'], categories: ['Network', 'WebBrowser'], runInTerminal: false },
  { id: 'org.telegram.desktop', name: 'Telegram', genericName: 'Messenger', comment: 'Chat with friends', keywords: ['Chat'], categories: ['Network'], runInTerminal: false },
  { id: 'org.kde.dolphin', name: 'Dolphin', genericName: 'File Manager', comment: 'Manage files and folders', keywords: ['Files', 'Folders'], categories: ['System', 'FileManager'], runInTerminal: false },
  { id: 'com.transmissionbt.Transmission', name: 'Transmission', genericName: 'BitTorrent Client', comment: 'Download and share files over BitTorrent', keywords: ['torrent', 'download'], categories: ['Network', 'FileTransfer'], runInTerminal: false },
  { id: 'org.example.btop', name: 'btop', genericName: 'Resource Monitor', comment: 'System resource monitor', keywords: ['monitor', 'system'], categories: ['System', 'Monitor'], runInTerminal: true }
];

assert.strictEqual(applicationSearch.valuesOf(entries).length, entries.length, 'native JS arrays are supported');
const qmlListLike = { length: entries.length, ...Object.fromEntries(entries.map((entry, index) => [index, entry])) };
assert.strictEqual(Array.isArray(qmlListLike), false, 'fixture represents a QML list-like value');
assert.strictEqual(applicationSearch.valuesOf(qmlListLike).length, entries.length, 'QML/Qt list-like catalogs are converted');
assert.strictEqual(applicationSearch.searchValue({ 0: 'Files', 1: 'Folders', length: 2 }), 'Files Folders', 'list-like metadata values are searchable');

const fuzzy = launcherSearch.fuzzyScore;
assert(fuzzy('Firefox', 'ff', true) >= 0, 'fuzzy mode keeps Launcher subsequence behavior');
assert.strictEqual(fuzzy('Firefox', 'ff', false), -1, 'strict mode follows Launcher preference');
assert(fuzzy('Firefox', 'ащч', true) >= 0, 'keyboard-layout correction is shared');

// Verify that the extracted canonical helper retains the former AppModel
// field weights and whole-query matching semantics.
function previousAppModelScore(entry, query, enabled) {
  query = String(query ?? '').toLowerCase().trim();
  if (!query) return 0;
  let score = -1;
  score = Math.max(score, fuzzy(entry.name, query, enabled));
  score = Math.max(score, fuzzy(entry.genericName, query, enabled) - 100);
  score = Math.max(score, fuzzy(entry.comment, query, enabled) - 200);
  if (entry.keywords) {
    for (const keyword of entry.keywords) score = Math.max(score, fuzzy(keyword, query, enabled) - 150);
  }
  return score;
}
for (const query of ['firefox', 'fir', 'browser', 'Dolphin manager', 'ff', 'ащч']) {
  for (const enabled of [true, false]) {
    for (const entry of entries) {
      assert.strictEqual(
        launcherSearch.scoreApplication(entry, query, enabled),
        previousAppModelScore(entry, query, enabled),
        `shared AppModel score remains identical for ${query} / fuzzy=${enabled} / ${entry.name}`
      );
    }
  }
}
assert(launcherSearch.scoreApplication(entries[0], '@i org.mozilla', true) >= 0, 'special metadata selectors remain available');
assert.strictEqual(launcherSearch.scoreApplication(entries[0], '@c', true), -1, 'bare special selectors show no app results');

const observedSenders = [entries[0], entries[3]];
const empty = notificationsSearch.buildRows(observedSenders, [], [], '', 40, true, []);
assert.strictEqual(empty.length, 0, 'DND empty query does not dump the installed catalog');
const configured = notificationsSearch.buildRows(observedSenders,
  ['org.telegram.desktop'], ['org.kde.dolphin'], '', 40, true, []);
assert.deepStrictEqual(Array.from(configured, row => row.id).sort(),
  ['org.kde.dolphin', 'org.telegram.desktop'].sort(), 'empty DND query keeps only apps with existing rules');
const searched = notificationsSearch.buildRows(observedSenders, [], [], 'fire', 40, true, []);
assert.deepStrictEqual(Array.from(searched, row => row.id), ['org.mozilla.firefox.desktop'],
  'a real-world short query must not leak unrelated Transmission/btop entries into DND');
const launcherEntries = launcherSearch.buildApplicationEntries(observedSenders, 'fire', true, [], [], {}, [], 8);
assert.deepStrictEqual(Array.from(searched, row => row.id),
  Array.from(launcherEntries, entry => entry.id),
  'DND and Launcher use the same complete result builder and produce the same ordered matches');
const unobservedInstalledAppSearch = notificationsSearch.buildRows(observedSenders, [], [], 'btop', 40, true, []);
assert.deepStrictEqual(Array.from(unobservedInstalledAppSearch, row => row.id), [],
  'DND does not show an installed app until it has actually sent a notification');

const section = fs.readFileSync(root + '/components/settings/sections/SettingsNotificationsSection.qml', 'utf8');
assert(section.includes('NotificationAppSearch.buildRows('), 'DND list uses the notification row adapter');
assert(section.includes('Config.launcherFuzzySearchApps !== false'), 'DND uses the Launcher fuzzy preference');
assert(section.includes('LauncherAppPreferences.normalizeIds(Config.launcherFavoriteApps || [])'), 'DND shares Launcher favorite ranking');
assert(!section.includes('Config.launcherHiddenApps'), 'DND does not inherit Launcher-only hidden-app filtering');
assert(section.includes('Config.notificationsSeenSenders || []'), 'DND catalog is populated by the notification server, not installed desktop entries');
assert(!section.includes('DesktopEntries.applications.values'), 'DND does not enumerate all installed applications');
const appModel = fs.readFileSync(root + '/components/launcher/models/AppModel.qml', 'utf8');
assert(appModel.includes('LauncherAppSearch.buildApplicationEntries('), 'Launcher AppModel uses the shared complete application-list primitive');
const notificationModule = fs.readFileSync(root + '/js/notifications/NotificationAppSearch.js', 'utf8');
assert(notificationModule.includes('LauncherAppSearch.buildApplicationResults('), 'DND uses the same complete application-list primitive as Launcher');
console.log('Shared application search: Launcher matching is reused over the DND observed-sender catalog: OK');
JS
