#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VOLUMES="$ROOT/components/Volumes.qml"
CHECK="$ROOT/CHECK.sh"
python3 - "$VOLUMES" "$CHECK" <<'PYCODE'
from pathlib import Path
import sys
volumes_path, check_path = map(Path, sys.argv[1:])
source = volumes_path.read_text(encoding="utf-8")
check = check_path.read_text(encoding="utf-8")
checks = {
    "runtime expanded state starts from the configured default": "property bool streamsExpanded: Config.volumeShowStreams",
    "adaptive widget height follows runtime expanded state": "readonly property int effectiveStreamCount: streamsExpanded ? streamCount : 0",
    "stream viewport expands and collapses with runtime state": "height: root.streamsExpanded ? root.streamListViewportTargetHeight : 0",
    "right-click handler accepts only the secondary mouse button": "acceptedButtons: Qt.RightButton",
    "right-click toggles the stream list": "root.streamsExpanded = !root.streamsExpanded",
    "changing the setting updates the runtime state": "function onVolumeShowStreamsChanged() {\n            root.streamsExpanded = Config.volumeShowStreams",
}
for description, snippet in checks.items():
    if snippet not in source:
        raise SystemExit(f"Missing volume right-click behavior: {description}")
if "test_volume_right_click_stream_toggle.sh" not in check:
    raise SystemExit("Volume right-click stream-toggle test is not connected to CHECK.sh")
print("Volume right-click stream toggle: OK")
PYCODE
