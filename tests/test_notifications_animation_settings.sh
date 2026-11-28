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
persistence = read("js/settings/SettingsPersistence.js")
apply_behaviour = read("js/settings/SettingsApplyBehaviour.js")
profiles = read("js/settings/SettingsProfiles.js")
resets = read("js/settings/SettingsResets.js")
registry = read("js/settings/SettingsPageRegistry.js")
navigation = read("components/settings/SettingsNavigationController.qml")
settings_ui = read("components/settings/sections/SettingsNotificationsSection.qml")
notifications = read("components/notifications/Notifications.qml")

for key, text in {
    "Config defaults": config,
    "profile defaults": defaults,
    "snapshot": persistence,
    "apply": apply_behaviour,
}.items():
    assert "animationNotificationsMorphDuration" in text, f"{key} misses notification animation duration"
    assert "animationNotificationsMorphProfile" in text, f"{key} misses notification animation profile"

assert 'animationNotificationsMorphDuration: 180' in config
assert 'animationNotificationsMorphProfile: "ease-in-out"' in config
assert 'animationNotificationsMorphDuration: 180' in defaults
assert 'animationNotificationsMorphProfile: "ease-in-out"' in defaults
assert 'Math.max(0, Math.min(5000, Math.round(notificationsMorphDuration)))' in apply_behaviour
assert 'applyMorphProfile(Config, o, "animationNotificationsMorphProfile")' in apply_behaviour

assert 'notifications: ["notifications", "animationNotifications"]' in profiles
assert profiles.count('notifications: ["notifications", "animationNotifications"]') == 1
assert resets.count('"animationNotificationsMorphDuration", "animationNotificationsMorphProfile", "animationNotificationsVisibilityStyle", "animationNotificationsVisibilityProfile"') >= 2

assert 'subTabs: ["Поведение", "Внешний вид", "Размещение", "Анимация"]' in registry
assert '{ keys: ["animationNotificationsMorphDuration", "animationNotificationsMorphProfile", "animationNotificationsVisibilityStyle", "animationNotificationsVisibilityProfile"] }' in navigation
assert 'SettingsAnimationGroup {' in settings_ui
assert 'currentPageSubTabIndex === 3' in settings_ui
assert 'onDurationEdited:' in settings_ui and 'onProfileEdited:' in settings_ui

assert 'notificationTransitionDuration: Config.animationDurationForProfile(' in notifications
assert 'populate: Transition {' not in notifications
assert 'add: Transition {' not in notifications
assert 'function startNotificationEntry()' in notifications
assert 'ListView.onAdd: card.startNotificationEntry()' in notifications
assert 'id: entryAnimation' in notifications
assert 'NotificationAnimation.effectiveStyle(' in notifications
assert 'Config.animationNotificationsVisibilityProfile' in notifications
assert 'NotificationAnimation.visibilityDuration(' in notifications
assert 'property string activeTransitionStyle: \"none\"' in notifications
assert 'activeTransitionDuration = root.notificationCardVisibilityDuration' in notifications
assert 'property: \"transitionProgress\"' in notifications
assert 'entryAnimation.stop()' in notifications
assert 'remove: Transition {' not in notifications, 'exit animation must be explicitly delayed by its delegate, not hidden with the popup window'
assert 'displaced: Transition {' in notifications
assert 'Config.animationEasingType(card.activeTransitionProfile, "enter")' in notifications
assert 'Config.animationEasingType(card.activeTransitionProfile, "exit")' in notifications
assert 'model: visibleNotificationModel' in notifications
assert 'ScriptModel {' in notifications and 'NotificationDnd.visibleNotifications(' in notifications
assert 'ListView.onRemove:' in notifications, 'removed delegates must stop their timeout before the remove animation finishes'
assert 'ListView.delayRemove = true' in notifications and 'ListView.delayRemove = false' in notifications
assert 'root.activeNotificationExitCount += 1' in notifications
assert 'root.activeNotificationExitCount > 0' in notifications.split('PanelWindow {', 1)[1].split('Item {', 1)[0]
assert 'root.activeNotificationExitCount > 0' in notifications.split('ListView {', 1)[1].split('displaced: Transition', 1)[0]
assert 'onFinished: card.finishNotificationExit()' in notifications
assert 'removalPending = true' in notifications, 'delegate removal state must be set before fade-out'
assert 'expirationTimer.stop()' in notifications, 'visible timeout must stop as soon as a card is removed'
assert 'property bool timeoutExpirationRequested: false' in notifications, 'timeout expiration must be one-shot during removal animation'
assert 'card.timeoutExpirationRequested = true' in notifications, 'timeout must be marked before calling expire()'
assert 'enabled: !card.removalPending' in notifications, 'dismiss/action controls must be disabled during remove animation'

print("notification-card animation settings, delegate-owned entry/exit animations, shared profile UI, save/reset wiring: OK")
PY
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/settings/SettingsApplyBehaviour.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const curveSource = fs.readFileSync(root + '/js/AnimationCurves.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const curves = {}; vm.createContext(curves); vm.runInContext(curveSource, curves);
const context = { Config: {
  animationNotificationsMorphDuration: 180,
  animationNotificationsMorphProfile: 'expressive',
  normalizeAnimationProfile: curves.normalizeProfile
} };
vm.createContext(context);
vm.runInContext(source + '\nthis.applyForTest = apply;', context);
context.applyForTest(context.Config, {
  animationNotificationsMorphDuration: 240,
  animationNotificationsMorphProfile: 'none'
});
if (context.Config.animationNotificationsMorphDuration !== 240 || context.Config.animationNotificationsMorphProfile !== 'none')
  throw new Error('valid notification animation settings were not applied');
context.applyForTest(context.Config, {
  animationNotificationsMorphDuration: 9000,
  animationNotificationsMorphProfile: 'invalid'
});
if (context.Config.animationNotificationsMorphDuration !== 5000 || context.Config.animationNotificationsMorphProfile !== 'none')
  throw new Error('notification animation values were not clamped/validated');
console.log('notification animation profile apply/clamp: OK');
const profilesSource = fs.readFileSync(root + '/js/settings/SettingsProfiles.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const profileContext = {};
vm.createContext(profileContext);
vm.runInContext(profilesSource + '\nthis.pathMatchesForTest = profileSavePathMatches; this.modulePathMatchesForTest = modulePathMatches;', profileContext);
if (!profileContext.pathMatchesForTest({}, 'notifications', null, ['animationNotificationsMorphProfile']))
  throw new Error('notifications scoped profile save omitted animation profile key');
if (!profileContext.pathMatchesForTest({}, 'notifications', null, ['animationNotificationsMorphDuration']))
  throw new Error('notifications scoped profile save omitted animation duration key');
if (!profileContext.modulePathMatchesForTest(['animationNotificationsMorphProfile'], 'notifications'))
  throw new Error('notifications module reset/scope does not include animation profile');
if (profileContext.pathMatchesForTest({}, 'notifications', null, ['notificationsCardWidth']))
  throw new Error('notification width should remain owned by Modules scope');
console.log('notification animation profile scoped persistence: OK');
JS
