#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])
def read(path): return (root/path).read_text(encoding='utf-8')

config=read('Config.qml')
defaults=read('js/settings/SettingsDefaults.js')
persistence=read('js/settings/SettingsPersistence.js')
apply=read('js/settings/SettingsApplyBehaviour.js')
profiles=read('js/settings/SettingsProfiles.js')
resets=read('js/settings/SettingsResets.js')
settings=read('Settings.qml')
navigation=read('components/settings/SettingsNavigationController.qml')
section=read('components/settings/sections/SettingsTimersSection.qml')
timer=read('components/TimerWidget.qml')
registry=read('js/settings/SettingsPageRegistry.js')

# Defaults preserve the existing 220 ms entry/exit row motion and Expressive curve.
for token in (
    'property bool animationTimerMorphEnabled: true',
    'property int animationTimerMorphDuration: 220',
    'property string animationTimerMorphProfile: "expressive"',
):
    assert token in config, f'missing Config default: {token}'
    literal=token.replace('property bool ', '').replace('property int ', '').replace('property string ', '')
    assert literal in defaults, f'missing profile default: {literal}'

# Persistence, validation, reset and profile scopes are complete.
for key in ('animationTimerMorphDuration','animationTimerMorphProfile'):
    assert f'{key}: config.{key}' in persistence, f'{key} missing from persistence snapshot'
    assert f'"{key}"' in resets, f'{key} missing from Timer reset'
assert 'animationTimerMorphEnabled: config.animationTimerMorphEnabled' not in persistence
assert 'animationTimerMorphEnabled' in persistence[persistence.index('var managedKeys'):]
assert 'var legacyTimerMorphEnabled = o.animationTimerMorphEnabled' in apply
assert 'Config.animationTimerMorphEnabled = true' in apply
assert 'if (legacyTimerMorphEnabled === false)' in apply and 'Config.animationTimerMorphProfile = "none"' in apply
assert 'Math.max(0, Math.min(5000, Math.round(timerMorphDuration)))' in apply
assert 'var allowedTimerMorphProfiles = ["none", "standard", "spatial", "effects", "expressive"]' in apply
assert 'timer: ["timer"]' in profiles and 'timer: ["timer", "animationTimer"]' in profiles
assert 'weatherDaily: ["weather", "animationWeather"], timer: ["timer"],' in settings
assert 'timer: ["timer", "animationTimer"], player: ["player"]' in settings
assert 'prefixes: ["animationTimer", "timerButton"]' in navigation

# The existing Timer -> Animations subtab is extended rather than creating a new page.
assert '{ id: "timers", saveScope: "timer", subTabs: ["Основные", "Окно окончания", "Иконки", "Разметка", "Анимации", "Опции таймера"] }' in registry
assert 'heading: "Внутренние переходы таймера"' in section
assert 'SettingsAnimationGroup {' in section
assert 'animationsEnabled:' not in section
assert 'duration: Config.animationTimerMorphDuration' in section
assert 'profile: Config.animationTimerMorphProfile' in section
assert 'onAnimationEnabledEdited:' not in section and 'onDurationEdited:' in section and 'onProfileEdited:' in section
assert 'Config.animationTimerMorphProfile !== \"none\"' not in section, 'Timer button settings must remain available for every profile'
assert section.count('visible: root.host.currentPageId === \"timers\" && root.host.currentPageSubTabIndex === 4') >= 4, 'button settings should be gated only by the Timer animation settings page'
assert section.count('height: visible ? 30 : 0') >= 3
assert 'currentPageSubTabIndex === 4' in section

# Existing row, icon and preset-button transitions respond to the module settings.
assert 'readonly property int timerRowMorphDuration: Config.animationDurationForProfile(' in timer
assert timer.count('animationProfile: Config.animationTimerMorphProfile') >= 3
assert timer.count('!Config.animationProfileIsEnabled(Config.animationTimerMorphEnabled, Config.animationTimerMorphProfile)\n                ? 0 : Config.animationDuration(Config.timerButtonIconFadeDuration, \"appearance\")') == 2, 'icon morphs must depend on the internal profile, not preset-button style'
assert timer.count('animationStyle: Config.animationProfileIsEnabled(Config.animationTimerMorphEnabled, Config.animationTimerMorphProfile) ? Config.animationTimerVisibilityStyle : "none"') == 2
assert timer.count('animationProfile: Config.animationTimerMorphProfile') >= 5
assert 'Config.animationEasingType(Config.animationTimerMorphProfile, "enter")' in timer
assert 'Config.animationEasingType(Config.animationTimerMorphProfile, "exit")' in timer
assert 'Config.animationBezierCurve(Config.animationTimerMorphProfile, "enter")' in timer
assert 'Config.animationBezierCurve(Config.animationTimerMorphProfile, "exit")' in timer
# The options popup keeps its independent pre-existing style and duration.
options=read('components/TimerOptions.qml')
assert 'Config.animationTimerOptionsVisibilityStyle' in options
assert 'Config.animationTimerOptionsDuration' in options
print('Timer animation settings: defaults, persistence, profile scopes, reset, UI, row/icon/button transitions and independent options popup: OK')
PY
