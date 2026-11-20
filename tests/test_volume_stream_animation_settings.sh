#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
defaults = (root / "js/settings/SettingsDefaults.js").read_text(encoding="utf-8")
apply = (root / "js/settings/SettingsApplyBehaviour.js").read_text(encoding="utf-8")
persist = (root / "js/settings/SettingsPersistence.js").read_text(encoding="utf-8")
resets = (root / "js/settings/SettingsResets.js").read_text(encoding="utf-8")
widget = (root / "components/settings/SettingsWidget.qml").read_text(encoding="utf-8")
navigation = (root / "components/settings/SettingsNavigationController.qml").read_text(encoding="utf-8")
registry = (root / "js/settings/SettingsPageRegistry.js").read_text(encoding="utf-8")
section = (root / "components/settings/sections/SettingsVolumeSection.qml").read_text(encoding="utf-8")
volumes = (root / "components/Volumes.qml").read_text(encoding="utf-8")
shell = (root / "shell.qml").read_text(encoding="utf-8")
check = (root / "CHECK.sh").read_text(encoding="utf-8")

assert 'property string animationVolumeStreamsVisibilityStyle: "fade"' in config
assert 'property int volumeStreamsAnimationDuration: 250' in config
assert 'property string animationVolumeMorphProfile: "expressive"' in config
assert 'animationVolumeStreamsVisibilityStyle: "fade"' in defaults
assert 'volumeStreamsAnimationDuration: 250' in defaults
assert 'animationVolumeMorphProfile: "expressive"' in defaults
assert '"animationVolumeStreamsVisibilityStyle"' in apply
assert '["volumeStreamsAnimationDuration", 0, 5000]' in apply
assert 'animationVolumeStreamsVisibilityStyle: config.animationVolumeStreamsVisibilityStyle' in persist
assert 'animationVolumeMorphProfile: config.animationVolumeMorphProfile' in persist
assert 'volumeStreamsAnimationDuration: config.volumeStreamsAnimationDuration' in persist

volume_reset = resets.split('function resetVolumeSettings', 1)[1].split('function resetTimerSettings', 1)[0]
assert '"animationVolumeStreamsVisibilityStyle"' in volume_reset
assert '"animationVolumeMorphProfile"' in volume_reset
assert '"volumeStreamsAnimationDuration"' in volume_reset
volume_profile = resets.split('} else if (moduleName === "volumes") {', 1)[1].split('} else if (moduleName === "player") {', 1)[0]
assert '"animationVolumeStreamsVisibilityStyle"' in volume_profile
assert '"animationVolumeMorphProfile"' in volume_profile
assert '"volumeStreamsAnimationDuration"' in volume_profile

assert '{ id: "volume", saveScope: "volume", subTabs: ["Иконки", "Общие", "Полосы", "Потоки", "Адаптивность", "Анимация"] }' in registry
assert '{ keys: ["animationVolumeStreamsVisibilityStyle", "animationVolumeMorphProfile", "volumeStreamsAnimationDuration"] }' in navigation
assert 'visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 5' in section
assert 'SettingsAnimationGroup {' in section
assert 'profile: Config.animationVolumeMorphProfile' in section
assert 'property var values: ["fade", "slideLeft", "slideRight", "slideUp", "slideDown"]' in section
assert 'Config.animationVolumeStreamsVisibilityStyle' in section
assert 'Config.volumeStreamsAnimationDuration' in section

assert 'readonly property int streamAnimationDuration:' in volumes
assert 'Behavior on animatedAdaptiveHeight' in volumes
assert 'Behavior on height' in volumes
assert 'streamListViewportTargetHeight' in volumes
assert 'Config.animationVolumeStreamsVisibilityStyle === "fade"' in volumes
assert 'Config.animationVolumeStreamsVisibilityStyle === "slideLeft"' in volumes
assert 'Config.animationVolumeStreamsVisibilityStyle === "slideRight"' in volumes
assert 'Config.animationVolumeStreamsVisibilityStyle === "slideUp"' in volumes
assert 'Config.animationVolumeStreamsVisibilityStyle === "slideDown"' in volumes
assert 'Config.animationDurationForProfile(' in volumes
assert 'Config.animationEasingType(Config.animationVolumeMorphProfile' in volumes
assert 'Config.animationBezierCurve(Config.animationVolumeMorphProfile' in volumes
assert 'contentHeight: Math.min(Config.volumeMaxHeight, volumesWidget.animatedAdaptiveHeight)' in shell

assert 'test_volume_stream_animation_settings.sh' in check
assert 'test_volume_animation_settings.sh' in check
print("Volume stream animation settings, profile/reset persistence and animated layout: OK")
PY
