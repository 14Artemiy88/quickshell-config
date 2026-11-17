#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
CONTENT="$ROOT/components/settings/SettingsPageContent.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
PLAYER_PAGE="$ROOT/components/settings/pages/SettingsPlayerPage.qml"
MOPIDY_PAGE="$ROOT/components/settings/pages/SettingsMopidyPage.qml"
SEARCH_CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"

grep -Fq 'SettingsPageContent {' "$WIDGET"
grep -Fq 'host: root' "$WIDGET"
grep -Fq 'settings: root.settings' "$WIDGET"
grep -Fq 'function resetScroll()' "$CONTENT"
grep -Fq 'settingsPageContent.resetScroll()' "$WIDGET"
! grep -Eq 'Settings(Modules|Colors|Calendar|Weather|General|Player|Cava|CpuRam|Network|Volume|Timers|Launcher|Window|Notifications).*Section[[:space:]]*\{' "$WIDGET"
grep -Fq 'SettingsPages.SettingsPlayerPage {' "$CONTENT"
grep -Fq 'SettingsPages.SettingsMopidyPage {' "$CONTENT"
grep -Fq 'SettingsPageHost {' "$CONTENT"

node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const widget = fs.readFileSync(path.join(root, 'components/settings/SettingsWidget.qml'), 'utf8');
const content = fs.readFileSync(path.join(root, 'components/settings/SettingsPageContent.qml'), 'utf8');
const registry = fs.readFileSync(path.join(root, 'js/settings/SettingsPageRegistry.js'), 'utf8');
const playerPage = fs.readFileSync(path.join(root, 'components/settings/pages/SettingsPlayerPage.qml'), 'utf8');
const mopidyPage = fs.readFileSync(path.join(root, 'components/settings/pages/SettingsMopidyPage.qml'), 'utf8');
const searchController = fs.readFileSync(path.join(root, 'components/settings/SettingsSearchController.qml'), 'utf8');
const navigationController = fs.readFileSync(path.join(root, 'components/settings/SettingsNavigationController.qml'), 'utf8');
const pageSources = content + playerPage + mopidyPage;
for (const page of ['modules','themes','calendar','weather','general','player','mopidy','cava','cpuRam','network','volume','timers','launcher','settingsWindow','notifications']) {
  assert(pageSources.includes(`settings-search-page:${page}`), `${page} search root remains discoverable`);
}
const navigation = fs.readFileSync(path.join(root, 'components/settings/SettingsNavigationController.qml'), 'utf8');
assert(widget.includes('property alias currentPageId: settingsNavigationController.currentPageId'), 'stable page ID is exposed by SettingsWidget');
assert(navigation.includes('property string currentPageId: "modules"'), 'stable page ID state is owned by navigation controller');
assert(content.includes('host: root.host'), 'page sections receive the settings controller explicitly');
assert(content.includes('root.host.currentPageId'), 'page declarations route through stable controller IDs');
assert(registry.includes('function tabDefinitions'), 'page registry remains the source of page metadata');
assert(widget.includes('settingsSearchController.rebuildSettingsSearchIndex()'), 'SettingsWidget delegates index rebuilding to the search controller');
assert(searchController.includes('root.collectSettingsSearchItems(treeRoot, "", null'), 'search controller still traverses the complete widget tree');
for (const source of [widget, content, playerPage, mopidyPage, searchController, navigationController]) {
  const stack = [];
  const match = {')':'(',']':'[','}':'{'};
  let mode='code', escaped=false;
  for (let i=0;i<source.length;i++) {
    const c=source[i], n=source[i+1];
    if (mode==='line') { if(c==='\n') mode='code'; continue; }
    if (mode==='block') { if(c==='*'&&n==='/'){mode='code';i++;} continue; }
    if (mode==='single'||mode==='double'||mode==='template') {
      if(escaped){escaped=false;continue;}
      if(c==='\\'){escaped=true;continue;}
      if((mode==='single'&&c==="'")||(mode==='double'&&c==='"')||(mode==='template'&&c==='`')) mode='code';
      continue;
    }
    if(c==='/'&&n==='/'){mode='line';i++;continue;}
    if(c==='/'&&n==='*'){mode='block';i++;continue;}
    if(c==="'"){mode='single';continue;} if(c==='"'){mode='double';continue;} if(c==='`'){mode='template';continue;}
    if(c==='('||c==='['||c==='{') stack.push(c);
    else if(match[c]) assert.strictEqual(stack.pop(),match[c],`unbalanced ${c}`);
  }
  assert.deepStrictEqual(stack,[], 'unclosed delimiters in settings component');
  assert(!['line','block','single','double','template'].includes(mode), `unterminated ${mode}`);
}
NODE

echo 'Settings page content extraction: stable-ID routing, searchable page roots and balanced QML delimiters: OK'
