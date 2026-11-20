#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherAppSearch.js"
APP_MODEL="$ROOT/components/launcher/models/AppModel.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ parseSpecialQuery, scoreEntry })');

const fuzzy = (value, query) => {
  value = String(value ?? '').toLowerCase();
  query = String(query ?? '').toLowerCase();
  if (!query) return -1;
  if (value === query) return 10000;
  if (value.startsWith(query)) return 9000 - value.length;
  if (value.includes(query)) return 8000 - value.indexOf(query);
  let pos = 0;
  for (const ch of query) {
    pos = value.indexOf(ch, pos);
    if (pos < 0) return -1;
    pos += 1;
  }
  return 1000 - pos;
};

const app = {
  id: 'org.example.Terminal.desktop',
  name: 'Alacritty',
  categories: ['System', 'TerminalEmulator'],
  comment: 'GPU accelerated terminal emulator',
  execString: 'alacritty --config-file %f',
  startupClass: 'Alacritty',
  genericName: 'Terminal',
  keywords: ['shell', 'console', 'command line'],
  runInTerminal: false
};
const terminalApp = { ...app, id: 'org.example.Tui.desktop', name: 'TUI Manager', runInTerminal: true };

const cases = [
  ['@i org.example', 'org.example.Terminal.desktop'],
  ['@c terminalemulator', 'System TerminalEmulator'],
  ['@d accelerated terminal', 'GPU accelerated terminal emulator'],
  ['@e config-file', 'alacritty --config-file %f'],
  ['@w alacritty', 'Alacritty'],
  ['@g terminal', 'Terminal'],
  ['@k console', 'shell console command line']
];
for (const [input, expected] of cases) {
  const parsed = api.parseSpecialQuery(input);
  assert(parsed, `${input} should parse as a special query`);
  assert(api.scoreEntry(app, parsed, fuzzy) >= 0, `${input} should match the expected metadata`);
}

const terminalQuery = api.parseSpecialQuery('@t tui');
assert(terminalQuery && terminalQuery.terminalOnly, '@t must set the terminal-only flag');
assert(api.scoreEntry(terminalApp, terminalQuery, fuzzy) >= 0, '@t should match apps marked Terminal=true');
assert.strictEqual(api.scoreEntry(app, terminalQuery, fuzzy), -1, '@t must exclude applications without Terminal=true');

assert.strictEqual(api.scoreEntry(app, api.parseSpecialQuery('@c'), fuzzy), -1, 'bare selectors must not list all applications');
assert.strictEqual(api.parseSpecialQuery('@cat firefox'), null, 'selector codes require a whitespace boundary');
assert.strictEqual(api.parseSpecialQuery('@x firefox'), null, 'unknown selector codes stay ordinary search');
assert.strictEqual(api.parseSpecialQuery('firefox'), null, 'ordinary queries are not special searches');

// QML list-like fields may not be native arrays; searchValue must still read them.
const listLike = { 0: 'Graphics', 1: 'Utility', length: 2 };
const listQuery = api.parseSpecialQuery('@c utility');
assert(api.scoreEntry({ ...app, categories: listLike }, listQuery, fuzzy) >= 0, 'list-like Qt metadata must be searchable');
JS

python3 - "$APP_MODEL" "$LAUNCHER" <<'PY'
from pathlib import Path
import sys
app_model = Path(sys.argv[1]).read_text()
launcher = Path(sys.argv[2]).read_text()
assert 'LauncherAppSearch.js' in app_model
assert 'readonly property var specialSearch: LauncherAppSearch.parseSpecialQuery(root.query)' in app_model
assert 'LauncherAppSearch.scoreEntry(' in app_model
assert 'if (appModel.specialSearch)\n            return results' in launcher
assert 'appModel.specialSearch.query' in launcher
expected_hints = '@i ID\\n@c category\\n@d description\\n@e command\\n@w WM_CLASS\\n@g generic name\\n@k keywords\\n@t apps inside terminal'
assert expected_hints in launcher, 'metadata filter hints must be displayed one per line'
hint_start = launcher.index('text: "' + expected_hints + '"')
hint_block_start = launcher.rfind('Text {', 0, hint_start)
hint_block_end = launcher.index('\n                }', hint_start)
hint_block = launcher[hint_block_start:hint_block_end]
assert 'anchors.centerIn: contentArea' in hint_block, 'metadata hints block must remain centered in the content area'
assert 'width: Math.min(implicitWidth, Math.max(0, contentArea.width - 48))' in hint_block, 'metadata hints should use a compact centered text block'
assert 'horizontalAlignment: Text.AlignLeft' in hint_block, 'metadata hint lines must be left-aligned'
assert 'horizontalAlignment: Text.AlignHCenter' not in hint_block, 'metadata hint text must not be center-aligned'
assert '@i ID · @c category' not in launcher
assert '@t terminal apps' not in launcher
print('Launcher @ application metadata search integration: OK')
PY
