#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])

def read(path):
    return (root / path).read_text(encoding="utf-8")

config = read("Config.qml")
defaults = read("js/settings/SettingsDefaults.js")
persist = read("js/settings/SettingsPersistence.js")
apply = read("js/settings/SettingsApplyBehaviour.js")
resets = read("js/settings/SettingsResets.js")
section = read("components/settings/sections/SettingsNotificationsSection.qml")
nav = read("components/settings/SettingsNavigationController.qml")
notifications = read("components/notifications/Notifications.qml")
check = read("CHECK.sh")

key = "animationNotificationsVisibilityStyle"
styles = ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
assert f'property string {key}: "fade"' in config
assert f'{key}: "fade"' in defaults
assert f'{key}: config.{key}' in persist
assert f'allowedNotificationsVisibilityStyles = {styles!r}'.replace("'", '"') in apply
assert f'Config.{key} = notificationsVisibilityStyle' in apply
assert key in resets
assert key in nav
assert key in section
assert 'model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]' in section
assert 'property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]' in section
assert 'root.settings.save()' in section

assert 'readonly property string notificationCardAnimationStyle:' in notifications
assert 'readonly property int notificationCardVisibilityDuration:' in notifications
assert 'populate: Transition {' not in notifications and 'add: Transition {' not in notifications
assert 'function startNotificationEntry()' in notifications
assert 'ListView.onAdd: card.startNotificationEntry()' in notifications
assert 'Component.onCompleted: {\n                        // Existing tracked notifications' in notifications
assert 'entryAnimationStarted || removalPending || notification === null' in notifications
assert 'property real transitionProgress: 1' in notifications
assert 'property string activeTransitionStyle: "none"' in notifications
assert 'activeTransitionStyle = root.notificationCardAnimationStyle' in notifications
assert 'activeTransitionPhase = "enter"' in notifications
assert 'activeTransitionPhase = "exit"' in notifications
assert 'transitionProgress = 0' in notifications
assert 'transitionProgress = 1' in notifications
assert 'property: "transitionProgress"' in notifications
assert 'opacity: animatedOpacity' in notifications
assert 'readonly property real animatedOpacity: NotificationAnimation.opacityForProgress(' in notifications
assert 'readonly property real motionOffsetX: NotificationAnimation.motionOffsetXForProgress(' in notifications
assert 'readonly property real motionOffsetY: NotificationAnimation.motionOffsetYForProgress(' in notifications
assert 'property: "animatedOpacity"' not in notifications
assert 'property: "motionOffsetX"' not in notifications
assert 'property: "motionOffsetY"' not in notifications
assert 'remove: Transition {' not in notifications
assert 'ListView.onRemove: card.startNotificationExit("listview-remove")' in notifications
assert 'ListView.delayRemove = true' in notifications and 'ListView.delayRemove = false' in notifications
assert 'root.activeNotificationExitCount += 1' in notifications
panel_block = notifications.split('PanelWindow {\n        id: popupWindow', 1)[1].split('Item {\n            id: notificationContent', 1)[0]
assert 'visible: true' in panel_block
assert 'readonly property bool notificationSurfaceActive:' in notifications
assert 'implicitWidth: root.notificationSurfaceActive ? root.notificationCardWidth : 1' in panel_block
assert 'if (!root.notificationSurfaceActive)\n                return 1' in panel_block
assert 'visible: root.notificationSurfaceActive' in notifications
assert 'NotificationAnimation.shouldAnimate(activeTransitionStyle, activeTransitionDuration)' in notifications
assert 'root.notificationCardVisibilityDuration' in notifications
assert 'displaced: Transition {' in notifications
assert 'property: "y"' in notifications.split('displaced: Transition {', 1)[1]
assert 'NotificationAnimation.js" as NotificationAnimation' in notifications
assert 'NotificationAnimation.motionOffsetXForProgress' in notifications and 'NotificationAnimation.motionOffsetYForProgress' in notifications
assert 'NotificationAnimation.effectiveStyle(' in notifications
assert 'NotificationAnimation.visibilityDuration(' in notifications
assert 'ListView.onRemove:' in notifications and 'expirationTimer.stop()' in notifications
assert 'test_notifications_animation_direction.sh' in check
print("notification card entrance/exit directions, profile persistence and queue reflow isolation: OK")
PY
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/settings/SettingsApplyBehaviour.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const context = { Config: { animationNotificationsVisibilityStyle: 'fade' } };
vm.createContext(context);
vm.runInContext(source + '\nthis.applyForTest = apply;', context);
for (const style of ['none', 'fade', 'slideLeft', 'slideRight', 'slideUp', 'slideDown']) {
  context.applyForTest(context.Config, { animationNotificationsVisibilityStyle: style });
  if (context.Config.animationNotificationsVisibilityStyle !== style)
    throw new Error('valid notification visibility style was not applied: ' + style);
}
context.applyForTest(context.Config, { animationNotificationsVisibilityStyle: 'invalid' });
if (context.Config.animationNotificationsVisibilityStyle !== 'slideDown')
  throw new Error('invalid notification visibility style should preserve the prior value');
console.log('notification direction profile load/validation: OK');
JS

node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/notifications/NotificationAnimation.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.api = { motionOffsetX, motionOffsetY, motionOffsetXForProgress, motionOffsetYForProgress, opacityForProgress, shouldAnimate, effectiveStyle, visibilityDuration };', context);
const api = context.api;
const expected = {
  none: [0, 0], fade: [0, 0],
  slideLeft: [-380, 0], slideRight: [380, 0],
  slideUp: [0, -84], slideDown: [0, 84]
};
for (const [style, offsets] of Object.entries(expected)) {
  const actual = [api.motionOffsetX(style, 380), api.motionOffsetY(style, 84)];
  if (actual[0] !== offsets[0] || actual[1] !== offsets[1])
    throw new Error('wrong entry/exit offset for ' + style + ': ' + actual);
}
if (api.shouldAnimate('none', 180)) throw new Error('none style must disable the card animation');
if (api.shouldAnimate('slideUp', 0)) throw new Error('zero duration must disable the card animation');
if (!api.shouldAnimate('fade', 180) || !api.shouldAnimate('slideDown', 180))
  throw new Error('enabled notification styles must animate');
if (api.effectiveStyle('none', 'slideLeft') !== 'none')
  throw new Error('the no-animation profile must override the selected direction');
if (api.effectiveStyle('expressive', 'slideleft') !== 'slideLeft')
  throw new Error('direction style should be normalized case-insensitively');
for (const style of ['none', 'fade', 'slideLeft', 'slideRight', 'slideUp', 'slideDown']) {
  if (api.effectiveStyle('expressive', style) !== style)
    throw new Error('selected notification style was not applied: ' + style);
}
if (api.visibilityDuration('none', 180) !== 0 || api.visibilityDuration('fade', 0) !== 0)
  throw new Error('disabled notification style/profile must have zero duration');
if (api.visibilityDuration('slideDown', 180) !== 180)
  throw new Error('enabled notification style must keep the configured duration');
// Entry and exit are driven by one normalized progress value. Slide styles
// preserve opacity, while fade leaves geometry unchanged.
for (const style of ['slideLeft', 'slideRight', 'slideUp', 'slideDown', 'none']) {
  for (const phase of ['enter', 'exit']) {
    if (api.opacityForProgress(style, phase, 0) !== 1 || api.opacityForProgress(style, phase, 0.5) !== 1 || api.opacityForProgress(style, phase, 1) !== 1)
      throw new Error(style + ' ' + phase + ' must not fade');
  }
}
if (api.opacityForProgress('fade', 'enter', 0) !== 0 || api.opacityForProgress('fade', 'enter', 1) !== 1)
  throw new Error('fade entry opacity endpoints are incorrect');
if (api.opacityForProgress('fade', 'exit', 0) !== 1 || api.opacityForProgress('fade', 'exit', 1) !== 0)
  throw new Error('fade exit opacity endpoints are incorrect');
if (api.motionOffsetXForProgress('slideLeft', 380, 'enter', 0) !== -380 || api.motionOffsetXForProgress('slideLeft', 380, 'enter', 1) !== 0)
  throw new Error('slideLeft entry must travel from left edge to final position');
if (api.motionOffsetXForProgress('slideLeft', 380, 'exit', 0) !== 0 || api.motionOffsetXForProgress('slideLeft', 380, 'exit', 1) !== -380)
  throw new Error('slideLeft exit must travel from final position to left edge');
if (api.motionOffsetYForProgress('slideDown', 84, 'enter', 0) !== 84 || api.motionOffsetYForProgress('slideDown', 84, 'enter', 1) !== 0)
  throw new Error('slideDown entry must travel from bottom edge to final position');
if (api.motionOffsetYForProgress('slideDown', 84, 'exit', 0) !== 0 || api.motionOffsetYForProgress('slideDown', 84, 'exit', 1) !== 84)
  throw new Error('slideDown exit must travel from final position to bottom edge');
console.log('notification normalized transition: all directions, fade isolation, profile override and disabled state OK');
JS
