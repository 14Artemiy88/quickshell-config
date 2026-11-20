#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherSchemePicker.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ parseQuery, buildResults })');

for (const command of ['scheme', 'schemes', 'theme', 'themes', 'color-scheme', 'colour-scheme', 'палитра', 'тема', 'темы']) {
  assert.deepStrictEqual(api.parseQuery(command), { active: true, query: '' }, `${command} opens the scheme picker`);
  assert.deepStrictEqual(api.parseQuery(`${command} nord`), { active: true, query: 'nord' }, `${command} preserves a search term`);
}
assert.strictEqual(api.parseQuery('scheme-nord').active, false, 'command parsing requires a token boundary');
assert.strictEqual(api.parseQuery('ordinary query').active, false, 'ordinary input is not intercepted');

const score = (text, query) => {
  text = String(text).toLowerCase(); query = String(query).toLowerCase();
  if (!query) return 0;
  if (text === query) return 10000;
  if (text.startsWith(query)) return 9000 - text.length;
  if (text.includes(query)) return 8000 - text.indexOf(query);
  let pos = 0, result = 0;
  for (const ch of query) { const at = text.indexOf(ch, pos); if (at < 0) return -1; result += 100 - at; pos = at + 1; }
  return result;
};
const names = ['14 Theme', 'Catppuccin Mocha', 'Tokyo Night', 'Dracula', 'Nord', 'Custom Sunset', 'Nord'];
const preview = name => ['#112233', '#445566', '#778899', '#aabbcc', '#ddeeff', '#123456'];
const description = name => name === 'Custom Sunset' ? 'Пользовательская тёплая тема' : `${name} palette`;
let results = api.buildResults('', names, 'Dracula', preview, description, score, 100);
assert.strictEqual(results[0].name, 'Dracula', 'currently active theme is first when the query is empty');
assert.strictEqual(results.length, 6, 'duplicate names are removed without excluding custom themes');
assert(results[0].isActive, 'active theme is marked');
assert.strictEqual(results[0].colors.length, 6, 'each theme carries the six existing settings preview swatches');
assert(results.some(item => item.name === 'Custom Sunset'), 'custom themes are included');
assert(results.every(item => Array.isArray(item.colors) && item.colors.length === 6), 'preview colors are attached to each result');
results = api.buildResults('nord', names, 'Dracula', preview, description, score, 100);
assert.strictEqual(results.length, 1, 'search narrows the scheme list');
assert.strictEqual(results[0].name, 'Nord', 'search finds the requested theme');
results = api.buildResults('sunset', names, 'Dracula', preview, description, score, 100);
assert.strictEqual(results.length, 1, 'custom theme descriptions are searchable');
assert.strictEqual(results[0].name, 'Custom Sunset', 'custom theme description match returns the custom theme');
assert.strictEqual(api.buildResults('not-a-theme', names, 'Dracula', preview, description, score, 100).length, 0, 'unmatched themes are excluded');
assert.strictEqual(api.buildResults('', names, 'Dracula', preview, description, score, 1).length, 1, 'result limit is enforced');
console.log('Scheme picker aliases, fuzzy search, custom themes, swatches, active-theme ordering and limits: OK');
JS

python3 - "$LAUNCHER" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text()
assert 'LauncherSchemePicker.js" as LauncherSchemePicker' in source
assert 'LauncherSchemePicker.parseQuery(normalizedQuery)' in source
assert 'Settings.themeNames' in source and 'Settings.activeTheme' in source
assert 'Settings.themePreview(name)' in source and 'Settings.themeDescription(name)' in source
assert 'kind: "schemePickerAction"' in source and 'searchField.text = ">scheme"' in source
assert 'if (result.kind === "scheme")' in source and 'Settings.applyTheme(selectedName)' in source
assert 'case "scheme": return String(itemData.name || "")' in source
assert 'Текущая тема' in source and 'Выбрать цветовую тему' in source
assert 'Settings.themePreview(String(appDelegate.itemData.name || ""))' in source, 'scheme swatches should bind directly to the live Settings preview'
assert 'kind === "scheme"' in source and 'visible: appDelegate.itemData && appDelegate.itemData.kind === "scheme"' in source
assert 'delegate: Rectangle {' in source and 'width: 12' in source and 'height: 12' in source and 'radius: 6' in source, 'scheme swatches should render as larger 12px circles'
assert 'color: String(modelData || "transparent")' in source, 'scheme swatches should use actual preview colors'
assert 'Layout.preferredWidth: appDelegate.itemData && appDelegate.itemData.kind === "scheme" ? 87 : 0' in source, 'larger swatches should occupy a fixed visible slot beside the theme name'
assert 'Layout.preferredHeight: 14' in source, 'swatch row should have enough height for the larger circles'
assert 'appDelegate.itemData.colors' not in source, 'do not rely on color arrays copied through launcher result objects'
assert 'LauncherSchemePicker.parseQuery(searchField.text.replace(/^\\s*>\\s*/, "")).query' in source, 'scheme highlighting must ignore the command token'
assert 'selectedName !== String(Settings.activeTheme' in source, 'reselecting the current scheme must not reset user-modified colors'
print('Launcher scheme command, Settings singleton integration, preview rendering and safe activation: OK')
PY

echo 'Launcher scheme picker: OK'
