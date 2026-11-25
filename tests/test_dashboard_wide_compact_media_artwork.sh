#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8');
const helperSource = read('js/player/PlayerImage.js').replace(/^\.pragma library\s*$/gm, '');
const helperContext = {};
vm.runInNewContext(helperSource + '\nthis.api = { isPlaceholderImage, imageSourceForPath };', helperContext);
const helper = helperContext.api;

const shellDir = '/home/test/.config/quickshell';
assert.strictEqual(helper.imageSourceForPath('', shellDir), '', 'empty image metadata does not create an Image source');
assert.strictEqual(helper.imageSourceForPath(shellDir + '/assets/1px.png', shellDir), '',
  'the transparent sentinel remains absent from Player and Dashboard image sources');
assert.strictEqual(helper.isPlaceholderImage(shellDir + '/assets/album_cover.png', shellDir), true,
  'the default album-cover fallback is treated as non-artwork by Dashboard');
assert.strictEqual(helper.imageSourceForPath(shellDir + '/assets/album_cover.png', shellDir),
  'file://' + encodeURIComponent(shellDir + '/assets/album_cover.png').replace(/%2F/gi, '/'),
  'Player retains its existing visible album-cover fallback behavior');
assert.strictEqual(helper.imageSourceForPath('https://cdn.example.test/cover.jpg?size=256', shellDir),
  'https://cdn.example.test/cover.jpg?size=256', 'HTTP artwork URLs remain unchanged');
assert.strictEqual(helper.imageSourceForPath('image://icons/music', shellDir),
  'image://icons/music', 'Qt image-provider URLs remain unchanged');
assert.strictEqual(helper.imageSourceForPath('qrc:/icons/music.svg', shellDir),
  'qrc:/icons/music.svg', 'Qt resource URLs remain unchanged');
const local = '/home/test/Music/Живой альбом #1?.jpg';
const localExpected = 'file://' + encodeURIComponent(local).replace(/%2F/gi, '/');
assert.strictEqual(helper.imageSourceForPath(local, shellDir), localExpected,
  'raw local paths encode spaces, Cyrillic and URL-reserved characters safely');
assert.strictEqual(helper.imageSourceForPath('file:///home/test/Music/cover%20one%23two.jpg', shellDir),
  'file:///home/test/Music/cover%20one%23two.jpg',
  'already encoded file URLs are decoded and normalized exactly once');
assert.strictEqual(helper.imageSourceForPath('file://localhost/home/test/cover%20one.jpg', shellDir),
  'file:///home/test/cover%20one.jpg', 'localhost file URLs normalize to local file URLs');

const dashboard = read('components/Dashboard.qml');
const player = read('components/Player.qml');
assert(dashboard.includes('import "../js/player/PlayerImage.js" as PlayerImage')
    && player.includes('import "../js/player/PlayerImage.js" as PlayerImage'),
  'Dashboard and Player share the same image URL normalization module');
assert(player.includes('return PlayerImage.imageSourceForPath(value, Quickshell.shellDir)'),
  'the Player keeps using the shared URL normalization helper');
assert(dashboard.includes('!PlayerImage.isPlaceholderImage(root.playerData.image, Quickshell.shellDir)'),
  'Dashboard hides missing/placeholder artwork instead of showing the generic Player cover');
assert.strictEqual((dashboard.match(/mediaImageSource: (?:horizontalLeadSlot\.)?modelData\.id === "media" \? root\.mediaImageSource : ""/g) || []).length, 4,
  'all four Dashboard delegate paths propagate media artwork when Media is selected as the lead or peer');

const start = dashboard.indexOf('// Compact wide Media:');
const end = dashboard.indexOf('// Wide System lead:', start);
assert(start >= 0 && end > start, 'compact wide Media block exists');
const media = dashboard.slice(start, end);
assert(media.includes('!infoCard.expanded && infoCard.wideLead && infoCard.cardId === "media"'),
  'artwork remains exclusive to the compact wide-lead Media composition');
assert(media.includes('source: infoCard.mediaImageSource')
    && media.includes('asynchronous: true')
    && media.includes('cache: true')
    && media.includes('fillMode: Image.PreserveAspectCrop'),
  'artwork loads asynchronously, reuses the image cache and crops to a square thumbnail');
assert(media.includes('mediaArtwork.status !== Image.Ready') && media.includes('text: "♫"'),
  'missing, loading or invalid artwork retains a music-note fallback');
assert(media.includes('sourceSize.width: 160') && media.includes('sourceSize.height: 160'),
  'the thumbnail requests a bounded decode size');
assert(media.includes('Layout.horizontalStretchFactor: 56')
    && media.includes('Layout.horizontalStretchFactor: 44'),
  'the established track/metadata column balance is retained');
assert(dashboard.includes('if ((infoCard.expanded || infoCard.wideLead) && infoCard.mediaProgressPercent >= 0)'),
  'existing screen-reader track/progress details remain intact');
assert(!dashboard.includes('Process {'), 'artwork introduces no additional polling process');
console.log('Dashboard compact wide Media artwork: URL normalization, placeholder fallback, responsive scope and existing Player behavior: OK');
NODE
echo 'Dashboard compact wide Media artwork: OK'
