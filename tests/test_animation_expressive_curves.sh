#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import ast
import re
import sys
root = Path(sys.argv[1])
curves = (root / "js/AnimationCurves.js").read_text(encoding="utf-8")
config = (root / "Config.qml").read_text(encoding="utf-8")

expected = {
    "emphasized", "emphasizedAccel", "emphasizedDecel",
    "standard", "standardAccel", "standardDecel",
    "expressiveFastSpatial", "expressiveDefaultSpatial", "expressiveSlowSpatial",
    "expressiveFastEffects", "expressiveDefaultEffects", "expressiveSlowEffects",
}
found = set(re.findall(r'^    (\w+): \[', curves, re.M))
assert found == expected, f"curve library mismatch: missing={expected-found}, extra={found-expected}"
for name in expected:
    match = re.search(rf'^    {name}: (\[[^\n]+\]),?$', curves, re.M)
    assert match, f"missing curve data: {name}"
    values = ast.literal_eval(match.group(1).replace("2 / 15", str(2 / 15)).replace("1 / 6", str(1 / 6)).replace("5 / 24", str(5 / 24)))
    assert len(values) in (6, 12), f"{name} must contain one or two cubic Bezier segments"
    assert values[-2:] == [1, 1], f"{name} must end at (1,1)"
    assert all(isinstance(value, (int, float)) for value in values)
assert 'return get(direction === "exit" ? "emphasizedAccel" : "emphasizedDecel")' in curves
assert 'return AnimationCurves.forProfile(profile, phase)' in config
assert 'return AnimationCurves.get(name)' in config
assert 'return AnimationCurves.names()' in config
assert 'return Easing.BezierSpline' in config
# Existing profiles and legacy default remain untouched.
assert 'direction === "exit" ? Easing.InCubic : Easing.OutCubic' in config
assert 'direction === "exit" ? Easing.InQuad : Easing.OutQuad' in config
assert 'return Easing.OutCubic' in config
print("Expressive curve library, Bezier endpoints and legacy easing compatibility: OK")
PY
