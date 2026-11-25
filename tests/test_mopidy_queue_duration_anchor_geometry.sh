#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
const helperPath = path.join(root, 'js/mopidy/QueueDurationGeometry.js');
const helper = {};
vm.runInNewContext(fs.readFileSync(helperPath, 'utf8').replace(/^\.pragma library\s*/m, ''), helper);
const eq = (actual, expected, message) => {
  if (actual !== expected) throw new Error(`${message}: expected ${expected}, got ${actual}`);
};
eq(helper.slotX('left', 0, 420, 60), 0, 'left mode X=0 must anchor at panel left edge');
eq(helper.slotX('left', 14, 420, 60), 14, 'left mode positive X is an inset from left edge');
eq(helper.slotX('left', -1250, 420, 60), 0, 'legacy large negative left X must normalize to left edge');
eq(helper.slotX('right', 0, 420, 60), 360, 'right mode must remain anchored before icon cluster');
eq(helper.slotX('right', -8, 420, 60), 352, 'right mode negative offset preserves legacy adjustment');
eq(helper.slotX('right', 8, 420, 60), 368, 'right mode positive offset preserves legacy adjustment');
eq(helper.slotX('left', Number.NaN, 420, 60), 0, 'invalid left offset must be safe');
eq(helper.slotX('right', 0, Number.NaN, 60), -60, 'invalid edge must be safe');
const panel = fs.readFileSync(path.join(root, 'components/mopidy/MopidyTopPanel.qml'), 'utf8');
if (!panel.includes('x: QueueDurationGeometry.slotX(Config.mopidyQueueDurationAlignment')) throw new Error('Mopidy panel is not using the edge-anchor helper');
const queueStart = panel.indexOf('id: queueDurationSlot');
const queueEnd = panel.indexOf('Widgets.MopidyHoverIcon', queueStart);
const block = panel.slice(queueStart, queueEnd);
if (!block.includes('x: 0\n                        y: Config.mopidyQueueDurationY')) throw new Error('queue duration Text must start at the slot origin');
if (block.includes('x: Config.mopidyQueueDurationX')) throw new Error('old inner Text X offset remains and would double-apply X');
const apply = fs.readFileSync(path.join(root, 'js/settings/SettingsApplyTimerPlayer.js'), 'utf8');
if (!apply.includes('if (Config.mopidyQueueDurationAlignment === "left" && Config.mopidyQueueDurationX < 0)')) throw new Error('legacy negative left X is not normalized');
const settings = fs.readFileSync(path.join(root, 'components/settings/sections/mopidy/SettingsMopidyTimeSection.qml'), 'utf8');
if (!settings.includes('minimum: Config.mopidyQueueDurationAlignment === "left" ? 0 : -2000')) throw new Error('left X input must not allow negative offsets');
if (!settings.includes('X — отступ от левого края панели (0 — у самого края).')) throw new Error('left X meaning is not explained');
console.log('Mopidy queue duration edge anchoring: OK');
NODE
