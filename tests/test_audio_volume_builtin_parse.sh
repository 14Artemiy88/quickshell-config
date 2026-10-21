#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMON="$ROOT/scripts/audio/common.sh"
for file in "$COMMON" "$ROOT/CHECK.sh"; do
    test -f "$file" || { echo "Audio volume parser test: missing $file" >&2; exit 1; }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/wpctl-bin" "$tmp/pactl-bin" "$tmp/amixer-bin"

cat > "$tmp/wpctl-bin/wpctl" <<'MOCK'
#!/usr/bin/env bash
[[ "${1:-}" == get-volume ]] || exit 2
printf '%s\n' "${MOCK_WPCTL_OUTPUT:-}"
MOCK
cat > "$tmp/pactl-bin/pactl" <<'MOCK'
#!/usr/bin/env bash
case "${1:-} ${2:-}" in
    'get-sink-volume @DEFAULT_SINK@') printf '%s\n' "${MOCK_PACTL_VOLUME:-}" ;;
    'get-sink-mute @DEFAULT_SINK@') printf '%s\n' "${MOCK_PACTL_MUTE:-}" ;;
    *) exit 2 ;;
esac
MOCK
cat > "$tmp/amixer-bin/amixer" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "${MOCK_AMIXER_OUTPUT:-}"
MOCK
cat > "$tmp/awk" <<'MOCK'
#!/usr/bin/env bash
printf 'unexpected awk invocation: %s\n' "$*" >> "$MOCK_AWK_LOG"
exit 97
MOCK
chmod +x "$tmp/wpctl-bin/wpctl" "$tmp/pactl-bin/pactl" "$tmp/amixer-bin/amixer" "$tmp/awk"
export MOCK_AWK_LOG="$tmp/awk.log"
: > "$MOCK_AWK_LOG"

run_getter() {
    local bin_dir="$1" expected="$2" actual
    actual="$(PATH="$bin_dir:$tmp:/usr/bin:/bin" bash -c 'source "$1"; get_main_volume' _ "$COMMON")"
    [[ "$actual" == "$expected" ]] || {
        printf 'Expected "%s", got "%s" for %s\n' "$expected" "$actual" "$bin_dir" >&2
        exit 1
    }
}

# PipeWire output keeps nearest-integer percent rounding and mute detection.
export MOCK_WPCTL_OUTPUT='Volume: 0.555 [MUTED]'
run_getter "$tmp/wpctl-bin" '56 1'
export MOCK_WPCTL_OUTPUT='Volume: 0.50'
run_getter "$tmp/wpctl-bin" '50 0'
export MOCK_WPCTL_OUTPUT='Volume: 0.125'
run_getter "$tmp/wpctl-bin" '13 0'
export MOCK_WPCTL_OUTPUT='Volume: not-a-number'
run_getter "$tmp/wpctl-bin" '0 0'

# PulseAudio fallback must continue reading the first volume row and last mute token.
export MOCK_PACTL_VOLUME='Volume: front-left: 65536 / 61% / -1.00 dB, front-right: 65536 / 65% / -1.00 dB'
export MOCK_PACTL_MUTE='Mute: yes'
run_getter "$tmp/pactl-bin" '61 1'
export MOCK_PACTL_MUTE='Mute: no'
run_getter "$tmp/pactl-bin" '61 0'

# ALSA fallback keeps the Left channel's bracket percentage and on/off status.
export MOCK_AMIXER_OUTPUT=$'Simple mixer control '\''Master'\'',0\n  Front Left: Playback 65536 [78%] [on]\n  Front Right: Playback 65536 [80%] [on]'
run_getter "$tmp/amixer-bin" '78 0'
export MOCK_AMIXER_OUTPUT=$'  Front Left: Playback 65536 [78%] [off]\n  Front Right: Playback 65536 [80%] [on]'
run_getter "$tmp/amixer-bin" '78 1'

[[ ! -s "$MOCK_AWK_LOG" ]] || { cat "$MOCK_AWK_LOG" >&2; exit 1; }
if ! grep -q 'test_audio_volume_builtin_parse.sh' "$ROOT/CHECK.sh"; then
    echo 'Audio volume parser test is not connected to CHECK.sh' >&2
    exit 1
fi

echo 'Audio volume Bash parser: wpctl, pactl, amixer parity and zero AWK invocations OK'
