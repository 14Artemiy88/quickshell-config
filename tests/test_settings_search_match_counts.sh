#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
FOLDER="$ROOT/components/settings/primitives/SettingsNavigationFolder.qml"
PAGE_HOST="$ROOT/components/settings/SettingsPageHost.qml"
TAB_BASE="$ROOT/components/settings/primitives/SettingsTabBase.qml"
fail() { echo "Settings search match counts: FAIL: $*" >&2; exit 1; }

for method in settingsSearchCountMatches settingsSearchPageMatchCount settingsSearchNavigationGroupMatchCount settingsSearchSubTabMatchCount; do
    grep -Fq "function $method(" "$CONTROLLER" || fail "$method is missing from the search controller"
done
for method in settingsSearchPageMatchCount settingsSearchNavigationGroupMatchCount settingsSearchSubTabMatchCount; do
    grep -Fq "function $method(" "$WIDGET" || fail "$method is not exposed by SettingsWidget"
done
grep -Fq 'settingsSearchMatchCount: root.host.settingsSearchPageMatchCount(parent.modelData.id)' "$NAV" || fail 'page match count is not bound to sidebar page tabs'
grep -Fq 'settingsSearchMatchCount: root.host' "$PAGE_HOST" || fail 'subtab match count is not bound'
grep -Fq 'property int settingsSearchMatchCount: 0' "$TAB_BASE" || fail 'shared tab primitive has no match count property'
grep -Fq 'Config.settingsSearchMatchCountFontSize' "$TAB_BASE" || fail 'shared tab count font does not use configured size'
grep -Fq 'Config.settingsSearchMatchCountFontSize' "$FOLDER" || fail 'sidebar group count font does not use configured size'
grep -Fq 'root.settingsSearchMatchCount > 0' "$TAB_BASE" || fail 'match count is not conditionally displayed'
grep -Fq 'searchMatchCount: root.host.settingsSearchNavigationGroupMatchCount(groupId)' "$NAV" || fail 'navigation group count is not passed to the folder primitive'
grep -Fq 'root.searchMatchCount > 0' "$FOLDER" || fail 'navigation folder primitive does not render the count'

node - "$ROOT" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const rootPath = process.argv[2];
const controllerPath = path.join(rootPath, 'components/settings/SettingsSearchController.qml');
const source = fs.readFileSync(controllerPath, 'utf8');
const start = source.indexOf('    function settingsSearchCountMatches(');
const end = source.indexOf('    function settingsSearchMatchesHint(', start);
if (start < 0 || end < 0) throw new Error('Cannot locate search count methods');
const methods = source.slice(start, end);
const controller = {
  settingsSearchQuery: 'icon',
  settingsSearchResults: [
    { pageId: 'mopidy', subTabIndex: 2 },
    { pageId: 'mopidy', subTabIndex: 2 },
    { pageId: 'mopidy', subTabIndex: 1 },
    { pageId: 'weather', subTabIndex: 0 },
    { pageId: 'weather', subTabIndex: 2 }
  ]
};
const context = {
  root: controller,
  SettingsPageRegistry: {
    navigationGroupIdForTabId: id => id === 'weather' || id === 'mopidy' ? 'modules' : 'appearance'
  }
};
vm.runInNewContext(methods, context, { filename: 'SettingsSearchController-counts.js' });
for (const name of [
  'settingsSearchCountMatches', 'settingsSearchPageMatchCount',
  'settingsSearchNavigationGroupMatchCount', 'settingsSearchSubTabMatchCount',
  'settingsSearchPageHasMatches', 'settingsSearchNavigationGroupHasMatches',
  'settingsSearchSubTabHasMatches'
]) controller[name] = context[name];
if (controller.settingsSearchPageMatchCount('mopidy') !== 3) throw new Error('Mopidy page count is wrong');
if (controller.settingsSearchNavigationGroupMatchCount('modules') !== 5) throw new Error('Modules group count is wrong');
if (controller.settingsSearchSubTabMatchCount('mopidy', 2) !== 2) throw new Error('Mopidy icons subtab count is wrong');
if (controller.settingsSearchSubTabMatchCount('mopidy', 1) !== 1) throw new Error('Mopidy other subtab count is wrong');
if (!controller.settingsSearchSubTabHasMatches('mopidy', 2)) throw new Error('Subtab match predicate is inconsistent');
if (controller.settingsSearchPageMatchCount('missing') !== 0) throw new Error('Missing page should have no matches');
console.log('Search counts by group, page and subtab: OK');
NODE

echo 'settings search match counts: OK'
