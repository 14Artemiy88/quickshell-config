#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
need() { grep -Fq -- "$2" "$1" || { echo "missing '$2' in $1" >&2; exit 1; }; }

# Independent module-entry curves are declared, defaulted, loaded and persisted.
keys=(
  animationDashboardVisibilityProfile
  animationCalendarVisibilityProfile
  animationMopidyVisibilityProfile
  animationNetworkVisibilityProfile
  animationTimerVisibilityProfile
  animationTimerOptionsVisibilityProfile
  animationSettingsVisibilityProfile
  animationVolumeStreamsVisibilityProfile
  animationNotificationsVisibilityProfile
)
for key in "${keys[@]}"; do
  need "$ROOT/Config.qml" "property string ${key}: \"ease-out\""
  need "$ROOT/js/settings/SettingsDefaults.js" "${key}: \"ease-out\""
  need "$ROOT/js/settings/SettingsPersistence.js" "${key}: config.${key}"
  need "$ROOT/js/settings/SettingsApplyBehaviour.js" "\"${key}\""
done
need "$ROOT/components/primitives/AnimatedVisibility.qml" 'easing.type: Config.animationEasingType(root.activeAnimationProfile, "enter")'
need "$ROOT/components/primitives/AnimatedVisibility.qml" 'easing.bezierCurve: Config.animationBezierCurve(root.activeAnimationProfile, "enter")'
need "$ROOT/components/primitives/AnimatedVisibility.qml" 'easing.type: Config.animationEasingType(root.activeAnimationProfile, "exit")'
need "$ROOT/components/primitives/AnimatedVisibility.qml" 'easing.bezierCurve: Config.animationBezierCurve(root.activeAnimationProfile, "exit")'

# The actual module windows use their own visibility curve.
need "$ROOT/shell.qml" 'animationProfile: Config.animationCalendarVisibilityProfile'
need "$ROOT/shell.qml" 'animationProfile: Config.animationMopidyVisibilityProfile'
need "$ROOT/shell.qml" 'animationProfile: Config.animationNetworkVisibilityProfile'
need "$ROOT/shell.qml" 'animationProfile: Config.animationSettingsVisibilityProfile'

# Custom visibility implementations use the same curves instead of fixed easing.
need "$ROOT/components/Dashboard.qml" 'readonly property string visibilityProfile: Config.animationDashboardVisibilityProfile'
need "$ROOT/components/Dashboard.qml" 'easing.bezierCurve: Config.animationBezierCurve(drawer.visibilityProfile, "enter")'
need "$ROOT/components/TimerWidget.qml" 'animationProfile: Config.animationTimerVisibilityProfile'
need "$ROOT/components/TimerOptions.qml" 'Config.animationTimerOptionsVisibilityProfile'
need "$ROOT/components/Volumes.qml" 'Config.animationEasingType(Config.animationVolumeStreamsVisibilityProfile'
need "$ROOT/components/Volumes.qml" 'Config.animationBezierCurve(Config.animationVolumeStreamsVisibilityProfile'
need "$ROOT/components/notifications/Notifications.qml" 'Config.animationNotificationsVisibilityProfile'
need "$ROOT/components/osd/SystemOsd.qml" 'Config.animationNotificationsVisibilityProfile'

# The matching UI exposes the curve alongside every existing entrance style.
need "$ROOT/components/settings/sections/SettingsCalendarSection.qml" 'SettingsAnimationCurveControl {'
need "$ROOT/components/settings/sections/mopidy/SettingsMopidyAnimationSection.qml" 'SettingsAnimationCurveControl {'
need "$ROOT/components/settings/sections/SettingsNetworkSection.qml" 'SettingsAnimationCurveControl {'
need "$ROOT/components/settings/sections/SettingsDashboardSection.qml" 'SettingsAnimationCurveControl {'
need "$ROOT/components/settings/sections/SettingsTimersSection.qml" 'SettingsAnimationCurveControl {'
need "$ROOT/components/settings/sections/SettingsVolumeSection.qml" 'SettingsAnimationCurveControl {'
need "$ROOT/components/settings/sections/SettingsNotificationsSection.qml" 'SettingsAnimationCurveControl {'
need "$ROOT/components/settings/sections/SettingsWindowSection.qml" 'SettingsAnimationCurveControl {'
need "$ROOT/components/settings/SettingsNavigationController.qml" 'animationTimerOptionsVisibilityProfile' 

# CSS easing input and backward-compatible profile fallback.
need "$ROOT/components/settings/primitives/SettingsAnimationCurveControl.qml" '"cubic-bezier()"'
need "$ROOT/js/AnimationCurves.js" 'function normalizeProfile(profile)'
need "$ROOT/js/AnimationCurves.js" 'return [custom[0], custom[1], custom[2], custom[3], 1, 1]'
need "$ROOT/js/settings/SettingsResets.js" '/^animation[A-Za-z]+VisibilityProfile$/'
need "$ROOT/CHECK.sh" 'test_visibility_animation_easing_profiles.sh'

echo 'Module visibility CSS easing settings, persistence, UI and runtime wiring passed'

node - "$ROOT" <<'JS'
const fs = require('node:fs');
const vm = require('node:vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/settings/SettingsSchema.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.normalizeForTest = normalizeProfile;', context);
const keys = [
  'animationDashboardVisibilityProfile', 'animationCalendarVisibilityProfile',
  'animationMopidyVisibilityProfile', 'animationNetworkVisibilityProfile',
  'animationTimerVisibilityProfile', 'animationTimerOptionsVisibilityProfile',
  'animationSettingsVisibilityProfile', 'animationVolumeStreamsVisibilityProfile',
  'animationNotificationsVisibilityProfile'
];
const legacyFull = context.normalizeForTest({ animationCalendarVisibilityStyle: 'slideUp' }, false);
for (const key of keys) {
  if (legacyFull[key] !== 'ease-out') throw new Error(`legacy full profile did not receive default curve: ${key}`);
}
const sparse = context.normalizeForTest({ animationCalendarVisibilityStyle: 'slideUp' }, true);
for (const key of keys) {
  if (Object.prototype.hasOwnProperty.call(sparse, key)) throw new Error(`sparse profile materialized a non-override: ${key}`);
}
const custom = context.normalizeForTest({ animationCalendarVisibilityProfile: 'cubic-bezier(0.34, 1.56, 0.64, 1)' }, true);
if (custom.animationCalendarVisibilityProfile !== 'cubic-bezier(0.34, 1.56, 0.64, 1)')
  throw new Error('custom visibility curve with overshoot was not preserved');
console.log('Visibility curve profile migration: full defaults, sparse inheritance, custom Bezier: 19/19 passed');
JS

