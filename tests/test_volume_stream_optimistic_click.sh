#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VOLUMES="$ROOT/components/Volumes.qml"
CHECK="$ROOT/CHECK.sh"
for file in "$VOLUMES" "$CHECK"; do
    test -f "$file" || { echo "Volume stream optimistic-click test: missing $file" >&2; exit 1; }
done

python3 - "$VOLUMES" "$CHECK" <<'PYCODE'
from pathlib import Path
import sys
volumes_path, check_path = map(Path, sys.argv[1:])
volumes = volumes_path.read_text(encoding="utf-8")
check = check_path.read_text(encoding="utf-8")
checks = {
    "pending stream targets live outside delegates and survive snapshot replacement": "property var streamPendingValues: ({})",
    "requested stream level is optimistically stored before issuing command": "pending[String(id)] = { value: next, until: Date.now() + 2000 }",
    "stream command still uses the original stream id": '"stream", String(next), String(id)',
    "track renders pending target instead of stale backend snapshot": "value: root.clampVolume(streamColumn.displayedValue)",
    "backend confirmation clears pending target": "Math.abs(Number(backendValue) - Number(pending.value)) <= 0.5",
    "pending target expires if backend never confirms": "Number(current[key]?.until ?? 0) > now",
    "wheel changes build from the currently displayed value": "const current = streamColumn.displayedValue",
    "click release applies the final drag target": "root.applyStreamVolume(modelData.num, streamColumn.dragValue)",
}
for description, snippet in checks.items():
    if snippet not in volumes:
        raise SystemExit(f"Missing stream-volume stability behavior: {description}")
if "onPendingVolumeChanged" in volumes:
    raise SystemExit("Pending-volume binding loop regression: onPendingVolumeChanged must not mutate the same dependency")
if "test_volume_stream_optimistic_click.sh" not in check:
    raise SystemExit("Stream-volume optimistic-click test is not connected to CHECK.sh")
print("Volume stream optimistic-click behavior: OK")
PYCODE
