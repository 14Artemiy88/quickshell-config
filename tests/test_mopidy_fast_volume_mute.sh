#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
REAL_JQ="$(command -v jq)"
export REAL_JQ HOME="$TMP/home" XDG_STATE_HOME="$TMP/state-home" QS_STATE_DIR="$TMP/state" MOPIDY_RPC_URL='http://mock.invalid/rpc'
mkdir -p "$TMP/bin" "$HOME" "$QS_STATE_DIR"
export PATH="$TMP/bin:$PATH" CURL_LOG="$TMP/curl-log" MOCK_NATIVE_MUTE=false MOCK_CURRENT_VOLUME=73
cat > "$TMP/bin/pactl" <<'STUB'
#!/usr/bin/env bash
# No Mopidy sink input: exercise the backend RPC fallback on ALSA/other paths.
if [[ "${1:-}" == "list" && "${2:-}" == "sink-inputs" ]]; then
  exit 0
fi
exit 1
STUB
cat > "$TMP/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
body=""
while (($#)); do
  case "$1" in
    -d) body="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
method="$("$REAL_JQ" -r 'if type=="array" then "batch" else .method // "" end' <<< "$body" 2>/dev/null || printf '')"
printf '%s\n' "$method" >> "$CURL_LOG"
case "$method" in
  core.mixer.get_mute) printf '{"jsonrpc":"2.0","id":1,"result":%s}\n' "$MOCK_NATIVE_MUTE" ;;
  core.mixer.get_volume) printf '{"jsonrpc":"2.0","id":1,"result":%s}\n' "$MOCK_CURRENT_VOLUME" ;;
  core.mixer.set_volume)
    vol="$("$REAL_JQ" -r '.params.volume' <<< "$body")"
    printf 'set_volume:%s\n' "$vol" >> "$CURL_LOG"
    MOCK_CURRENT_VOLUME="$vol"
    printf '{"jsonrpc":"2.0","id":1,"result":null}\n'
    ;;
  core.mixer.set_mute)
    val="$("$REAL_JQ" -r '.params.mute' <<< "$body")"
    printf 'set_mute:%s\n' "$val" >> "$CURL_LOG"
    MOCK_NATIVE_MUTE="$val"
    printf '{"jsonrpc":"2.0","id":1,"result":null}\n'
    ;;
  batch)
    printf '[{"id":1,"result":%s},{"id":2,"result":%s},{"id":3,"result":false},{"id":4,"result":false},{"id":5,"result":false}]\n' "$MOCK_CURRENT_VOLUME" "$MOCK_NATIVE_MUTE"
    ;;
  *) printf '{"jsonrpc":"2.0","id":1,"result":null}\n' ;;
esac
STUB
chmod +x "$TMP/bin/pactl" "$TMP/bin/curl"
fail() { echo "Mopidy fast volume mute: FAIL: $*" >&2; exit 1; }

# Muting uses the same volume path as volume changes and remembers the previous level.
: > "$CURL_LOG"
output="$(bash "$ROOT/scripts/mopidy/mixer.sh" mute true 73)"
[[ "$(cat "$QS_STATE_DIR/mopidy-volume-restore")" == 73 ]] || fail 'restore volume was not saved'
grep -Fqx 'set_volume:0' "$CURL_LOG" || fail 'mute did not request volume zero'
if grep -Fq 'set_mute:' "$CURL_LOG"; then fail 'normal mute still calls delayed set_mute'; fi
"$REAL_JQ" -e '.ok == true' <<< "$output" >/dev/null || fail "mute failed: $output"

# Unmute restores the saved level without the native mute call on the regular path.
: > "$CURL_LOG"
output="$(bash "$ROOT/scripts/mopidy/mixer.sh" mute false 73)"
grep -Fqx 'set_volume:73' "$CURL_LOG" || fail 'unmute did not restore saved volume'
if grep -Fq 'set_mute:' "$CURL_LOG"; then fail 'unmute used native set_mute despite native mute being false'; fi
"$REAL_JQ" -e '.ok == true' <<< "$output" >/dev/null || fail "unmute failed: $output"

# Positive volume changes update the restore value; zero keeps the last positive level.
bash "$ROOT/scripts/mopidy/mixer.sh" set 41 >/dev/null
[[ "$(cat "$QS_STATE_DIR/mopidy-volume-restore")" == 41 ]] || fail 'positive volume change did not update restore value'
bash "$ROOT/scripts/mopidy/mixer.sh" set 0 41 >/dev/null
[[ "$(cat "$QS_STATE_DIR/mopidy-volume-restore")" == 41 ]] || fail 'zero volume overwrote restore value'
MOCK_CURRENT_VOLUME=0
status="$(bash "$ROOT/scripts/mopidy/status.sh" state)"
"$REAL_JQ" -e '.mixer.volume == 0 and .mixer.restore_volume == 41' <<< "$status" >/dev/null || fail "status does not expose the saved unmute volume: $status"

# Existing native mute from an older build is cleared when unmuting.
MOCK_NATIVE_MUTE=true
: > "$CURL_LOG"
bash "$ROOT/scripts/mopidy/mixer.sh" mute false 41 >/dev/null
grep -Fqx 'set_mute:false' "$CURL_LOG" || fail 'legacy native mute was not cleared'
grep -Fqx 'set_volume:41' "$CURL_LOG" || fail 'legacy unmute did not restore volume'

python3 - "$ROOT/components/mopidy/Mopidy.qml" "$ROOT/components/mopidy/MopidyTopPanel.qml" <<'PY'
from pathlib import Path
import sys
qml=Path(sys.argv[1]).read_text()
panel=Path(sys.argv[2]).read_text()
checks={
 'mixer restore level state': 'property int mopidyRestoreVolume: -1' in qml,
 'pending target suppresses stale polling': 'root.pendingMixerTargetVolume' in qml and 'mixerPendingRefreshTimer.restart()' in qml,
 'mute button uses volume-based fast path': '"mute", "true", String(root.mopidyRestoreVolume)' in qml,
 'volume percentage remains stable while muted': 'controller.mopidyMuted && controller.mopidyRestoreVolume > 0' in panel,
}
missing=[name for name,ok in checks.items() if not ok]
if missing: raise SystemExit('missing: '+', '.join(missing))
print('Mopidy fast volume mute UI: OK')
PY

echo 'Mopidy fast volume mute: OK'
