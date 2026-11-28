#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
need() { grep -Fq -- "$2" "$1" || { echo "missing '$2' in $1" >&2; exit 1; }; }
need "$ROOT/Config.qml" 'property int animationNetworkMorphDuration: 220'
need "$ROOT/Config.qml" 'property string animationNetworkMorphProfile: "ease-in-out"'
need "$ROOT/js/settings/SettingsDefaults.js" 'animationNetworkMorphDuration: 220'
need "$ROOT/js/settings/SettingsDefaults.js" 'animationNetworkMorphProfile: "ease-in-out"'
need "$ROOT/js/settings/SettingsPersistence.js" 'animationNetworkMorphDuration: config.animationNetworkMorphDuration'
need "$ROOT/js/settings/SettingsPersistence.js" 'animationNetworkMorphProfile: config.animationNetworkMorphProfile'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'applyMorphProfile(Config, o, "animationNetworkMorphProfile")'
need "$ROOT/js/settings/SettingsPageRegistry.js" 'subTabs: ["Обновления", "Сеть", "Анимация"]'
need "$ROOT/components/settings/sections/SettingsNetworkSection.qml" 'SettingsAnimationGroup {'
need "$ROOT/components/settings/sections/SettingsNetworkSection.qml" 'currentPageSubTabIndex === 2'
need "$ROOT/components/settings/sections/SettingsNetworkSection.qml" 'Анимация появления самого модуля остаётся независимой.'
need "$ROOT/components/Networks.qml" 'Config.animationNetworkMorphProfile !== "none"'
need "$ROOT/components/Networks.qml" 'Config.animationBezierCurve(Config.animationNetworkMorphProfile'
need "$ROOT/components/NetworkConnectionButton.qml" 'rowAnimationProfile === "none" ? 0 : Config.animationNetworkMorphDuration'
need "$ROOT/js/settings/SettingsProfiles.js" 'network: ["network", "systemMonitor", "animationNetwork"]'
need "$ROOT/js/settings/SettingsProfiles.js" 'networkStat: ["network", "systemMonitor"], networks: ["network", "systemMonitor", "animationNetwork"]'
need "$ROOT/js/settings/SettingsResets.js" 'if (moduleName === "networks")'
need "$ROOT/js/settings/SettingsResets.js" '"animationNetworkMorphDuration", "animationNetworkMorphProfile"'
echo 'Network animation settings schema and wiring passed'
