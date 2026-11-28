#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/playerctl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$PLAYERCTL_CALL_LOG"
if [[ "$1" == "-p" && "$3" == "metadata" && "$4" == "mpris:length" ]]; then
    if [[ "${MOCK_EMPTY_LENGTH:-0}" == "1" ]]; then
        exit 1
    fi
    printf '%s\n' "240000000"
    exit 0
fi
if [[ "$1" == "-p" && "$3" == "position" && "$4" == "120.000000" ]]; then
    exit 0
fi
exit 1
MOCK
chmod +x "$TMP/bin/playerctl"
export PATH="$TMP/bin:$PATH"
export PLAYERCTL_CALL_LOG="$TMP/playerctl.log"

# Normal MPRIS path: query length and seek the exact selected backend.
"$ROOT/scripts/player_pausing" position 50 org.telegram.desktop 240000000
grep -Fq -- '-p org.telegram.desktop metadata mpris:length' "$PLAYERCTL_CALL_LOG"
grep -Fq -- '-p org.telegram.desktop position 120.000000' "$PLAYERCTL_CALL_LOG"
if grep -Fq -- '-l' "$PLAYERCTL_CALL_LOG"; then
    echo 'seek must not run a second player discovery pass' >&2
    exit 1
fi

# Fallback path: backend duration is already MPRIS microseconds, not milliseconds.
: > "$PLAYERCTL_CALL_LOG"
export MOCK_EMPTY_LENGTH=1
"$ROOT/scripts/player_pausing" position 50 org.telegram.desktop 240000000
grep -Fq -- '-p org.telegram.desktop position 120.000000' "$PLAYERCTL_CALL_LOG"

if grep -Fq -- '-p spotify position' "$PLAYERCTL_CALL_LOG"; then
    echo 'seek must stay on the selected MPRIS backend' >&2
    exit 1
fi

echo 'Player absolute MPRIS seek route: exact backend ID, target seconds and duration fallback: OK'
