#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
SEARCH="$ROOT/components/settings/SettingsSearchController.qml"
fail() { echo "Settings navigation component extraction: FAIL: $*" >&2; exit 1; }

[[ -f "$NAV" ]] || fail 'SettingsNavigation.qml is missing'
grep -Fq 'SettingsNavigation {' "$WIDGET" || fail 'SettingsWidget does not mount the navigation component'
grep -Fq 'host: root' "$WIDGET" || fail 'navigation host is not passed explicitly'
grep -Fq 'navigationGroups: root.settingsNavigationGroups' "$WIDGET" || fail 'navigation groups are not passed explicitly'
grep -Fq 'searchQuery: root.settingsSearchQuery' "$WIDGET" || fail 'search query is not passed explicitly'
grep -Fq 'searchResults: root.settingsSearchResults' "$WIDGET" || fail 'search results are not passed explicitly'
grep -Fq 'onSearchQueryEdited: query => root.updateSettingsSearchResults(query)' "$WIDGET" || fail 'query edits are not emitted to the host'
grep -Fq 'settingsSearchController.searchInput = settingsNavigation.searchInput' "$WIDGET" || fail 'search controller is not connected to the extracted field after component creation'
grep -Fq 'property alias searchInput: settingsSearchInput' "$NAV" || fail 'component does not expose the search input'
grep -Fq 'signal searchQueryEdited(string query)' "$NAV" || fail 'component does not expose query edits'
grep -Fq 'model: root.navigationGroups' "$NAV" || fail 'group rendering is not owned by the extracted component'
grep -Fq 'root.host.settingsNavigationGroupCollapsed(modelData.id)' "$NAV" || fail 'collapse state is routed through host API'
grep -Fq 'root.host.settingsSearchNavigationGroupMatchCount(modelData.id)' "$NAV" || fail 'group counters are not connected through host API'
grep -Fq 'root.host.settingsSearchPageMatchCount(parent.modelData.id)' "$NAV" || fail 'page counters are not connected through host API'
grep -Fq 'ScrollBar.vertical: SettingsScrollBar' "$NAV" || fail 'navigation scroll bar was not extracted'
! grep -Fq 'id: mainSettingsTabs' "$WIDGET" || fail 'old inline sidebar still remains in SettingsWidget'
! grep -Fq 'id: settingsSearchInput' "$WIDGET" || fail 'search input remains duplicated in SettingsWidget'
grep -Fq 'width: parent.width - settingsNavigation.width - 16' "$WIDGET" || fail 'page content width does not use the component width'

node - "$WIDGET" "$NAV" "$SEARCH" <<'NODE'
const assert = require('assert');
const fs = require('fs');
for (const file of process.argv.slice(2)) {
  const source = fs.readFileSync(file, 'utf8');
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let state = 'code', escaped = false;
  for (let i=0;i<source.length;i++) {
    const c=source[i], n=source[i+1];
    if(state==='line'){if(c==='\n')state='code';continue;}
    if(state==='block'){if(c==='*'&&n==='/'){state='code';i++;}continue;}
    if(['single','double','template'].includes(state)){
      if(escaped){escaped=false;continue;}
      if(c==='\\'){escaped=true;continue;}
      if((state==='single'&&c==="'")||(state==='double'&&c==='"')||(state==='template'&&c==='`'))state='code';
      continue;
    }
    if(c==='/'&&n==='/'){state='line';i++;continue;}
    if(c==='/'&&n==='*'){state='block';i++;continue;}
    if(c==="'"){state='single';continue;} if(c==='"'){state='double';continue;} if(c==='`'){state='template';continue;}
    if('([{'.includes(c))stack.push(c); else if(pairs[c])assert.strictEqual(stack.pop(),pairs[c],`${file}: unbalanced ${c}`);
  }
  assert.deepStrictEqual(stack,[],`${file}: unclosed delimiters`);
  assert.strictEqual(state,'code',`${file}: unterminated lexical state`);
}
NODE

echo 'Settings navigation component extraction and explicit host API: OK'
