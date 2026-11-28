#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
source = (root / "components/TimerWidget.qml").read_text(encoding="utf-8")
for morph_id, enabled_key, size_key, x_key in (
    ("timerIconMorph", "timerIconEnabled", "timerIconSize", "timerIconX"),
    ("alarmIconMorph", "timerAlarmIconEnabled", "timerAlarmIconSize", "timerAlarmIconX"),
):
    assert f"id: {morph_id}" in source, f"{morph_id} is missing"
    start = source.index(f"id: {morph_id}")
    end = source.index("\n        }", start)
    block = source[start:end]
    assert f"Config.{x_key} + 1" in block, f"{morph_id} must start one pixel inset"
    assert "28, 31" in block and "30, 33" in block, f"{morph_id} must interpolate a compact-to-full icon box"
    assert f"Config.{enabled_key} && root.controlsMode === 0 ? 1 : 0" in block
    assert "normalizedProgress > 0.001" in block, f"{morph_id} must stay alive through exit"
    assert "Config.animationDuration(Config.timerButtonIconFadeDuration, \"appearance\")" in block
    assert f"opacity: {morph_id}.normalizedProgress" in block
    assert f"font.pixelSize: Config.uiFontSize(Config.{size_key})" in block
    assert "clip:" not in block, f"{morph_id} must not clip its glyph"
assert "Behavior on opacity" not in source, "legacy fade-only icon behavior must be removed"
print("Timer/alarm icon MorphGeometry transitions: OK")
PY
