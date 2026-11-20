#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Settings search match hints: FAIL: $*" >&2; exit 1; }
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
WIDGET="$ROOT/components/settings/SettingsNavigation.qml"
PAGE_HOST="$ROOT/components/settings/SettingsPageHost.qml"

# Match explanations are exposed by controls. Overlay-based controls delegate the
# hover explanation to the shared SettingsSearchHighlight primitive.
for primitive in SettingsGroup SettingsNumberField SettingsColorField SettingsFontField SettingsInputField SettingsCheckBox SettingsComboBox SettingsTabBase; do
    file="$ROOT/components/settings/primitives/$primitive.qml"
    grep -Fq 'settingsSearchMatchHint' "$file" || fail "$primitive has no match-hint property"
done
for primitive in SettingsNumberField SettingsColorField SettingsFontField SettingsCheckBox; do
    grep -Fq 'SettingsSearchHighlight {' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive does not use the shared hover explanation"
done
for primitive in SettingsInputField SettingsComboBox SettingsTabBase; do
    file="$ROOT/components/settings/primitives/$primitive.qml"
    grep -Fq 'ToolTip.visible' "$file" || fail "$primitive has no hover explanation"
    grep -Fq 'ToolTip.text: root.settingsSearchMatchHint' "$file" || fail "$primitive does not display the explanation text"
done
grep -Fq 'ToolTip.text: root.matchHint' "$ROOT/components/settings/primitives/SettingsSearchHighlight.qml" || fail 'shared highlight does not display the explanation text'
grep -Fq 'root.host.settingsSearchNavigationGroupMatchHint(modelData.id)' "$WIDGET" || fail 'navigation group tooltip does not describe matches'
grep -Fq 'root.host.settingsSearchPageMatchHint(parent.modelData.id)' "$WIDGET" || fail 'page tab tooltip does not describe matches'
grep -Fq 'settingsSearchSubTabMatchHint(root.host.currentPageId, index)' "$PAGE_HOST" || fail 'subtab tooltip does not describe matches'
grep -Fq 'SettingsSearch.explainMatch(entry, root.settingsSearchQuery)' "$CONTROLLER" || fail 'matched controls do not receive a semantic explanation'
grep -Fq 'function settingsSearchMatchesHint(predicate)' "$CONTROLLER" || fail 'ancestor hints are not summarized'
grep -Fq 'ToolTip.visible: root.settingsSearchHighlighted' "$ROOT/components/settings/primitives/SettingsGroup.qml" || fail 'group match hint is not limited to its heading'

node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsSearch.js'), 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const api = {};
vm.runInNewContext(source, api, {filename: 'SettingsSearch.js'});
const entry = {
  label: 'Интервал обновления',
  keywords: 'частота запроса',
  targetKey: 'weatherNowIntervalMinutes',
  keyTerms: 'weatherNowIntervalMinutes погода температура прогноз ветер',
  pageLabel: 'Погода',
  pageId: 'weather',
  group: 'Основные параметры',
  navigationGroupLabel: 'Модули'
};
const cases = [
  ['интервал', 'название'],
  ['частота', 'поисковая метка'],
  ['weather', 'имя параметра'],
  ['погода', 'страница'],
  ['ветер', 'синоним']
];
for (const [query, expected] of cases) {
  const hint = api.explainMatch(entry, query);
  if (!hint.includes(expected)) throw new Error(`${query}: expected ${expected}, got ${hint}`);
}
const result = api.search([{...entry, searchText:'Интервал обновления частота запроса weatherNowIntervalMinutes погода температура прогноз ветер Погода Основные параметры Модули'}], 'погода', 10);
if (result.length !== 1) throw new Error('search result compatibility regressed');
console.log('Search explanation categories (label, keyword, parameter, page, synonym): 5/5');
NODE

echo 'settings search match hints: OK'
