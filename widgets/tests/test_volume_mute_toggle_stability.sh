#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VOLUMES="$ROOT/components/Volumes.qml"
SET_MUTE="$ROOT/scripts/set_mute"
COMMON="$ROOT/scripts/audio/common.sh"
CHECK="$ROOT/CHECK.sh"
for file in "$VOLUMES" "$SET_MUTE" "$COMMON" "$CHECK"; do
    test -f "$file" || { echo "Volume mute-toggle test: missing $file" >&2; exit 1; }
done

python3 - "$VOLUMES" "$SET_MUTE" "$CHECK" <<'PYCODE'
from pathlib import Path
import sys
volumes_path, set_mute_path, check_path = map(Path, sys.argv[1:])
volumes = volumes_path.read_text(encoding='utf-8')
set_mute = set_mute_path.read_text(encoding='utf-8')
check = check_path.read_text(encoding='utf-8')
checks = {
    'toggle tracks the latest pending target for rapid clicks': 'root.mainMuteHasPending ? root.mainPendingMuted : root.mainMuted',
    'mute state is updated optimistically': 'root.expectMainMuteState(nextMuted)',
    'uses explicit target-state command, not toggle': '"/scripts/set_mute", nextMuted ? "1" : "0"',
    'stale backend state is ignored while pending': 'mainMuted = mainPendingMuted',
    'pending state expires to recover from backend failure': 'Date.now() < mainMutePendingUntil',
    'refresh is delayed instead of restarting a live poll': 'volumeMuteRefreshTimer.restart()',
}
for message, snippet in checks.items():
    if snippet not in volumes:
        raise SystemExit(f'Missing volume mute stability behavior: {message}')
if 'toggle_mute' in volumes:
    raise SystemExit('Volume icon still uses a race-prone toggle command')
if 'volumePoll.running = false' in volumes[volumes.index('id: mainVolumeIcon'):volumes.index('id: mainTrack')]:
    raise SystemExit('Mute click must not cancel an in-flight volume poll')
if 'set_main_mute "$value"' not in set_mute:
    raise SystemExit('set_mute must apply an explicit mute target')
if 'test_volume_mute_toggle_stability.sh' not in check:
    raise SystemExit('Mute-toggle stability test is not connected to CHECK.sh')
print('Volume mute toggle stability: pending-state guard and explicit mute command OK')
PYCODE

# Exercise explicit mute with a mocked PipeWire CLI; no toggle operation may be used.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/wpctl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_WPCTL_LOG"
MOCK
chmod +x "$tmp/bin/wpctl"
export MOCK_WPCTL_LOG="$tmp/wpctl.log"
PATH="$tmp/bin:$PATH" bash "$SET_MUTE" 1
PATH="$tmp/bin:$PATH" bash "$SET_MUTE" 0
mapfile -t lines < "$MOCK_WPCTL_LOG"
[[ "${#lines[@]}" -eq 2 ]] || { echo "Expected two explicit mute commands" >&2; exit 1; }
[[ "${lines[0]}" == 'set-mute @DEFAULT_AUDIO_SINK@ 1' ]] || { echo "Mute-on command was not explicit" >&2; exit 1; }
[[ "${lines[1]}" == 'set-mute @DEFAULT_AUDIO_SINK@ 0' ]] || { echo "Mute-off command was not explicit" >&2; exit 1; }
if grep -q 'toggle' "$MOCK_WPCTL_LOG"; then echo "Mute command must not toggle state" >&2; exit 1; fi

echo 'Volume mute-toggle stability test: OK'
