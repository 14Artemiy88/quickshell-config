#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT/js/volumes/VolumeLayout.js" "$ROOT/components/Volumes.qml" "$ROOT/CHECK.sh" <<'NODE'
const fs = require('fs')
const vm = require('vm')
const assert = require('assert')
const [helperPath, widgetPath, checkPath] = process.argv.slice(2)
const helper = fs.readFileSync(helperPath, 'utf8').replace(/^\.pragma\s+library\s*;?\s*/m, '')
const context = {}
vm.runInNewContext(helper, context)
const qml = fs.readFileSync(widgetPath, 'utf8')
const check = fs.readFileSync(checkPath, 'utf8')

assert.strictEqual(context.presentationScale('compact'), 0.9)
assert.strictEqual(context.presentationScale('regular'), 1)
assert.strictEqual(context.presentationScale('wide'), 1.12)
assert.strictEqual(context.verticalPadding('compact', 12), 9)
assert.strictEqual(context.verticalPadding('regular', 12), 12)
assert.strictEqual(context.verticalPadding('compact', 0), 0)

// At the default 275 px width the regular slider remains exactly 220 px.
assert.strictEqual(context.mainTrackWidth('regular', 275, 12, 25, 220), 220)
// Compact squeezes the bar to the actual available width instead of clipping it.
assert.strictEqual(context.mainTrackWidth('compact', 260, 12, 25, 220), 211)
assert.strictEqual(context.mainTrackWidth('compact', 220, 12, 25, 220), 171)
// Both presentation boundaries remain continuous; wide growth starts progressively after 420 px.
assert.strictEqual(context.mainTrackWidth('regular', 419, 12, 25, 220), 220)
assert.strictEqual(context.mainTrackWidth('wide', 420, 12, 25, 220), 220)
assert.strictEqual(context.mainTrackWidth('wide', 600, 12, 25, 220), 283)
assert(context.mainTrackWidth('compact', 260, 12, 25, 220) <= 260 - 24 - 25)

assert.strictEqual(context.trackHeight('compact', 8), 7)
assert.strictEqual(context.trackHeight('regular', 8), 8)
assert.strictEqual(context.trackHeight('wide', 8), 9)
assert.strictEqual(context.streamRowHeight('compact', 20, 7), 19)
assert.strictEqual(context.streamRowHeight('regular', 20, 8), 20)
assert.strictEqual(context.streamRowHeight('wide', 20, 9), 22)
assert.strictEqual(context.streamListSpacing('compact'), 5)
assert.strictEqual(context.streamListSpacing('regular'), 7)
assert.strictEqual(context.streamListSpacing('wide'), 9)
assert.strictEqual(context.streamLabelSpacing('regular', 3), 3)

for (const required of [
  'VolumeLayout.presentationScale(root.presentationMode)',
  'readonly property int effectiveHorizontalPadding: Math.max(0, Config.volumeHorizontalPadding)',
  'VolumeLayout.mainTrackWidth(',
  'VolumeLayout.trackHeight(root.presentationMode, Config.volumeMainTrackHeight)',
  'VolumeLayout.streamRowHeight(',
  'readonly property real effectiveStreamLabelFontSize: root.regularPresentation',
  'font.pixelSize: root.effectiveStreamLabelFontSize',
  'spacing: root.effectiveStreamListSpacing',
  'anchors.fill: parent',
  'root.applyMainVolume(root.mainDragValue, true)',
  'root.applyStreamVolume(modelData.num, streamColumn.dragValue)',
]) assert(qml.includes(required), `Missing adaptive presentation contract: ${required}`)

// Presentation geometry must remain derived-only and keep existing input paths.
assert(!/Config\.volume(?:HorizontalPadding|VerticalPadding|MainTrackWidth|MainTrackHeight|StreamTrackHeight|StreamLabelFontSize)\s*=/.test(qml),
  'Adaptive presentation must not overwrite saved volume preferences')
assert(check.includes('test_volume_adaptive_presentation.sh'), 'Adaptive volume test must be registered in CHECK.sh')
console.log('Volume compact/regular/wide presentation and interaction contract: OK')
NODE
