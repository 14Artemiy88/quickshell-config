#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
need() { grep -Fq -- "$2" "$1" || { echo "missing '$2' in $1" >&2; exit 1; }; }
need "$ROOT/Config.qml" 'property int animationCavaMorphDuration: 180'
need "$ROOT/Config.qml" 'property string animationCavaMorphProfile: "expressive"'
need "$ROOT/js/settings/SettingsDefaults.js" 'animationCavaMorphDuration: 180'
need "$ROOT/js/settings/SettingsDefaults.js" 'animationCavaMorphProfile: "expressive"'
need "$ROOT/js/settings/SettingsPersistence.js" 'animationCavaMorphDuration: config.animationCavaMorphDuration'
need "$ROOT/js/settings/SettingsPersistence.js" 'animationCavaMorphProfile: config.animationCavaMorphProfile'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'allowedCavaMorphProfiles = ["none", "standard", "spatial", "effects", "expressive"]'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'Config.animationCavaMorphDuration = Math.max(0, Math.min(5000, Math.round(cavaMorphDuration)))'
need "$ROOT/js/settings/SettingsPageRegistry.js" '{ id: "cava", saveScope: "cava", subTabs: ["Основные", "Полосы", "Анимация"] }'
need "$ROOT/components/settings/SettingsNavigationController.qml" '{ keys: ["animationCavaMorphDuration", "animationCavaMorphProfile"] }'
need "$ROOT/components/settings/sections/SettingsCavaSection.qml" 'SettingsAnimationGroup {'
need "$ROOT/components/settings/sections/SettingsCavaSection.qml" 'currentPageSubTabIndex === 2'
need "$ROOT/components/settings/sections/SettingsCavaSection.qml" 'Анимация появления самого модуля остаётся независимой.'
need "$ROOT/components/Cava.qml" 'Config.animationDurationForProfile(true, Config.animationCavaMorphProfile, Config.animationCavaMorphDuration, "appearance")'
need "$ROOT/components/Cava.qml" 'Config.animationBezierCurve(Config.animationCavaMorphProfile'
need "$ROOT/js/settings/SettingsProfiles.js" 'cava: ["cava", "animationCava"]'
need "$ROOT/js/settings/SettingsResets.js" '"animationCavaMorphDuration", "animationCavaMorphProfile"'
need "$ROOT/CHECK.sh" 'test_cava_animation_settings.sh'
echo 'CAVA animation settings schema, profile/reset persistence and transition wiring passed'
