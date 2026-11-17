#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
qml = (root / "components/primitives/AnimatedVisibility.qml").read_text(encoding="utf-8")
config = (root / "Config.qml").read_text(encoding="utf-8")
options = (root / "components/TimerOptions.qml").read_text(encoding="utf-8")
timer = (root / "components/TimerWidget.qml").read_text(encoding="utf-8")
shell = (root / "shell.qml").read_text(encoding="utf-8")
launcher = (root / "components/launcher/Launcher.qml").read_text(encoding="utf-8")
widget = (root / "components/settings/SettingsWidget.qml").read_text(encoding="utf-8")
registry = (root / "js/settings/SettingsPageRegistry.js").read_text(encoding="utf-8")
general = (root / "components/settings/sections/SettingsGeneralSection.qml").read_text(encoding="utf-8")
apply = (root / "js/settings/SettingsApplyBehaviour.js").read_text(encoding="utf-8")
persist = (root / "js/settings/SettingsPersistence.js").read_text(encoding="utf-8")
allowed = qml.split("function animationAllowed()", 1)[1].split("function applyImmediate()", 1)[0]
assert 'root.activeAnimationStyle !== "none"' in allowed and "root.activeDuration > 0" in allowed
assert "Config.animationsEnabled" not in qml and "animationAppearanceEnabled" not in qml
style_handler = qml.split("function handleAnimationStyleChange()", 1)[1].split("function handleDurationChange()", 1)[0]
assert 'if (root.animationStyle === "none")' in style_handler and "applyImmediate(root.shown)" in style_handler
assert "handleAnimationAvailabilityChange" not in qml
assert "function animationDuration(baseMs, category)" in config
assert "animationsEnabled" not in config and "animationAppearanceEnabled" not in config
assert "if (!animationsEnabled) return 0" not in config
assert 'animationStyle: Config.animationCalendarVisibilityStyle' in shell
assert 'duration: Config.animationCalendarVisibilityStyle === \"none\" ? 0 :' in shell
assert 'animationStyle: Config.animationMopidyVisibilityStyle' in shell
assert 'duration: Config.animationMopidyVisibilityStyle === \"none\" ? 0 :' in shell
assert 'animationStyle: Config.animationSettingsVisibilityStyle' in shell
assert 'duration: Config.animationSettingsVisibilityStyle === \"none\" ? 0 :' in shell
assert 'animationStyle: Config.animationTimerVisibilityStyle' in timer
assert 'Config.animationTimerVisibilityStyle === "none" ? 0 :' in timer, "timer icon fades must also stop when module style is none"
active = options.split("function animationsActive()", 1)[1].split("function syncVisualState()", 1)[0]
assert 'Config.animationTimerOptionsVisibilityStyle !== "none"' in active
assert 'function onAnimationTimerOptionsVisibilityStyleChanged() { root.syncVisualState() }' in options
assert 'Config.animationTimerVisibilityStyle' not in active, 'options popup must use its own animation setting'
assert "Config.animationsEnabled" not in options
assert "Config.animationsEnabled" not in launcher
assert "Config.animationDuration(180, \"movement\")" in launcher
assert "Config.animationDuration(180, \"size\")" in launcher
assert '{ id: "general", saveScope: "general", subTabs: ["Интерфейс", "Профили", "Хранилища"] }' in registry
assert '["Интерфейс", "Анимации", "Профили"]' not in registry
assert 'text: "Анимации"' not in general
assert "animationsEnabled" not in apply and "animationAppearanceEnabled" not in apply
assert "animationsEnabled: config.animationsEnabled" not in persist
assert "animationAppearanceEnabled: config.animationAppearanceEnabled" not in persist
print('per-module and timer-options animation `none` disable transitions independently; obsolete global gates removed: OK')
PY
