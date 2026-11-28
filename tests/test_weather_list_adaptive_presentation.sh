#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="$ROOT/components/WeatherList.qml"
ITEM="$ROOT/components/WeatherForecastItem.qml"
fail() { echo "Weather list adaptive presentation: FAIL: $*" >&2; exit 1; }

grep -Fq 'presentationMode: root.presentationMode' "$LIST" || fail "WeatherList must pass the host presentation mode to each forecast item"
grep -Fq 'property string presentationMode: "regular"' "$ITEM" || fail "forecast item must default to the unchanged regular presentation"
grep -Fq 'if (root.presentationMode === "regular") return 1.0' "$ITEM" || fail "regular presentation must keep the original scale"
grep -Fq 'const widthScale = root.width / root.referenceSlotWidth' "$ITEM" || fail "responsive scale must use the actual per-slot width"
grep -Fq 'const maximum = root.presentationMode === "wide" ? 1.2 : 1.0' "$ITEM" || fail "wide mode must have a bounded enlargement while compact never enlarges"
grep -Fq 'elide: root.presentationMode === "compact" ? Text.ElideRight : Text.ElideNone' "$ITEM" || fail "compact day labels must avoid overflowing narrow slots"
grep -Fq 'effectiveHighTemperatureX: root.presentationMode === "compact" ? 0' "$ITEM" || fail "compact high temperature must reclaim the configured horizontal offset"
grep -Fq 'effectiveLowTemperatureX: root.presentationMode === "compact" ? 0' "$ITEM" || fail "compact low temperature must reclaim the configured horizontal offset"
grep -Fq 'elide: Text.ElideNone' "$ITEM" || fail "daily temperature values must not be elided in compact slots"
grep -Fq 'root.presentationMode === "regular"' "$ITEM" || fail "legacy icon width must be preserved in regular mode"
# Keep the existing transient count, saved count, and morph behavior untouched.
grep -Fq 'property int temporaryHourlyCount: -1' "$LIST" || fail "transient hourly count state was removed"
grep -Fq 'temporaryHourlyCount = next === Config.weatherHourlyCount ? -1 : next' "$LIST" || fail "hourly wheel must still clear its override at the saved count"
grep -Fq 'progress: forecastSlot.slotActive ? 1 : 0' "$LIST" || fail "hourly slot morph behavior was removed"
grep -Fq 'acceptedButtons: Qt.NoButton' "$LIST" || fail "hourly wheel handler must not consume mouse buttons"

python3 - "$LIST" "$ITEM" <<'PYTEST'
from pathlib import Path
import sys
pairs={")":"(","]":"[","}":"{"}
for name in sys.argv[1:]:
    s=Path(name).read_text(encoding="utf-8")
    stack=[]; quote=None; escaped=False; line=False; block=False; i=0
    while i < len(s):
        c=s[i]; n=s[i+1] if i+1 < len(s) else ""
        if line:
            if c=="\n": line=False
            i+=1; continue
        if block:
            if c=="*" and n=="/": block=False; i+=2; continue
            i+=1; continue
        if quote:
            if escaped: escaped=False
            elif c=="\\": escaped=True
            elif c==quote: quote=None
            i+=1; continue
        if c=="/" and n=="/": line=True; i+=2; continue
        if c=="/" and n=="*": block=True; i+=2; continue
        if c in ("'", '"', "`"): quote=c; i+=1; continue
        if c in "([{": stack.append(c)
        elif c in ")]}":
            if not stack or stack[-1] != pairs[c]:
                raise SystemExit(f"{name}: unbalanced {c} at {i}")
            stack.pop()
        i+=1
    if stack: raise SystemExit(f"{name}: unclosed delimiter")
item=Path(sys.argv[2]).read_text(encoding="utf-8")
if item.count("Image {") != 1:
    raise SystemExit("forecast icon must remain a direct Image element")
if item.count("MorphGeometry {") != 2:
    raise SystemExit("high/low temperature MorphGeometry nodes must be preserved")
print("Weather list responsive presentation bindings and QML delimiter structure: OK")
PYTEST

echo 'Weather list adaptive presentation test: OK'
