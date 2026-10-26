#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const cavaPath = path.join(root, 'components/settings/sections/SettingsCavaSection.qml');
const widgetPath = path.join(root, 'components/settings/SettingsWidget.qml');
const cava = fs.readFileSync(cavaPath, 'utf8');
const widget = fs.readFileSync(widgetPath, 'utf8');

function blockContaining(source, token, pos) {
  const start = source.lastIndexOf(token, pos);
  assert(start >= 0, `parent block found for ${token}`);
  const open = source.indexOf('{', start);
  let depth = 0, quote = null, escaped = false, lineComment = false, blockComment = false;
  for (let i = open; i < source.length; i++) {
    const c = source[i], n = source[i + 1] || '';
    if (lineComment) { if (c === '\n') lineComment = false; continue; }
    if (blockComment) { if (c === '*' && n === '/') { blockComment = false; i++; } continue; }
    if (quote) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === quote) quote = null;
      continue;
    }
    if (c === '/' && n === '/') { lineComment = true; i++; continue; }
    if (c === '/' && n === '*') { blockComment = true; i++; continue; }
    if (c === '"' || c === "'") { quote = c; continue; }
    if (c === '{') depth++;
    else if (c === '}' && --depth === 0) return {start, end: i + 1, text: source.slice(start, i + 1)};
  }
  throw new Error(`unbalanced block for ${token}`);
}

const placement = [
  ['Режим CAVA', 0],
  ['Скрывать полоски без звука', 0],
  ['Скрывать пустые полоски', 0],
  ['Частота обновления CAVA (FPS)', 0],
  ['Количество полос CAVA', 1],
  ['Зазор между слотами CAVA', 1],
  ['Ширина полоски (% слота)', 1],
];
for (const [label, subtab] of placement) {
  const at = cava.indexOf(`text: "${label}"`);
  assert(at >= 0, `CAVA setting exists: ${label}`);
  assert.strictEqual(cava.indexOf(`text: "${label}"`, at + 1), -1, `CAVA setting appears once: ${label}`);
  const row = blockContaining(cava, 'Row {', at).text;
  assert(row.includes(`host.currentOtherTab === 4 && host.currentOtherSubTab === ${subtab}`), `${label} is displayed in the correct CAVA subtab ${subtab}`);
}

// Every CAVA config setting must have a visible UI control in exactly one expected row.
for (const key of ['cavaMode', 'cavaHideWhenSilent', 'cavaHideZeroBars', 'cavaFramerate', 'cavaBars', 'cavaRowSpacing', 'cavaBarWidthRatio']) {
  assert(cava.includes(`Config.${key}`) || cava.includes(`targetProperty: "${key}"`), `CAVA setting has a control: ${key}`);
}

const expectedCavaKeys = ['cavaMode', 'cavaHideWhenSilent', 'cavaHideZeroBars', 'cavaFramerate', 'cavaBars', 'cavaRowSpacing', 'cavaBarWidthRatio'].sort();
const config = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');
const configCavaKeys = [...config.matchAll(/^\s*property \w+ (cava[A-Z]\w*)\s*:/gm)].map(m => m[1]).sort();
assert.deepStrictEqual(configCavaKeys, expectedCavaKeys, 'every CAVA Config property has an audited UI placement');
for (const file of ['js/settings/SettingsDefaults.js', 'js/settings/SettingsPersistence.js', 'js/settings/SettingsResets.js']) {
  const body = fs.readFileSync(path.join(root, file), 'utf8');
  for (const key of expectedCavaKeys) assert(body.includes(key), `${file} handles ${key}`);
}
assert.strictEqual((cava.match(/targetProperty: "cavaBars"/g) || []).length, 1, 'bar count has exactly one field');

// The frame scopes must follow the same division as the visible settings.
const groups = [...cava.matchAll(/SettingsGroup\s*\{/g)].map(m => blockContaining(cava, 'SettingsGroup {', m.index).text);
const mainGroup = groups.find(g => g.includes('currentOtherSubTab === 0'));
const barsGroup = groups.find(g => g.includes('currentOtherSubTab === 1'));
assert(mainGroup && barsGroup, 'both CAVA framed subtabs exist');
const mainChangeKeys = mainGroup.match(/changeKeys:\s*\(\{ keys: \[([^\]]+)\] \}\)/);
const barsChangeKeys = barsGroup.match(/changeKeys:\s*\(\{ keys: \[([^\]]+)\] \}\)/);
assert(mainChangeKeys && barsChangeKeys, 'both CAVA frames declare exact change-key scopes');
const keys = s => [...s.matchAll(/"([^"]+)"/g)].map(m => m[1]);
assert.deepStrictEqual(keys(mainChangeKeys[1]).sort(), ['cavaFramerate', 'cavaHideWhenSilent', 'cavaHideZeroBars', 'cavaMode'].sort(), 'Main frame only tracks Main settings');
assert.deepStrictEqual(keys(barsChangeKeys[1]).sort(), ['cavaBars', 'cavaBarWidthRatio', 'cavaRowSpacing'].sort(), 'Bars frame tracks bar count, spacing and width');

// The sidebar dirty-marker map must agree with those exact settings scopes.
const start = widget.indexOf('    function settingsSubTabChangeSpec(tab, sub) {');
const end = widget.indexOf('\n    function settingsSubTabHasChanges', start);
assert(start >= 0 && end > start, 'subtab change-selector function found');
const context = {root: {}};
vm.createContext(context);
vm.runInContext(widget.slice(start, end).trim() + '\nthis.spec = settingsSubTabChangeSpec;', context);
const mainSpec = context.spec(4, 0);
const barsSpec = context.spec(4, 1);
assert(mainSpec && barsSpec, 'CAVA subtab marker scopes exist');
assert.deepStrictEqual([...mainSpec.keys].sort(), ['cavaFramerate', 'cavaHideWhenSilent', 'cavaHideZeroBars', 'cavaMode'].sort(), 'Main subtab marker tracks Main controls');
assert.deepStrictEqual([...barsSpec.keys].sort(), ['cavaBars', 'cavaBarWidthRatio', 'cavaRowSpacing'].sort(), 'Bars subtab marker tracks Bars controls');
console.log('CAVA settings placement and dirty-indicator scopes: OK');
JS
