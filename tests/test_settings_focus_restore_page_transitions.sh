#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAV_CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"
PAGE_HOST="$ROOT/components/settings/SettingsPageHost.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
SEARCH="$ROOT/components/settings/SettingsSearchController.qml"
TAB="$ROOT/components/settings/primitives/SettingsTabBase.qml"

node - "$NAV_CONTROLLER" "$PAGE_HOST" "$WIDGET" "$SEARCH" "$TAB" <<'NODE'
const fs = require('fs');
const assert = require('assert');
const [navController, pageHost, widget, search, tab] = process.argv.slice(2).map(p => fs.readFileSync(p, 'utf8'));
function body(source, name) {
  const start = source.indexOf(`function ${name}(`);
  assert(start >= 0, `missing ${name}`);
  const open = source.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < source.length; i++) {
    if (source[i] === '{') depth++;
    else if (source[i] === '}' && --depth === 0) return source.slice(open + 1, i);
  }
  throw new Error(`unterminated ${name}`);
}
const selectPage = body(navController, 'selectSettingsTab');
assert(!selectPage.includes('clearSettingsFocus'), 'page navigation must not discard focus from the invoking sidebar control');
assert(selectPage.includes('root.currentPageId = pageId'), 'page navigation still changes the selected stable page ID');
assert(tab.includes('root.forceActiveFocus(Qt.MouseFocusReason)'), 'mouse activation focuses the clicked navigation control before routing');
assert(tab.includes('root.clicked()'), 'keyboard activation routes through the same focused navigation control');
const selectSubTab = body(pageHost, 'resetScroll');
assert(selectSubTab.includes('otherFlick.contentY = 0'), 'page host retains its scroll reset helper');
const subtabHandler = pageHost.slice(pageHost.indexOf('onClicked: {'), pageHost.indexOf('\n                        }', pageHost.indexOf('onClicked: {')));
assert(subtabHandler.includes('root.host.currentPageSubTabIndex = index'), 'subtab selection still updates the active index');
assert(!subtabHandler.includes('clearSettingsFocus'), 'subtab transition must retain focus on the selected subtab');
assert(subtabHandler.includes('root.resetScroll()'), 'subtab transition still resets page scroll');
assert(search.includes('root.host.focusSettingsNavigationPage(pageId)'), 'search-result navigation keeps its explicit destination focus');
const weather = body(widget, 'openWeatherSettings');
assert(weather.includes('root.focusSettingsNavigationPage("weather")'), 'programmatic weather navigation restores focus to the weather sidebar item');
assert(weather.includes('Qt.callLater'), 'programmatic focus waits until the destination navigation item is visible');
console.log('Settings focus restoration: page and subtab transitions retain invoking controls; search and programmatic routing focus their destination');
NODE

echo 'settings focus restore across page transitions: OK'
