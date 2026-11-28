#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];

const layoutSource = fs.readFileSync(root + '/js/launcher/LauncherKeyboardLayout.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const KeyboardLayout = vm.runInNewContext(layoutSource + '\n({ alternateLayoutQuery, scoreWithLayout, bestMatchingQuery })');

const sharedSource = fs.readFileSync(root + '/js/utils/ApplicationSearch.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');
const sharedContext = vm.createContext({ KeyboardLayout });
vm.runInContext(sharedSource + '\nthis.api = { valuesOf, searchValue, fuzzyScoreCore, fuzzyScoreNative, fuzzyScore };', sharedContext);

const launcherSource = fs.readFileSync(root + '/js/launcher/LauncherAppSearch.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');
const launcherContext = vm.createContext({ ApplicationSearch: sharedContext.api });
vm.runInContext(launcherSource + '\nthis.api = { valuesOf, fuzzyScore, parseSpecialQuery, scoreEntry, scoreApplication, buildApplicationResults, buildApplicationEntries, collectCategories };', launcherContext);

const notificationSource = fs.readFileSync(root + '/js/notifications/NotificationAppSearch.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');
const catalogSource = fs.readFileSync(root + '/js/notifications/NotificationAppCatalog.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/gm, '');
const catalogContext = vm.createContext({});
vm.runInContext(catalogSource + '\nthis.api = { valuesOf, cleanText, normalized, copyStrings, desktopEntrySnapshot, makeSenderEntry, upsertSender, ruleIds, canonicalRuleIds, uniqueLegacyRuleIds, uniqueRuleIds, matchesAnyRule, isAmbiguousAppName, normalizeDndRuleIds, mergeConfiguredEntries };', catalogContext);
const notificationContext = vm.createContext({ LauncherAppSearch: launcherContext.api, NotificationAppCatalog: catalogContext.api });
vm.runInContext(notificationSource + '\nthis.api = { buildRows };', notificationContext);
const buildRows = notificationContext.api.buildRows;

const entries = [
  { id: 'org.mozilla.firefox.desktop', name: 'Firefox', genericName: 'Web Browser', comment: 'Browse the web', keywords: ['Internet', 'Browser'], categories: ['Network', 'WebBrowser'], runInTerminal: false },
  { id: 'org.telegram.desktop', name: 'Telegram', genericName: 'Messenger', comment: 'Chat with friends', keywords: ['Chat'], categories: ['Network'], runInTerminal: false },
  { id: 'org.kde.dolphin', name: 'Dolphin', genericName: 'File Manager', comment: 'Manage files and folders', keywords: ['Files', 'Folders'], categories: ['System', 'FileManager'], runInTerminal: false },
  { id: 'org.example.terminal', name: 'Alacritty', genericName: 'Terminal', comment: 'GPU terminal emulator', keywords: ['Shell', 'Console'], categories: ['System', 'TerminalEmulator'], runInTerminal: true },
  { id: 'com.transmissionbt.Transmission', name: 'Transmission', genericName: 'BitTorrent Client', comment: 'Download and share files over BitTorrent', keywords: ['torrent', 'download'], categories: ['Network', 'FileTransfer'], runInTerminal: false },
  { id: 'org.example.btop', name: 'btop', genericName: 'Resource Monitor', comment: 'System resource monitor', keywords: ['monitor', 'system'], categories: ['System', 'Monitor'], runInTerminal: true }
];

function ids(rows) { return Array.from(rows, row => row.id); }

assert.deepStrictEqual(ids(buildRows(entries, [], [], '', 40, true, [])), [],
  'empty query hides unconfigured installed apps');
assert.deepStrictEqual(ids(buildRows(entries, ['org.telegram.desktop'], ['org.kde.dolphin'], '', 40, true, [])),
  ['org.kde.dolphin', 'org.telegram.desktop'],
  'empty query keeps only configured apps and both independent rules');
assert.deepStrictEqual(ids(buildRows(entries, [], [], '', 40, true, [], true)),
  entries.map(entry => entry.id).sort((a, b) => {
    const an = entries.find(entry => entry.id === a).name;
    const bn = entries.find(entry => entry.id === b).name;
    return an.localeCompare(bn);
  }), 'Показать все reveals all observed notification senders for an empty query');

const notifySend = { id: 'notify-send', name: 'notify-send', appName: 'notify-send', desktopEntry: '', comment: '', genericName: '', keywords: [], categories: [] };
assert.deepStrictEqual(ids(buildRows([notifySend], 'n;o;t;i;f;y;-;s;e;n;d', '', '', 40, true, [])), [],
  'old character-split notify-send rules are cleaned instead of showing one configured row per character');
assert.deepStrictEqual(ids(buildRows([notifySend], 'n;o;t;i;f;y;-;s;e;n;d', '', '', 40, true, [], true)),
  ['notify-send'], 'Show All reveals the real notify-send sender after legacy character fragments are removed');
assert.deepStrictEqual(ids(buildRows([notifySend], '', '', 'notify-send', 40, true, [])),
  ['notify-send'], 'observed notify-send remains searchable regardless of the empty-query Show All option');

// These are the Launcher AppModel semantics: full query is scored against
// each supported field independently; query words are not split across fields.
assert.deepStrictEqual(ids(buildRows(entries, [], [], 'firefox', 40, true, [])),
  ['org.mozilla.firefox.desktop'], 'exact app-name search matches');
assert.deepStrictEqual(ids(buildRows(entries, [], [], 'fire', 40, true, [])),
  ['org.mozilla.firefox.desktop'], 'short prefix query returns Firefox only, never Transmission or btop');
assert.deepStrictEqual(ids(buildRows(entries, [], [], 'fire', 40, true, [])),
  Array.from(launcherContext.api.buildApplicationEntries(entries, 'fire', true, [], [], {}, [], 8), entry => entry.id),
  'DND result list is the exact ordered Launcher app result list');
assert.deepStrictEqual(ids(buildRows(entries, [], [], 'browser', 40, true, [])),
  ['org.mozilla.firefox.desktop'], 'Generic Name and keywords match as in Launcher');
assert.deepStrictEqual(ids(buildRows(entries, [], [], 'Dolphin manager', 40, true, [])), [],
  'multi-word text is scored as one query and is not split across unrelated fields');
assert.deepStrictEqual(ids(buildRows(entries, [], [], 'org.kde.dolphin', 40, true, [])), [],
  'desktop ID is not searched by default, matching Launcher');
assert.deepStrictEqual(ids(buildRows(entries, [], [], '@i org.kde.dolphin', 40, true, [])),
  ['org.kde.dolphin'], 'desktop IDs are searched using the Launcher @i selector');
assert.deepStrictEqual(ids(buildRows(entries, [], [], '@c terminalemulator', 40, true, [])),
  ['org.example.terminal'], 'category metadata search uses the Launcher @c selector');
const categoryBrowser = buildRows(entries, [], [], '@c', 40, true, []);
assert.strictEqual(categoryBrowser.length > 0, true, 'bare @c opens the same category browser as Launcher');
assert(categoryBrowser.every(row => row.kind === 'category'), 'bare @c returns category entries, not app checkboxes');
assert.deepStrictEqual(ids(buildRows(entries, [], [], '@t alacritty', 40, true, [])),
  ['org.example.terminal'], 'terminal-only search uses the Launcher @t selector');
assert.deepStrictEqual(ids(buildRows(entries, [], [], '@t firefox', 40, true, [])), [],
  'terminal-only search excludes non-terminal applications');

const libreOfficeEntry = { id: 'org.libreoffice.LibreOffice', name: 'LibreOffice', genericName: 'Office Suite', comment: 'Office productivity suite', keywords: ['documents', 'spreadsheet'], categories: ['Office', 'WordProcessor'], runInTerminal: false };
const entriesWithLibreOffice = entries.concat([libreOfficeEntry]);
const launcherHiddenIds = ['org.libreoffice.LibreOffice'];
assert.deepStrictEqual(ids(buildRows(entries, [], [], 'libreoffice', 40, true, [])),
  [], 'installed applications do not appear until they have sent a notification');
assert.deepStrictEqual(ids(buildRows(entriesWithLibreOffice, [], [], 'libreoffice', 40, true, [])),
  ['org.libreoffice.LibreOffice'], 'an app becomes searchable after its notification sender is observed');
assert.deepStrictEqual(
  Array.from(launcherContext.api.buildApplicationEntries(entriesWithLibreOffice, 'libreoffice', true, [], launcherHiddenIds, {}, [], 8), entry => entry.id),
  [], 'Launcher-only hidden preferences remain scoped to Launcher');

const fuzzyMatches = ids(buildRows(entries, [], [], 'ff', 40, true, []));
assert(fuzzyMatches.includes('org.mozilla.firefox.desktop'), 'fuzzy mode matches non-contiguous letters as Launcher does');
assert.strictEqual(fuzzyMatches[0], 'org.mozilla.firefox.desktop', 'higher-scoring app name ranks ahead of incidental metadata matches');
assert.deepStrictEqual(ids(buildRows(entries, [], [], 'ff', 40, false, [])), [],
  'strict mode follows launcherFuzzySearchApps and rejects subsequences');
assert.deepStrictEqual(ids(buildRows(entries, [], [], 'ащч', 40, true, [])),
  ['org.mozilla.firefox.desktop'], 'keyboard-layout correction matches Launcher');

const favoriteMatches = ids(buildRows(entries, [], [], 't', 40, true, ['org.telegram.desktop']));
assert.strictEqual(favoriteMatches[0], 'org.telegram.desktop',
  'Launcher favorites are pinned ahead of score-ranked search results');


const sameNameEntries = [
  { id: 'org.example.mail-a', desktopEntry: 'org.example.mail-a', appName: 'Mail', name: 'Mail A', genericName: 'Mail', comment: 'Sender A' },
  { id: 'org.example.mail-b', desktopEntry: 'org.example.mail-b', appName: 'Mail', name: 'Mail B', genericName: 'Mail', comment: 'Sender B' }
];
const sameNameRows = buildRows(sameNameEntries, ['Mail'], [], '', 40, true, [], true);
const mailARow = sameNameRows.find(row => row.id === 'org.example.mail-a');
const mailBRow = sameNameRows.find(row => row.id === 'org.example.mail-b');
const ambiguousLegacyRow = sameNameRows.find(row => row.id === 'Mail');
assert.strictEqual(mailARow.allowed, false, 'ambiguous appName rule does not check the first desktop-backed row');
assert.strictEqual(mailBRow.allowed, false, 'ambiguous appName rule does not check the second desktop-backed row');
assert.deepStrictEqual(Array.from(mailARow.ruleIds), ['org.example.mail-a'], 'DND checkbox writes only the canonical desktop ID');
assert.strictEqual(mailARow.legacyRuleIds.length, 0, 'shared appName aliases are excluded from migration actions');
assert.strictEqual(ambiguousLegacyRow.unusableRule, true, 'ambiguous alias row is marked unsafe');
const ambiguousNameOnly = { id: 'Mail', desktopEntry: '', appName: 'Mail', name: 'Mail', comment: '', genericName: '', keywords: [], categories: [] };
const nameOnlyRows = buildRows(sameNameEntries.concat([ambiguousNameOnly]), ['Mail'], [], '', 40, true, [], false);
const ambiguousNameOnlyRow = nameOnlyRows.find(row => row.id === 'Mail');
assert(ambiguousNameOnlyRow && ambiguousNameOnlyRow.unusableRule, 'an observed name-only sender with colliding desktop IDs remains a visible but disabled configured row');
assert.strictEqual(nameOnlyRows.filter(row => row.id === 'Mail').length, 1, 'ambiguous name-only rule is not duplicated by a configured-only placeholder');
const uniqueLegacyRows = buildRows([sameNameEntries[0]], ['Mail'], [], '', 40, true, []);
assert.strictEqual(uniqueLegacyRows[0].allowed, true, 'unique legacy appName alias remains checked');
assert.deepStrictEqual(Array.from(uniqueLegacyRows[0].ruleIds), ['org.example.mail-a'], 'unique legacy alias migrates toward canonical desktop ID');
assert.deepStrictEqual(Array.from(uniqueLegacyRows[0].legacyRuleIds), ['Mail'], 'only the unique legacy alias is removed when the canonical rule is toggled');
const historyOnlyRows = buildRows([sameNameEntries[0]], [], [], '', 40, true, [], false, ['Mail']);
assert.strictEqual(historyOnlyRows.length, 1, 'history-only configured application remains visible when Show All is off');
assert.strictEqual(historyOnlyRows[0].historyIgnored, true, 'history-ignore rule is independently represented on the app row');
assert.strictEqual(historyOnlyRows[0].allowed, false, 'history-ignore does not enable Ignore DND');
assert.strictEqual(historyOnlyRows[0].blocked, false, 'history-ignore does not enable Disable');
const section = fs.readFileSync(root + '/components/settings/sections/SettingsNotificationsSection.qml', 'utf8');
assert(section.includes('NotificationAppSearch.buildRows('), 'DND app list uses its row builder');
assert(section.includes('Config.notificationsSeenSenders || []'), 'DND app search uses only the runtime observed-sender catalog');
assert(!section.includes('DesktopEntries.applications.values'), 'DND does not browse the whole installed catalog');
assert(section.includes('Config.launcherFuzzySearchApps !== false'), 'DND follows the Launcher fuzzy-search setting');
assert(section.includes('LauncherAppPreferences.normalizeIds(Config.launcherFavoriteApps || [])'), 'DND follows Launcher favorite ordering');
assert(section.includes('function setDndApplicationRule(kind, appIds, enabled, legacyAliases)'), 'DND rule edits distinguish canonical IDs from legacy appName aliases');
assert(section.includes('LauncherAppPreferences.setId(allowed, aliases[a], false)'), 'allow-rule toggle removes only uniquely mapped legacy aliases before writing canonical IDs');
assert(section.includes('LauncherAppPreferences.setId(blocked, aliases[b], false)'), 'block-rule toggle removes only uniquely mapped legacy aliases before writing canonical IDs');
assert(section.includes('LauncherAppPreferences.setId(historyIgnored, aliases[h], false)'), 'history rule edits migrate aliases independently');
assert(section.includes('root.setDndApplicationRule("history"'), 'third per-app checkbox edits history exclusion only');
assert(section.includes('enabled: modelData.unusableRule !== true'), 'ambiguous name-only senders cannot receive an unsafe rule');
assert(!section.includes('Config.launcherHiddenApps'), 'DND does not inherit Launcher-only hidden-app preferences');
assert(section.includes('onTextEdited: root.dndApplicationSearch = text'), 'search uses direct user-edit events');
assert(section.includes('property bool dndShowAllApplications: false'), 'show-all starts disabled by default');
assert(section.includes('root.dndShowAllApplications,'), 'the show-all toggle affects empty-query list generation');
assert(section.includes('text: "Показать все"'), 'DND search row exposes a Show All checkbox');
assert(section.includes('function migrateLegacyDndCharacterRules()'), 'DND removes previously persisted character-split rule artifacts on load');
assert(section.includes('Component.onCompleted: Qt.callLater(root.migrateLegacyDndCharacterRules)'), 'legacy DND rule cleanup runs on section startup');
assert(section.includes('root.dndApplicationSearch = "@c " + modelData.category'), 'choosing a category converts the query into a Launcher-style @c filter');
assert(section.includes('@i ID\\n@c category'), 'DND shows the same special search selector hints as Launcher');

const notificationModule = fs.readFileSync(root + '/js/notifications/NotificationAppSearch.js', 'utf8');
assert(notificationModule.includes('NotificationAppCatalog.mergeConfiguredEntries('), 'previously configured rules remain manageable after restart');
const notificationCatalogModule = fs.readFileSync(root + '/js/notifications/NotificationAppCatalog.js', 'utf8');
assert(notificationCatalogModule.includes('function upsertSender('), 'sender catalog is deduplicated and updated by notification identity');
assert(notificationModule.includes('LauncherAppSearch.buildApplicationResults('),
  'DND delegates the complete result-building pipeline to the Launcher app-search primitive');
const appModel = fs.readFileSync(root + '/components/launcher/models/AppModel.qml', 'utf8');
assert(appModel.includes('LauncherAppSearch.buildApplicationEntries('), 'Launcher AppModel uses the same complete result builder');
console.log('DND / Launcher application matching, ranking, special selectors, fuzzy setting and empty state: OK');
JS
