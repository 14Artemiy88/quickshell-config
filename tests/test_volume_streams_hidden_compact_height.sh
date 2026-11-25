#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT/js/volumes/VolumeLayout.js" "$ROOT/components/Volumes.qml" "$ROOT/shell.qml" <<'NODE'
const fs = require('fs')
const vm = require('vm')
const assert = require('assert')
const [helperPath, widgetPath, shellPath] = process.argv.slice(2)
const helper = fs.readFileSync(helperPath, 'utf8').replace(/^\.pragma\s+library\s*;?\s*/m, '')
const context = {}
vm.runInNewContext(helper, context)
const height = context.adaptiveHeight

// Collapsing streams must use only the main-control geometry, even when the
// source snapshot still contains stream delegates and the user min-height is high.
assert.strictEqual(height(false, 4, 56, 7, 240, 85, 1200), 56)
assert.strictEqual(height(false, 0, 56, 0, 0, 140, 1200), 56)
// An empty expanded list also should not reserve its stream minimum height.
assert.strictEqual(height(true, 0, 56, 0, 0, 140, 1200), 56)
// The minimum height remains effective when actual stream rows are visible.
assert.strictEqual(height(true, 1, 56, 7, 20, 100, 1200), 100)
assert.strictEqual(height(true, 2, 56, 7, 65, 85, 1200), 128)
// The maximum height still caps a long stream list.
assert.strictEqual(height(true, 12, 56, 7, 1800, 85, 600), 600)
// User-adjusted padding/main-row geometry is respected when collapsed.
assert.strictEqual(height(false, 3, 72, 7, 120, 85, 1200), 72)

const widget = fs.readFileSync(widgetPath, 'utf8')
const shell = fs.readFileSync(shellPath, 'utf8')
assert(widget.includes('import "../js/volumes/VolumeLayout.js" as VolumeLayout'))
assert(widget.includes('readonly property int adaptiveHeight: VolumeLayout.adaptiveHeight('))
assert(!/^\s*height:\s*210\s*$/m.test(widget), 'fixed legacy height must not override adaptive module sizing')
assert(shell.includes('contentHeight: Math.min(Config.volumeMaxHeight, volumesWidget.animatedAdaptiveHeight)'))
console.log('Volume hidden/empty/expanded adaptive heights and shell geometry: OK')
NODE
