#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CPU="$ROOT/components/CpuWidget.qml"
BAR="$ROOT/components/MetricBar.qml"
GRAPH="$ROOT/components/CpuGraph.qml"
fail() { echo "CPU adaptive presentation: FAIL: $*" >&2; exit 1; }
for file in "$CPU" "$BAR" "$GRAPH"; do test -f "$file" || fail "missing $file"; done

# CPU rows preserve the regular baseline, while compact mode caps the track to
# the host width and wide mode can use the additional horizontal space.
grep -Fq 'compactPresentation ? 190 : widePresentation ? 225 : 215' "$CPU" || fail "CPU frame height modes missing"
grep -Fq ': Config.cpuRowHeight' "$CPU" || fail "regular row-height baseline missing"
grep -Fq ': Config.cpuBarWidth' "$CPU" || fail "regular bar-width baseline missing"
grep -Fq 'widthBudget - 2 * effectiveCpuHorizontalMargin - effectiveCpuBarOffset - effectiveCpuBarRightSafety' "$CPU" || fail "compact track width does not reserve safe inner margins"
grep -Fq 'Math.max(Config.cpuBarWidth, Math.floor(widthBudget - 10 - effectiveCpuBarOffset - 5))' "$CPU" || fail "wide track does not use extra width"
grep -Fq 'anchors.margins: root.effectiveCpuHorizontalMargin' "$CPU" || fail "compact rows do not reserve additional edge padding"
grep -Fq 'clip: true' "$CPU" || fail "CPU bars are not clipped to the inner row viewport"
grep -Fq 'fillAvailableWidth && parent ? parent.width : 303' "$BAR" || fail "opt-in metric width following is missing"
grep -Fq 'fillAvailableWidth: true' "$CPU" || fail "CPU metrics do not opt into adaptive width"
grep -Fq 'width: root.barWidth' "$BAR" || fail "adaptive track width is not applied"

# Keep all cores/RAM and existing direction/animation wiring.
grep -Fq 'model: Config.cpuShowRam ? 9 : 8' "$CPU" || fail "CPU/RAM metric count changed"
grep -Fq 'direction: root.direction' "$BAR" || fail "metric direction wiring changed"
grep -Fq 'valueAnimationDuration: root.valueAnimationDuration' "$BAR" || fail "metric animation wiring changed"

# Graph retains the 51-sample history and mode-specific direction, adapting
# only slot/bar geometry and module height.
grep -Fq 'barCount: 51' "$GRAPH" || fail "graph sample count changed"
grep -Fq 'compactPresentation ? 70 : widePresentation ? 94 : 82' "$GRAPH" || fail "graph height modes missing"
grep -Fq 'available / 51' "$GRAPH" || fail "graph slot width is not constrained by host width"
grep -Fq 'effectiveGraphSlotWidth / configuredSlot' "$GRAPH" || fail "graph bars do not widen proportionally with their slots"
grep -Fq 'widthBudget > 315 || widePresentation' "$GRAPH" || fail "graph does not fill widths above the regular baseline"
python3 - "$GRAPH" <<'PYGRAPH'
configured_slot = 6
configured_bar = 2
for width in (350, 419, 420, 429, 600):
    available = max(51, width - 6)
    slot = max(1, available / 51)
    bar = min(slot, configured_bar * max(1, slot / configured_slot))
    assert abs(slot * 51 - available) < 0.001, (width, slot, available)
    assert bar > configured_bar, (width, slot, bar)
    assert abs((bar / slot) - (configured_bar / configured_slot)) < 0.001, (width, slot, bar)
for width in (240, 239, 220, 180):
    margin = 7
    safety = 8
    offset = min(35, max(24, round(width * .13)))
    bar = max(1, min(267, int(width - 2 * margin - offset - safety)))
    inner_width = width - 2 * margin
    assert offset + bar <= inner_width - safety, (width, offset, bar, inner_width)
PYGRAPH
grep -Fq 'CpuGraphData.normalizeHistory(parsed, 51)' "$GRAPH" || fail "history normalization changed"
grep -Fq 'Config.cpuGraphMode === "both"' "$GRAPH" || fail "graph mode selection changed"

echo "CPU adaptive presentation: OK"
