#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])

def read(path):
    return (root/path).read_text(encoding='utf-8')

config=read('Config.qml')
defaults=read('js/settings/SettingsDefaults.js')
persistence=read('js/settings/SettingsPersistence.js')
apply=read('js/settings/SettingsApplyBehaviour.js')
resets=read('js/settings/SettingsResets.js')
profiles=read('js/settings/SettingsProfiles.js')
navigation=read('components/settings/SettingsNavigationController.qml')
registry=read('js/settings/SettingsPageRegistry.js')
page=read('components/settings/pages/SettingsMopidyPage.qml')
section=read('components/settings/sections/mopidy/SettingsMopidyAnimationSection.qml')
primitive=read('components/settings/primitives/SettingsAnimationGroup.qml')
shell=read('shell.qml')

# Defaults and persistence are profile-backed; no standalone/global animation tab is introduced.
for token in (
    'property bool animationMopidyMorphEnabled: true',
    'property int animationMopidyMorphDuration: 180',
    'property string animationMopidyMorphProfile: "expressive"',
):
    assert token in config, f'missing Config default: {token}'
    assert token.replace('property bool ', '').replace('property int ', '').replace('property string ', '') in defaults, f'missing profile default: {token}'
for key in ('animationMopidyMorphDuration', 'animationMopidyMorphProfile'):
    assert f'{key}: config.{key}' in persistence, f'{key} is not in the snapshot'
    assert f'"{key}"' in resets, f'{key} is not reset from the active profile'
assert 'animationMopidyMorphEnabled: config.animationMopidyMorphEnabled' not in persistence
assert '"animationMopidyMorphEnabled"' in persistence[persistence.index('var managedKeys'):], 'legacy key must be cleared from old root snapshots'
assert 'mopidy: ["mopidy", "animationMopidy"]' in profiles, 'Mopidy profile scope does not include animation settings'
assert '"animationMopidyMorphDuration", "animationMopidyMorphProfile"' in navigation
assert 'subTabs: ["Общее", "Время", "Иконки", "Пусто и недоступен", "Анимация"]' in registry
assert 'MopidySettings.SettingsMopidyAnimationSection {' in page
assert 'objectName: "settings-search-page:mopidy"' in page

# Values loaded from JSON/profile data are range- and enum-validated.
assert 'var legacyMopidyMorphEnabled = o.animationMopidyMorphEnabled' in apply
assert 'Config.animationMopidyMorphEnabled = true' in apply
assert 'if (legacyMopidyMorphEnabled === false)' in apply and 'Config.animationMopidyMorphProfile = "none"' in apply
assert 'Math.max(0, Math.min(5000, Math.round(mopidyMorphDuration)))' in apply
assert 'var allowedMopidyMorphProfiles = ["none", "standard", "spatial", "effects", "expressive"]' in apply

# The new UI is scoped only to Mopidy's fifth subtab and saves all controls.
assert 'currentPageSubTabIndex === 4' in section
assert 'Включить внутренние переходы' not in primitive
assert 'SettingsAnimationGroup {' in section
assert 'animationsEnabled:' not in section
assert 'duration: Config.animationMopidyMorphDuration' in section
assert 'profile: Config.animationMopidyMorphProfile' in section
assert 'onAnimationEnabledEdited:' not in section and 'onDurationEdited:' in section and 'onProfileEdited:' in section
assert 'onAnimationMopidyEnabledChanged' not in section, 'stale Connections signal handler must not remain'
assert 'animationMopidyVisibilityStyle' in section
assert 'root.settings.save()' in section

# All existing Mopidy morph transitions consume the module-owned enable, duration and curve controls.
expected = {
    'components/mopidy/MopidyQueueTrackRow.qml': 2,
    'components/mopidy/MopidyFileBrowser.qml': 1,
    'components/mopidy/MopidyLibraryView.qml': 1,
    'components/mopidy/MopidyPlaylistDialog.qml': 1,
    'components/mopidy/MopidyTopPanel.qml': 3,
    'components/mopidy/Mopidy.qml': 1,
}
count=0
for filename, expected_count in expected.items():
    source=read(filename)
    n=source.count('animationDuration: Config.animationDurationForProfile(')
    assert n == expected_count, f'{filename}: expected {expected_count} profile-aware morph durations, got {n}'
    assert source.count('animationProfile: Config.animationMopidyMorphProfile') == expected_count, f'{filename}: profile not applied to every morph'
    count += n
assert count == 9, f'expected 9 controlled Mopidy morphs, got {count}'

print('Mopidy animation settings: profile defaults, sparse persistence, reset, UI routing and 9 live morph controls: OK')
PY
