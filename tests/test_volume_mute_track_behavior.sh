#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VOLUMES="$ROOT/components/Volumes.qml"
SET_VOLUME="$ROOT/scripts/set_volume"
COMMON="$ROOT/scripts/audio/common.sh"

for file in "$VOLUMES" "$SET_VOLUME" "$COMMON"; do
    test -f "$file" || { echo "Volume mute-track test: missing $file" >&2; exit 1; }
done

python3 - "$VOLUMES" "$SET_VOLUME" "$COMMON" <<'PYCODE'
from pathlib import Path
import sys
volumes, set_volume, common = [Path(name).read_text(encoding='utf-8') for name in sys.argv[1:]]
checks = {
    'muted main track renders empty outside drag': 'value: root.mainMuted && !root.mainDragging ? 0 : root.clampVolume(mainTrack.shownValue)',
    'main track release un-mutes on applying clicked level': 'root.applyMainVolume(root.mainDragValue, true)',
    'main track wheel adjustment also un-mutes': 'root.applyMainVolume(next, true)',
    'volume command has an explicit unmute option': 'unmute) set_main_mute 0 ;;',
    'explicit mute setter supports wpctl': 'wpctl set-mute @DEFAULT_AUDIO_SINK@ "$muted"',
    'explicit mute setter supports pactl': 'pactl set-sink-mute @DEFAULT_SINK@ "$muted"',
}
for description, snippet in checks.items():
    source = common if 'mute setter' in description else set_volume if 'volume command' in description else volumes
    if snippet not in source:
        raise SystemExit(f'Missing expected behavior: {description}')
if 'value: root.clampVolume(streamColumn.displayedValue)' not in volumes:
    raise SystemExit('Per-stream volume bars must use their independent displayed volume state')
if 'root.mainMuted' in volumes[volumes.index('Repeater {\n            id: streamRepeater'):]:
    raise SystemExit('Per-stream volume bars must not inherit main-output mute rendering')
PYCODE

# Exercise the real shell command with a mocked PipeWire CLI. Ensure volume and
# unmute happen sequentially in the same process, avoiding toggle races.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/wpctl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_WPCTL_LOG"
MOCK
chmod +x "$tmp/bin/wpctl"
export MOCK_WPCTL_LOG="$tmp/wpctl.log"
PATH="$tmp/bin:$PATH" bash "$SET_VOLUME" main 37 unmute
mapfile -t lines < "$MOCK_WPCTL_LOG"
[[ "${#lines[@]}" -eq 2 ]] || { echo "Expected volume + unmute commands" >&2; exit 1; }
[[ "${lines[0]}" == 'set-volume @DEFAULT_AUDIO_SINK@ 37%' ]] || { printf 'Unexpected first command: %s\n' "${lines[0]}" >&2; exit 1; }
[[ "${lines[1]}" == 'set-mute @DEFAULT_AUDIO_SINK@ 0' ]] || { printf 'Unexpected second command: %s\n' "${lines[1]}" >&2; exit 1; }
: > "$MOCK_WPCTL_LOG"
PATH="$tmp/bin:$PATH" bash "$SET_VOLUME" main 23
mapfile -t lines < "$MOCK_WPCTL_LOG"
[[ "${#lines[@]}" -eq 1 && "${lines[0]}" == 'set-volume @DEFAULT_AUDIO_SINK@ 23%' ]] || { echo "Normal volume changes should not alter mute state" >&2; exit 1; }

echo 'Volume mute-track behavior test: OK'
