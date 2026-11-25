#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplyTimerPlayer.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
SCHEMA="$ROOT/js/settings/SettingsSchema.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
UI="$ROOT/components/settings/sections/mopidy/SettingsMopidyTimeSection.qml"
ROW="$ROOT/components/mopidy/MopidyQueueTrackRow.qml"

# Runtime config, old-profile fallback, persistence and Mopidy reset scope.
grep -Fq 'property int mopidyTrackArtistGap: 0' "$CONFIG"
grep -Fq 'mopidyTrackArtistGap: 0' "$DEFAULTS"
grep -Fq 'mopidyTrackArtistGap: config.mopidyTrackArtistGap' "$PERSIST"
grep -Fq 'Config.mopidyTrackArtistGap = Math.max(0, Math.min(8, Math.round(Number(o.mopidyTrackArtistGap) || 0)))' "$APPLY"
grep -Fq '"mopidyTrackArtistGap"' "$RESETS"
grep -Fq 'mopidyTrackArtistGap' "$UI"
grep -Fq 'targetProperty: "mopidyTrackArtistGap"' "$UI"
grep -Fq 'visible: Config.mopidyTrackArtistDisplayMode === "two-lines"' "$UI"
grep -Fq '"mopidyTrackArtistGap"' "$UI"
grep -Fq 'prefixes: ["mopidyTrack"' "$ROOT/components/settings/SettingsNavigationController.qml"
grep -Fq 'readonly property real artistGap:' "$ROW"
grep -Fq 'Math.min(8, Number(Config.mopidyTrackArtistGap) || 0)' "$ROW"

# Verify legacy full profiles acquire 0, sparse profiles omit defaults, and values clamp.
node - "$SCHEMA" <<'JS'
const fs = require('fs');
const vm = require('vm');
const src = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(src, context);
const normalize = context.normalizeProfile;
if (typeof normalize !== 'function') throw new Error('normalizeProfile unavailable');
const legacy = normalize({}, false);
if (legacy.mopidyTrackArtistGap !== 0) throw new Error('legacy full profile must default gap to 0');
const sparse = normalize({}, true);
if (Object.prototype.hasOwnProperty.call(sparse, 'mopidyTrackArtistGap')) throw new Error('sparse profile must omit inherited gap');
if (normalize({mopidyTrackArtistGap: 99}, false).mopidyTrackArtistGap !== 8) throw new Error('gap upper clamp failed');
if (normalize({mopidyTrackArtistGap: -4}, false).mopidyTrackArtistGap !== 0) throw new Error('gap lower clamp failed');
if (normalize({mopidyTrackArtistGap: 'invalid'}, false).mopidyTrackArtistGap !== 0) throw new Error('invalid gap fallback failed');
// The split expands symmetrically around the original 57/43 boundary and keeps
// the configured blank space exact while preserving a positive text area.
for (const rowHeight of [30, 38, 48, 80]) {
  const baseY = Math.round(rowHeight * 0.57);
  for (const gap of [0, 2, 4, 8]) {
    const artistY = baseY + Math.ceil(gap / 2);
    const titleHeight = artistY - gap;
    const artistHeight = rowHeight - artistY;
    if (titleHeight + gap + artistHeight !== rowHeight || titleHeight < 1 || artistHeight < 1)
      throw new Error(`invalid split row=${rowHeight}, gap=${gap}`);
  }
}
console.log('Mopidy artist gap profile normalization and row geometry: OK');
JS
printf 'Mopidy two-line artist gap setting: OK\n'
