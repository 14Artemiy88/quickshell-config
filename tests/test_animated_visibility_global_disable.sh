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

allowed = qml.split("function animationAllowed()", 1)[1].split("function applyImmediate()", 1)[0]
assert "Config.animationsEnabled" in allowed and "return Config.animationsEnabled" in allowed, "global disable must prevent every visibility transition"
assert "effectiveAnimationStyle" not in qml and "respectGlobalAnimations" not in qml + timer, "do not substitute fade or let a module opt out of the global toggle"
block = qml.split("function handleAnimationAvailabilityChange()", 1)[1].split("function startTransition()", 1)[0]
assert "if (root.running && (!Config.animationsEnabled || !Config.animationAppearanceEnabled))" in block
assert "applyImmediate(root.shown)" in block
assert "function onAnimationsEnabledChanged()" in qml and "root.handleAnimationAvailabilityChange()" in qml
duration = qml.split("function handleDurationChange()", 1)[1].split("function handleAnimationAvailabilityChange()", 1)[0]
assert "!Config.animationsEnabled" in duration and "applyImmediate(root.shown)" in duration
config_duration = config.split("function animationDuration(", 1)[1].split("function easingType()", 1)[0]
assert "if (!animationsEnabled) return 0" in config_duration
assert "ignoreGlobalToggle" not in config_duration
active = options.split("function animationsActive()", 1)[1].split("function syncVisualState()", 1)[0]
assert "return Config.animationsEnabled" in active, "TimerOptions must not keep fading when the master toggle is off"
assert "? Config.animationExpansionEnabled : Config.animationAppearanceEnabled" not in active
assert "if (!animationsActive())" in options and "visualTransition.stop()" in options
assert 'Config.animationDuration(baseDuration, "appearance")' in options
assert 'Config.animationDuration(baseDuration, "expansion")' in options
assert 'Config.animationDuration(Config.animationCalendarVisibilityStyle === "fade" ? Config.animationCalendarFadeDuration : Config.animationCalendarSlideDuration, "appearance")' in shell
assert 'Config.animationDuration(280, "appearance")' in shell
assert 'Config.animationDuration(300, "appearance")' in shell
# Hard-gate module-specific visibility styles too. This prevents a configured
# "fade" style from surviving the master switch even if a custom duration or
# stale animation state slips through the generic primitive.
assert 'animationStyle: Config.animationsEnabled ? Config.animationCalendarVisibilityStyle : "none"' in shell
assert 'animationStyle: Config.animationsEnabled ? Config.animationMopidyVisibilityStyle : "none"' in shell
assert 'animationStyle: Config.animationsEnabled ? Config.animationSettingsVisibilityStyle : "none"' in shell
assert timer.count('animationStyle: Config.animationsEnabled ? Config.animationTimerVisibilityStyle : "none"') == 2, "both timer and alarm button groups must bypass visibility animations when disabled"
# The launcher had a separate set of hard-coded entrance and hover durations.
# Route these through the same master/category duration function too.
assert 'duration: Config.animationsEnabled ? Config.animationDuration(180, "movement") : 0' in launcher, "launcher entrance movement must honor global disable"
assert 'duration: Config.animationsEnabled ? Config.animationDuration(180, "size") : 0' in launcher, "launcher entrance scale must honor global disable"
assert 'duration: Config.animationsEnabled ? Config.animationDuration(140, "appearance") : 0' in launcher, "launcher entrance opacity must honor global disable"
assert 'duration: Config.animationsEnabled ? Config.animationDuration(110, "size") : 0' in launcher, "launcher hover-scale animations must honor global disable"
assert not any(token in launcher for token in ('duration: 180', 'duration: 140', 'duration: 120', 'duration: 110')), "no hard-coded launcher animation durations may bypass the master toggle"
print("Global Animations toggle hard-disables Calendar, Mopidy, TimerOptions, Settings Window, timer buttons and launcher transitions: OK")
PY
