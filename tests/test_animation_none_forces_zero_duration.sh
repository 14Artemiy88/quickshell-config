#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
qml = (root / "components/primitives/AnimatedVisibility.qml").read_text(encoding="utf-8")
shell = (root / "shell.qml").read_text(encoding="utf-8")
timer = (root / "components/TimerWidget.qml").read_text(encoding="utf-8")
options = (root / "components/TimerOptions.qml").read_text(encoding="utf-8")
start = qml.split("function startTransition()", 1)[1].split("ParallelAnimation {\n        id: showTransition", 1)[0]
assert 'if (root.animationStyle === "none")' in start
assert start.index('if (root.animationStyle === "none")') < start.index("var wasRunning = root.running")
none_branch = start.split('if (root.animationStyle === "none")', 1)[1].split("var wasRunning = root.running", 1)[0]
assert 'activeAnimationStyle = "none"' in none_branch
assert "activeDuration = 0" in none_branch
assert "applyImmediate(root.shown)" in none_branch
handler = qml.split("function handleAnimationStyleChange()", 1)[1].split("function handleDurationChange()", 1)[0]
assert 'if (root.animationStyle === "none")' in handler
assert "activeDuration = 0" in handler and "applyImmediate(root.shown)" in handler
assert 'duration: Config.animationCalendarVisibilityStyle === "none" ? 0 :' in shell
assert 'duration: Config.animationMopidyVisibilityStyle === "none" ? 0 :' in shell
assert 'duration: Config.animationSettingsVisibilityStyle === "none" ? 0 :' in shell
assert timer.count('duration: Config.animationTimerVisibilityStyle === "none" ? 0 : Config.animationDuration(') >= 2
assert 'if (!animationsActive())' in options and 'opacity = targetOpacity' in options
assert 'Config.animationTimerVisibilityStyle !== "none"' in options
print("Animation style `none` forces zero duration and immediate state for every module: OK")
PY
