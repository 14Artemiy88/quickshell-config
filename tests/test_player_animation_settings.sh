#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re, sys
root=Path(sys.argv[1])
def read(path): return (root/path).read_text(encoding='utf-8')

config=read('Config.qml')
defaults=read('js/settings/SettingsDefaults.js')
persistence=read('js/settings/SettingsPersistence.js')
apply=read('js/settings/SettingsApplyBehaviour.js')
profiles=read('js/settings/SettingsProfiles.js')
resets=read('js/settings/SettingsResets.js')
registry=read('js/settings/SettingsPageRegistry.js')
navigation=read('components/settings/SettingsNavigationController.qml')
page=read('components/settings/pages/SettingsPlayerPage.qml')
section=read('components/settings/sections/SettingsPlayerAnimationSection.qml')
player=read('components/Player.qml')

# The new settings preserve current Player behavior by default.
for token in (
    'property bool animationPlayerMorphEnabled: true',
    'property int animationPlayerMorphDuration: 180',
    'property string animationPlayerMorphProfile: "expressive"',
):
    assert token in config, f'missing Config default: {token}'
    literal=token.replace('property bool ', '').replace('property int ', '').replace('property string ', '')
    assert literal in defaults, f'missing profile default: {literal}'

# Snapshot, profile apply validation, scoped profile save and reset are wired.
for key in ('animationPlayerMorphDuration','animationPlayerMorphProfile'):
    assert f'{key}: config.{key}' in persistence, f'{key} missing from persistence snapshot'
    assert f'"{key}"' in resets, f'{key} missing from Player reset'
assert 'animationPlayerMorphEnabled: config.animationPlayerMorphEnabled' not in persistence
assert 'animationPlayerMorphEnabled' in persistence[persistence.index('var managedKeys'):]
assert 'var legacyPlayerMorphEnabled = o.animationPlayerMorphEnabled' in apply
assert 'Config.animationPlayerMorphEnabled = true' in apply
assert 'if (legacyPlayerMorphEnabled === false)' in apply and 'Config.animationPlayerMorphProfile = "none"' in apply
assert 'Math.max(0, Math.min(5000, Math.round(playerMorphDuration)))' in apply
assert 'var allowedPlayerMorphProfiles = ["none", "standard", "spatial", "effects", "expressive"]' in apply
assert 'player: ["player", "animationPlayer"]' in profiles
assert 'player: ["player", "animationPlayer"]' in profiles

# Profile registry and UI routing expose one appended Player subtab (index 7).
assert '{ id: "player", saveScope: "player", subTabs: ["Общее", "Тишина", "Оставшееся время", "Метаданные", "Иконки", "Прогресс", "Обложка и фон", "Анимация"] }' in registry
assert '{ keys: ["animationPlayerMorphDuration", "animationPlayerMorphProfile"] }' in navigation
assert 'SettingsPlayerAnimationSection {' in page
assert 'objectName: "settings-search-page:player"' in page
assert 'currentPageSubTabIndex === 7' in section
assert 'SettingsAnimationGroup {' in section
assert 'animationsEnabled:' not in section
assert 'duration: Config.animationPlayerMorphDuration' in section
assert 'profile: Config.animationPlayerMorphProfile' in section
assert 'onAnimationEnabledEdited:' not in section and 'onDurationEdited:' in section and 'onProfileEdited:' in section
assert 'root.settings.save()' in section

# All three existing Player transitions are configurable; no additional morphs are introduced.
assert player.count('animationDuration: Config.animationDurationForProfile(Config.animationPlayerMorphEnabled, Config.animationPlayerMorphProfile, Config.animationPlayerMorphDuration, \"appearance\")') == 3
assert player.count('animationProfile: Config.animationPlayerMorphProfile') == 3
assert player.count('animationProfile: "expressive"') == 0
print('Player animation settings: defaults, profile persistence, validation, reset, UI routing and 3 live morphs: OK')
PY
