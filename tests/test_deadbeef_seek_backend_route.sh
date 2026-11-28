#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/playerctl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$PLAYERCTL_CALL_LOG"
if [[ "$1" == "-p" && "$2" == "DeaDBeeF" && "$3" == "metadata" && "$4" == "mpris:length" ]]; then
    if [[ "${MOCK_EMPTY_LENGTH:-0}" == "1" ]]; then
        exit 1
    fi
    printf '%s\n' "240000000"
    exit 0
fi
if [[ "$1" == "-p" && "$2" == "DeaDBeeF" && "$3" == "position" && "$4" == "120.000000" ]]; then
    exit 0
fi
exit 1
MOCK
chmod +x "$TMP/bin/playerctl"
export PATH="$TMP/bin:$PATH"
export PLAYERCTL_CALL_LOG="$TMP/playerctl.log"

# DeaDBeeF MPRIS exposes DeaDBeeF as its service suffix, not the normalized internal ID.
"$ROOT/scripts/player_pausing" position 50 deadbeef 240000
grep -Fq -- '-p DeaDBeeF metadata mpris:length' "$PLAYERCTL_CALL_LOG"
grep -Fq -- '-p DeaDBeeF position 120.000000' "$PLAYERCTL_CALL_LOG"
if grep -Fq -- '-p deadbeef ' "$PLAYERCTL_CALL_LOG"; then
    echo 'seek used the normalized lowercase backend ID instead of the MPRIS service ID' >&2
    exit 1
fi

# When MPRIS metadata is unavailable, the CLI-provided duration is milliseconds.
# 50% of 240000ms must still be sent as 120 seconds.
: > "$PLAYERCTL_CALL_LOG"
export MOCK_EMPTY_LENGTH=1
"$ROOT/scripts/player_pausing" position 50 deadbeef 240000
grep -Fq -- '-p DeaDBeeF position 120.000000' "$PLAYERCTL_CALL_LOG"

printf 'DeaDBeeF absolute seek route: canonical MPRIS ID and millisecond fallback: OK\n'
