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
const controlScript = fs.readFileSync(path.join(root, 'scripts/player.d/controls.sh'), 'utf8');
const wrapper = fs.readFileSync(path.join(root, 'scripts/player_pausing'), 'utf8');
const config = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');

const stateStart = dashboard.indexOf('readonly property string mediaPlaybackState: {');
const stateEnd = dashboard.indexOf('readonly property bool mediaPlaybackControlSupported:', stateStart);
assert(stateStart >= 0 && stateEnd > stateStart, 'the existing playing/paused/unknown mapper remains the source of truth');
const stateMapper = dashboard.slice(stateStart, stateEnd);
assert(stateMapper.includes('if (status === "\\uF04C") return "playing"')
    && stateMapper.includes('if (status === "\\uF04B") return "paused"')
    && stateMapper.includes('return "unknown"'),
  'the Dashboard does not infer playback state when the backend omits it');

const supportedStart = dashboard.indexOf('readonly property bool mediaPlaybackControlSupported:');
const supportedEnd = dashboard.indexOf('readonly property string mediaPlaybackActionIcon:', supportedStart);
assert(supportedStart >= 0 && supportedEnd > supportedStart, 'supported backends are explicit');
const supported = dashboard.slice(supportedStart, supportedEnd);
for (const backend of ['deadbeef', 'mopidy', 'mpv', 'org.telegram.desktop', 'plasma-browser-integration', 'spotify']) {
  assert(supported.includes(`"${backend}"`), `Dashboard exposes the implemented pause command for ${backend}`);
}
assert(supported.includes('Settings.player'), 'control availability follows the Player module setting');

const helperStart = dashboard.indexOf('function toggleDashboardMediaPlayback() {');
const helperEnd = dashboard.indexOf('// The shared Player payload stores', helperStart);
assert(helperStart >= 0 && helperEnd > helperStart, 'Dashboard playback action helper exists');
const helper = dashboard.slice(helperStart, helperEnd);
assert(helper.includes('!root.mediaPlaybackControlSupported')
    && helper.includes('backend === ""')
    && helper.includes('typeof root.playerSource.togglePlayback !== "function"')
    && helper.includes('root.playerSource.togglePlayback()'),
  'Dashboard delegates playback control to its existing Player source instead of creating a second backend route');
const playerToggleStart = player.indexOf('function togglePlayback() {');
const playerToggleEnd = player.indexOf('    Process {', playerToggleStart);
assert(playerToggleStart >= 0 && playerToggleEnd > playerToggleStart, 'Player exposes a public playback-toggle method before its polling process');
const playerToggle = player.slice(playerToggleStart, playerToggleEnd);
assert(playerToggle.includes('root.player.player')
    && playerToggle.includes('Quickshell.execDetached([')
    && playerToggle.includes('Quickshell.shellDir + "/scripts/player_pausing"')
    && playerToggle.includes('"pause"')
    && playerToggle.includes('backend'),
  'Player routes the current selected backend through the existing pause script');
assert(player.includes('onClicked: {\n            root.togglePlayback()'),
  'the existing Player surface and Dashboard share the same playback toggle method');
assert(!dashboard.includes('Quickshell.execDetached') && !dashboard.includes('scripts/player'),
  'Dashboard consumes the shared Player source and does not add its own external process or command path');
assert(wrapper.includes('source "$PLAYER_SCRIPT_DIR/player.d/controls.sh"')
    && controlScript.includes('pause) pause "$2" ;;'),
  'the existing public player_pausing entry point routes to the shared pause implementation');
for (const backend of ['spotify', 'plasma-browser-integration', 'org.telegram.desktop']) {
  assert(controlScript.includes(`["${backend}"]`), `shared controller retains ${backend} pause support`);
}
assert(controlScript.includes("['deadbeef']=") && controlScript.includes('deadbeef --toggle-pause'),
  'DeaDBeeF keeps its legacy pause command');
assert(controlScript.includes('mopidy_pause_toggle') && controlScript.includes('MPV_SOCKET'),
  'Mopidy and MPV keep their specialized pause implementations');

const buttonStart = dashboard.indexOf('id: mediaPlaybackButton');
const buttonEnd = dashboard.indexOf('\n                RowLayout {\n                    visible: root.cardEditMode', buttonStart);
assert(buttonStart >= 0 && buttonEnd > buttonStart, 'a dedicated action button is placed in the Media card header');
const button = dashboard.slice(buttonStart, buttonEnd);
assert(button.includes('infoCard.cardId === "media"')
    && button.includes('root.mediaPlaybackControlSupported')
    && button.includes('!root.cardEditMode'),
  'the action appears only on a supported Media card and not while editing cards');
assert(button.includes('Accessible.role: Accessible.Button')
    && button.includes('Accessible.name: root.mediaPlaybackActionName')
    && button.includes('toolTipText: root.mediaPlaybackActionName'),
  'the action has a state-aware accessible name and tooltip');
assert(button.includes('activeFocusOnTab: visible && enabled')
    && button.includes('root.registerNavigationTarget(mediaPlaybackButton)')
    && button.includes('root.unregisterNavigationTarget(mediaPlaybackButton)')
    && button.includes('root.invalidateNavigationTarget(mediaPlaybackButton)'),
  'the action joins the Dashboard spatial keyboard-navigation lifecycle');
assert(button.includes('Qt.Key_Return') && button.includes('Qt.Key_Enter') && button.includes('Qt.Key_Space')
    && button.includes('onClicked: {')
    && button.includes('root.toggleDashboardMediaPlayback()')
    && !button.includes('forceActiveFocus()'),
  'keyboard and pointer activation share the playback action without pinning hover focus');
assert(button.includes('Layout.preferredWidth: 28') && button.includes('Layout.preferredHeight: 28'),
  'the action stays a compact header control without taking over the card body');
assert(button.includes('borderWidth: 0') && button.includes('hoverBorderEnabled: false')
    && !button.includes('hoverBorderWidth:'),
  'the icon-only Play/Pause control has no visible frame in hover or keyboard-focus states');
assert(dashboard.includes('readonly property string mediaPlaybackActionIcon: root.mediaPlaybackState === "playing"')
    && dashboard.includes('? Config.playerPlayingIcon : Config.playerPausedIcon'),
  'the icon changes from Pause while playing to Play when paused');
assert(config.includes('property string playerPlayingIcon: "\\uF04C"')
    && config.includes('property string playerPausedIcon: "\\uF04B"'),
  'the icons preserve the same established glyph semantics as Player.qml');
console.log('Dashboard Media Play/Pause: supported backends, shared command route, mouse/keyboard access and state-aware visuals: OK');
NODE
echo 'Dashboard Media Play/Pause: OK'
