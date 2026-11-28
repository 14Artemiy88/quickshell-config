#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAYOUT="$ROOT/js/networks/NetworkLayout.js"
WIDGET="$ROOT/components/Networks.qml"
ROW="$ROOT/components/NetworkConnectionButton.qml"
SHELL="$ROOT/shell.qml"
for file in "$LAYOUT" "$WIDGET" "$ROW" "$SHELL"; do test -f "$file"; done

node - "$LAYOUT" <<'NODE'
const fs = require('fs')
const vm = require('vm')
const assert = require('assert')
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma\s+library\s*;?\s*/m, '')
const context = {}
vm.runInNewContext(source, context)
const natural = context.naturalHeight
const panel = context.panelHeight
assert.strictEqual(natural(0, 32, 4, 8, 32), 48, 'empty state should stay compact')
assert.strictEqual(natural(1, 32, 4, 8, 32), 48, 'one network should fit its row and padding')
assert.strictEqual(natural(2, 32, 4, 8, 32), 84, 'two networks should not reserve unused panel height')
assert.strictEqual(natural(3, 32, 4, 8, 32), 120, 'three networks should grow by one row plus spacing')
assert.strictEqual(natural(4, 32, 4, 8, 32), 156, 'four networks should fit within default maximum')
assert.strictEqual(natural(5, 32, 4, 8, 32), 192, 'natural height should still reflect all rows')
assert.strictEqual(panel(5, 171, 32, 4, 8, 32), 171, 'many rows should be capped by saved maximum height')
assert.strictEqual(panel(2, 70, 32, 4, 8, 32), 70, 'user-configured maximum height should be respected')
assert.strictEqual(panel(2, 0, 32, 4, 8, 32), 84, 'invalid maximum should use the default cap')
console.log('Networks content sizing: empty/one/two/many rows and max-height cap: OK')
NODE

grep -Fq 'contentHeight: networksContent.implicitHeight' "$SHELL"
grep -Fq 'maxContentHeight: Settings.geometry.networks[3]' "$SHELL"
grep -Fq 'implicitHeight: root.contentDrivenHeight' "$WIDGET"
grep -Fq 'ScrollBar.vertical.policy:' "$WIDGET"
grep -Fq 'ScrollBar.AsNeeded' "$WIDGET"
grep -Fq 'Нет сохранённых подключений' "$WIDGET"
grep -Fq 'leftPadding: root.effectiveHorizontalPadding' "$WIDGET"
grep -Fq 'rightPadding: root.effectiveHorizontalPadding' "$WIDGET"
grep -Fq 'topPadding: root.effectiveVerticalPadding' "$WIDGET"
grep -Fq 'bottomPadding: root.effectiveVerticalPadding' "$WIDGET"
grep -Fq 'implicitHeight: 32' "$ROW"
! grep -Fq 'height: 180' "$WIDGET"

echo 'Networks compact content-driven frame, spacing and overflow behavior: OK'
