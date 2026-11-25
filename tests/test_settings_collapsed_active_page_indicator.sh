#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"

node - "$WIDGET" "$NAV" "$REGISTRY" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [widgetPath, navPath, registryPath] = process.argv.slice(2);
const widget = fs.readFileSync(widgetPath, 'utf8');
const nav = fs.readFileSync(navPath, 'utf8');
const registrySource = fs.readFileSync(registryPath, 'utf8').replace(/^\.pragma library\s*$/gm, '');

function functionBody(source, name) {
  const token = `function ${name}(`;
  const start = source.indexOf(token);
  assert(start >= 0, `missing ${name}()`);
  const open = source.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < source.length; i++) {
    if (source[i] === '{') depth++;
    else if (source[i] === '}' && --depth === 0) return source.slice(open + 1, i);
  }
  throw new Error(`unterminated ${name}()`);
}

const registry = {};
vm.runInNewContext(registrySource, registry, { filename: registryPath });
const pages = registry.tabDefinitions();
const groups = registry.navigationGroupDefinitions();
const widgetGroups = groups.map(group => ({
  id: group.id,
  items: pages.filter(page => page.groupId === group.id).map(page => ({ id: page.id, label: page.defaultLabel }))
}));

const getLabel = new Function('id', 'root', functionBody(widget, 'settingsNavigationGroupCurrentPageLabel'));
const host = {
  currentPageId: 'weather',
  settingsNavigationGroups: widgetGroups,
  settingsTabLabelForId(id) {
    for (const group of widgetGroups)
      for (const item of group.items)
        if (item.id === id) return item.label;
    return 'Настройки';
  }
};
assert.strictEqual(getLabel('modules', host), 'Погода', 'collapsed Modules group must name its active page');
assert.strictEqual(getLabel('appearance', host), '', 'groups without the active page must not show a page hint');
host.currentPageId = 'player';
assert.strictEqual(getLabel('modules', host), 'Плеер', 'indicator follows the currently active page');
host.settingsNavigationGroups[1].items.find(item => item.id === 'player').label = 'Музыка';
assert.strictEqual(getLabel('modules', host), 'Музыка', 'indicator uses the current user-customized page label');

assert(nav.includes('readonly property bool collapsedWithCurrentPage'), 'delegate must derive the collapsed-active state');
assert(nav.includes('height: navigationGroupDelegate.collapsedWithCurrentPage ? 42 : 30'),
  'collapsed active group header must reserve room for the second line');
assert(nav.includes('anchors.bottomMargin: navigationGroupDelegate.collapsedWithCurrentPage ? 14 : 0'),
  'main header row must leave space for the active-page hint');
assert(nav.includes('visible: navigationGroupDelegate.collapsedWithCurrentPage'),
  'active-page hint must only appear when its group is collapsed and selected');
assert(nav.includes('text: "Активно: " + root.host.settingsNavigationGroupCurrentPageLabel(modelData.id)'),
  'collapsed group must display a clear active-page label');
assert(nav.includes('root.host.settingsNavigationGroupHasCurrentPage(modelData.id)\n                                    ? Config.accent : Config.baseColor'),
  'existing accent frame must continue to indicate the group with the active page when it is not keyboard-focused');
assert(widget.includes('function toggleSettingsNavigationGroup(id)'), 'group collapse remains an independent navigation action');
console.log('settings collapsed active-page indicator: group lookup, custom labels, visibility and header layout: OK');
NODE
