#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');

const stateStart = dashboard.indexOf('readonly property string mediaPlaybackState: {');
const stateEnd = dashboard.indexOf('readonly property int mediaProgressPercent:', stateStart);
assert(stateStart >= 0 && stateEnd > stateStart, 'the existing playback state mapper is present');
const stateMapper = dashboard.slice(stateStart, stateEnd);
assert(stateMapper.includes('if (status === "\\uF04C") return "playing"')
    && stateMapper.includes('if (status === "\\uF04B") return "paused"')
    && stateMapper.includes('return "unknown"'),
  'the Dashboard preserves playing, paused and unknown backend states without inference');

assert.strictEqual((dashboard.match(/mediaPlaybackState: (?:horizontalLeadSlot\.modelData|modelData)\.id === "media" && Settings\.player \? root\.mediaPlaybackState : "unknown"/g) || []).length, 4,
  'all four Dashboard InfoCard delegate paths propagate the current Player state only to Media');
assert(dashboard.includes('property string mediaPlaybackState: "unknown"'),
  'InfoCard defaults to an unknown state so absent metadata cannot imply playback');

const start = dashboard.indexOf('// Compact wide Media:');
const end = dashboard.indexOf('// Wide System lead:', start);
assert(start >= 0 && end > start, 'compact wide Media block exists');
const media = dashboard.slice(start, end);
assert(media.includes('!infoCard.expanded && infoCard.wideLead && infoCard.cardId === "media"'),
  'the playback badge remains exclusive to compact wide-lead Media');
assert(media.includes('infoCard.mediaPlaybackState === "playing"')
    && media.includes('infoCard.mediaPlaybackState === "paused"'),
  'the badge distinguishes active playback from pause');
assert(media.includes('text: infoCard.mediaPlaybackState === "playing" ? "▶" : "Ⅱ"'),
  'the badge uses distinct play and pause glyphs');
assert(media.includes('visible: infoCard.mediaPlaybackState === "playing"')
    && media.includes('|| infoCard.mediaPlaybackState === "paused"'),
  'unknown playback state hides the badge instead of showing a guessed status');
assert(media.includes('anchors.right: parent.right')
    && media.includes('anchors.bottom: parent.bottom')
    && media.includes('width: 18') && media.includes('height: 18'),
  'the small state marker overlays the cover corner without changing card geometry');

const accessibleStart = dashboard.indexOf('function accessibleDetails()');
const accessibleEnd = dashboard.indexOf('onActiveFocusChanged:', accessibleStart);
assert(accessibleStart >= 0 && accessibleEnd > accessibleStart, 'InfoCard accessible description exists');
const accessible = dashboard.slice(accessibleStart, accessibleEnd);
assert(accessible.includes('root.mediaPlaybackState === "paused"')
    && accessible.includes('root.mediaPlaybackState === "playing"')
    && accessible.includes('Источник не сообщает состояние воспроизведения'),
  'screen readers continue to receive truthful state wording, including unknown sources');
assert(!dashboard.includes('Process {'), 'the playback state badge adds no polling process');
console.log('Dashboard compact wide Media playback state: playing, paused, unknown, delegate propagation and accessibility: OK');
NODE
echo 'Dashboard compact wide Media playback state: OK'
