#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
const helperPath = path.join(root, 'js/mopidy/MopidyPresentation.js');
const helperSource = fs.readFileSync(helperPath, 'utf8').replace(/^\.pragma library\s*/, '');
const sandbox = {};
vm.createContext(sandbox);
vm.runInContext(helperSource + '\nthis.api = {fontScale, fontSize, trackRowHeight, albumHeaderHeight, queueSpacing};', sandbox);
const api = sandbox.api;
const equal = (actual, expected, label) => {
  if (actual !== expected) throw new Error(`${label}: expected ${expected}, got ${actual}`);
};
// Regular mode is a strict no-op for all configured values.
equal(api.fontScale('regular'), 1, 'regular font scale');
equal(api.fontSize('regular', 12), 12, 'regular track font');
equal(api.trackRowHeight('regular', 38), 38, 'regular row height');
equal(api.albumHeaderHeight('regular', 10), 26, 'regular album height');
equal(api.queueSpacing('regular'), 2, 'regular queue spacing');
// Compact mode saves vertical space without shrinking the main row below 24px.
equal(api.fontScale('compact'), 0.92, 'compact font scale');
equal(api.fontSize('compact', 12), 11, 'compact track font');
equal(api.trackRowHeight('compact', 38), 34, 'compact row height');
equal(api.trackRowHeight('compact', 20), 27, 'compact minimum row height');
equal(api.albumHeaderHeight('compact', 10), 24, 'compact album height');
equal(api.queueSpacing('compact'), 1, 'compact queue spacing');
// Wide mode uses space moderately while retaining configured values as a baseline.
equal(api.fontSize('wide', 12), 12, 'wide rounded track font');
equal(api.trackRowHeight('wide', 38), 40, 'wide row height');
equal(api.albumHeaderHeight('wide', 10), 27, 'wide album height');
equal(api.queueSpacing('wide'), 3, 'wide queue spacing');
for (const rel of [
  'components/mopidy/Mopidy.qml',
  'components/mopidy/MopidyQueueTrackRow.qml',
  'components/mopidy/MopidyAlbumHeader.qml',
  'components/mopidy/MopidyFileBrowser.qml',
  'components/mopidy/MopidyLibraryView.qml',
  'components/mopidy/MopidyPlaylistContents.qml',
]) {
  const src = fs.readFileSync(path.join(root, rel), 'utf8');
  if (!src.includes('effectiveTrackRowHeight') && rel !== 'components/mopidy/MopidyAlbumHeader.qml')
    throw new Error(`${rel}: missing adaptive row-height contract`);
  if (!src.includes('effectiveQueueRowSpacing') && rel !== 'components/mopidy/MopidyQueueTrackRow.qml' && rel !== 'components/mopidy/MopidyAlbumHeader.qml')
    throw new Error(`${rel}: missing adaptive spacing contract`);
}
const main = fs.readFileSync(path.join(root, 'components/mopidy/Mopidy.qml'), 'utf8');
for (const token of [
  'MopidyPresentation.trackRowHeight(root.presentationMode, Config.mopidyTrackRowHeight)',
  'MopidyPresentation.albumHeaderHeight(root.presentationMode, Config.mopidyAlbumFontSize)',
  'readonly property int spacing: root.effectiveQueueRowSpacing',
  'var albumHeight = root.effectiveAlbumHeaderHeight',
  'var trackHeight = root.effectiveTrackRowHeight',
]) if (!main.includes(token)) throw new Error(`Mopidy.qml missing ${token}`);
console.log('Mopidy adaptive presentation: OK');
JS
