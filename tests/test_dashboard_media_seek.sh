#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const player = fs.readFileSync(path.join(root, 'components/Player.qml'), 'utf8');
const controls = fs.readFileSync(path.join(root, 'scripts/player.d/controls.sh'), 'utf8');
const shell = fs.readFileSync(path.join(root, 'scripts/player_pausing'), 'utf8');

const supportStart = dashboard.indexOf('readonly property bool mediaSeekSupported:');
const supportEnd = dashboard.indexOf('function seekDashboardMediaToPercent(', supportStart);
assert(supportStart >= 0 && supportEnd > supportStart, 'Dashboard exposes a bounded seek-support predicate');
const support = dashboard.slice(supportStart, supportEnd);
for (const required of ['Settings.player', 'root.mediaProgressPercent >= 0', 'root.playerData.duration',
  '"deadbeef"', '"mopidy"', '"mpv"', '"org.telegram.desktop"', '"plasma-browser-integration"', '"spotify"']) {
  assert(support.includes(required), `seek availability requires ${required}`);
}
assert(support.includes('"deadbeef"'), 'DeaDBeeF is exposed after its dedicated seek route is implemented');

const helperStart = dashboard.indexOf('function seekDashboardMediaToPercent(');
const helperEnd = dashboard.indexOf('// The shared Player payload stores', helperStart);
assert(helperStart >= 0 && helperEnd > helperStart, 'Dashboard exposes a public progress-seek helper');
const helper = dashboard.slice(helperStart, helperEnd);
assert(helper.includes('root.mediaSeekSupported')
  && helper.includes('typeof root.playerSource.seekToPercent !== "function"')
  && helper.includes('Math.max(0, Math.min(100, target))')
  && helper.includes('root.playerSource.seekToPercent('),
  'Dashboard clamps the clicked target and delegates it to the existing Player source');

const playerApiStart = player.indexOf('function seekToPercent(percent) {');
const playerApiEnd = player.indexOf('    function requestSeek(percent) {', playerApiStart);
assert(playerApiStart >= 0 && playerApiEnd > playerApiStart, 'Player exposes seekToPercent before the shared seek implementation');
const playerApi = player.slice(playerApiStart, playerApiEnd);
assert(playerApi.includes('root.player.duration') && playerApi.includes('root.player.player')
  && playerApi.includes('root.requestSeek(') && playerApi.includes('return false') && playerApi.includes('return true'),
  'Player validates a real selected source and duration before using the existing optimistic seek flow');
const requestStart = player.indexOf('    function requestSeek(percent) {');
const requestEnd = player.indexOf('    readonly property real playerProgressHeight:', requestStart);
const request = player.slice(requestStart, requestEnd);
assert(request.includes('pendingSeekPercent') && request.includes('pendingSeekDuration')
  && request.includes('"position"') && request.includes('root.pendingSeekPlayer')
  && request.includes('root.pendingSeekDuration'),
  'seek keeps the existing optimistic UI and sends the current backend with its duration');

const handlers = [...dashboard.matchAll(/MouseArea\s*\{[\s\S]*?\n\s*\}/g)].map(m => m[0])
  .filter(block => block.includes('root.seekDashboardMediaAtPointer('));
assert.strictEqual(handlers.length, 2, 'both compact/expanded and wide-lead progress bars have a dedicated pointer hit area');
for (const handler of handlers) {
  assert(handler.includes('anchors.fill: parent')
    && handler.includes('acceptedButtons: Qt.LeftButton')
    && handler.includes('hoverEnabled: true')
    && handler.includes('preventStealing: true')
    && handler.includes('cursorShape: Qt.PointingHandCursor')
    && handler.includes('root.mediaSeekSupported')
    && handler.includes('!root.layoutEditMode') && handler.includes('!root.cardEditMode')
    && handler.includes('mouse.x')
    && handler.includes('onPressed: function(mouse)')
    && handler.includes('mouse.accepted = true'),
    'each progress bar seeks immediately on mouse press, accepts the left click and preserves cursor/mode gating');
}
assert((dashboard.match(/Layout\.preferredHeight: 14/g) || []).length >= 4,
  'both progress rows reserve a usable transparent hit area taller than the 4px painted track');
const pointerHelperStart = dashboard.indexOf('function seekDashboardMediaAtPointer(');
const pointerHelperEnd = dashboard.indexOf('// The shared Player payload stores', pointerHelperStart);
assert(pointerHelperStart >= 0 && pointerHelperEnd > pointerHelperStart, 'Dashboard has one shared local-coordinate mapping helper');
const pointerHelper = dashboard.slice(pointerHelperStart, pointerHelperEnd);
assert(pointerHelper.includes('(x / width) * 100')
  && pointerHelper.includes('Math.max(0, Math.min(100')
  && pointerHelper.includes('width <= 0')
  && pointerHelper.includes('root.seekDashboardMediaToPercent('),
  'pointer coordinates are normalized, bounded and delegated to Player');
assert(!dashboard.includes('Quickshell.execDetached') && !dashboard.includes('scripts/player'),
  'Dashboard does not create a separate process or duplicate backend routing');

assert(shell.includes('source "$PLAYER_SCRIPT_DIR/player.d/controls.sh"')
  && controls.includes('position) position "$2" "$3" "$4" ;;'),
  'the shared player_pausing entry point continues to route seek commands');
assert(controls.includes('deadbeef_mpris_player="DeaDBeeF"')
  && controls.includes('position "$deadbeef_target_seconds"')
  && controls.includes('(p * d) / 100000'),
  'DeaDBeeF uses its canonical MPRIS identity and converts CLI milliseconds to seek seconds');

assert(controls.includes('mopidy_seek_percent "$pos_percent" "$duration_ms"')
  && controls.includes('set_property\\", \\"time-pos')
  && controls.includes('playerctl -p "$player_name" position "$target_seconds"')
  && controls.includes('length_us="$duration_ms"')
  && !controls.includes('done < <(playerctl -l 2>/dev/null'),
  'existing Mopidy, MPV and exact-ID MPRIS seek implementations are reused without rediscovery');
console.log('Dashboard Media click-to-seek: backend gating, proportional click mapping and shared Player seek route: OK');
NODE
echo 'Dashboard Media click-to-seek: OK'
