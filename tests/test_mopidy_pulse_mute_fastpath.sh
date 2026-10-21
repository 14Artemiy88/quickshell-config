#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
REAL_JQ="$(command -v jq)"
export REAL_JQ HOME="$TMP/home" XDG_STATE_HOME="$TMP/state-home" QS_STATE_DIR="$TMP/state"
export MOPIDY_RPC_URL='http://mock.invalid/rpc' PULSE_STATE="$TMP/pulse-state" PACTL_LOG="$TMP/pactl.log" CURL_LOG="$TMP/curl.log" MOCK_MIXER_VOLUME=73
mkdir -p "$TMP/bin" "$HOME" "$QS_STATE_DIR"
export PATH="$TMP/bin:$PATH"
printf 'no\n' > "$PULSE_STATE"
: > "$PACTL_LOG"
: > "$CURL_LOG"
fail() { echo "Mopidy Pulse mute fast path: FAIL: $*" >&2; exit 1; }

cat > "$TMP/bin/pactl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$PACTL_LOG"
if [[ "${1:-}" == "list" && "${2:-}" == "sink-inputs" ]]; then
  [[ "${NO_MOPIDY_STREAM:-0}" == 1 ]] && exit 0
  state="$(cat "$PULSE_STATE")"
  if [[ "${MOCK_PACTL_RU:-0}" == 1 ]]; then
    if [[ "$state" == yes ]]; then ru_state=да; else ru_state=нет; fi
    cat <<EOF_PACTL
Вход аудиоприёмника №42
    Без звука: $ru_state
    Properties:
        application.name = "Mopidy"
        application.process.binary = "python3"
        application.process.id = "4242"
        media.role = "music"
EOF_PACTL
  elif [[ "${MOCK_GENERIC_STREAM:-0}" == 1 ]]; then
    # Real GStreamer/Python streams can omit application.name and binary.
    # Keep the PID while earlier properties are empty to test exact columns.
    cat <<EOF_PACTL
Sink Input #42
    Mute: $state
    Properties:
        application.process.id = "4242"
        media.name = "GStreamer audio stream"
        media.role = "music"
EOF_PACTL
  else
    cat <<EOF_PACTL
Sink Input #42
    Mute: $state
    Properties:
        application.name = "Mopidy"
        application.process.binary = "python3"
        application.process.id = "4242"
        media.role = "music"
Sink Input #99
    Mute: no
    Properties:
        application.name = "Firefox"
        application.process.binary = "firefox"
        application.process.id = "9999"
EOF_PACTL
  fi
  exit 0
fi
if [[ "${1:-}" == "set-sink-input-mute" ]]; then
  [[ "${2:-}" == 42 ]] || exit 9
  if [[ "$3" == 1 ]]; then printf 'yes\n' > "$PULSE_STATE"; else printf 'no\n' > "$PULSE_STATE"; fi
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
printf '%s\n' "$body" >> "$CURL_LOG"
method="$("$REAL_JQ" -r 'if type=="array" then "batch" else .method // "" end' <<< "$body" 2>/dev/null || true)"
case "$method" in
  core.mixer.set_volume)
    if [[ "${MOCK_RPC_DELAY:-0}" != 0 ]]; then sleep "$MOCK_RPC_DELAY"; fi
    vol="$("$REAL_JQ" -r '.params.volume' <<< "$body")"
    printf '{"jsonrpc":"2.0","id":1,"result":%s}\n' "$vol"
    ;;
  batch)
    printf '[{"id":1,"result":%s},{"id":2,"result":false},{"id":3,"result":false},{"id":4,"result":false},{"id":5,"result":false}]\n' "${MOCK_MIXER_VOLUME:-73}"
    ;;
  *) printf '{"jsonrpc":"2.0","id":1,"result":false}\n' ;;
esac
STUB
cat > "$TMP/bin/ps" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "-p" && "${2:-}" == "4242" ]]; then
  printf '%s\n' '/nix/store/mock-mopidy/bin/python -m mopidy'
  exit 0
fi
exec /usr/bin/ps "$@"
STUB
chmod +x "$TMP/bin/pactl" "$TMP/bin/curl" "$TMP/bin/ps"

# Mute must be routed through pactl immediately and must not wait for the
# Mopidy software-mixer set_volume RPC.
: > "$PACTL_LOG"; : > "$CURL_LOG"
out="$(bash "$ROOT/scripts/mopidy/mixer.sh" mute true 73)"
[[ "$(cat "$PULSE_STATE")" == yes ]] || fail "direct mute did not change the sink input: $out"
grep -Fqx 'set-sink-input-mute 42 1' "$PACTL_LOG" || fail 'sink-input mute command was not issued'
[[ ! -s "$CURL_LOG" ]] || fail 'mute fast path unexpectedly called Mopidy RPC'
[[ "$(cat "$QS_STATE_DIR/mopidy-volume-restore")" == 73 ]] || fail 'restore level was not preserved'
"$REAL_JQ" -e '.ok == true and .mode == "pulse-stream" and .mute == true' <<< "$out" >/dev/null || fail "unexpected mute result: $out"

# Status must use the real sink-input mute state, not the unchanged Mopidy
# software-mixer get_mute result.
status="$(bash "$ROOT/scripts/mopidy/status.sh" state)"
"$REAL_JQ" -e '.mixer.volume == 73 and .mixer.mute == true and .mixer.pulse_mute_available == true' <<< "$status" >/dev/null || fail "status ignored PulseAudio mute: $status"
mixer_state="$(bash "$ROOT/scripts/mopidy/mixer.sh" get)"
"$REAL_JQ" -e '.volume == 73 and .mute == true' <<< "$mixer_state" >/dev/null || fail "mixer get ignored PulseAudio mute: $mixer_state"

# Unmute the sink input first; the RPC mixer synchronization may finish later,
# but must not be a prerequisite for audible output returning.
: > "$PACTL_LOG"; : > "$CURL_LOG"
out="$(MOCK_RPC_DELAY=1.5 timeout 1 bash "$ROOT/scripts/mopidy/mixer.sh" mute false 73)" || fail 'unmute action waited for the deliberately delayed RPC sync'
[[ "$(cat "$PULSE_STATE")" == no ]] || fail 'direct unmute did not change the sink input'
grep -Fqx 'set-sink-input-mute 42 0' "$PACTL_LOG" || fail 'sink-input unmute command was not issued'
for _ in {1..50}; do
  [[ -s "$CURL_LOG" ]] && break
  sleep 0.02
done
[[ -s "$CURL_LOG" ]] || fail 'mixer level synchronization was not attempted after direct unmute'
"$REAL_JQ" -e '.ok == true and .mode == "pulse-stream" and .mute == false' <<< "$out" >/dev/null || fail "unexpected unmute result: $out"
status="$(bash "$ROOT/scripts/mopidy/status.sh" state)"
"$REAL_JQ" -e '.mixer.volume == 73 and .mixer.mute == false' <<< "$status" >/dev/null || fail "status did not clear PulseAudio mute: $status"

# Localized pactl labels still resolve the correct stream.
printf 'no\n' > "$PULSE_STATE"
MOCK_PACTL_RU=1; export MOCK_PACTL_RU
: > "$PACTL_LOG"
out="$(bash "$ROOT/scripts/mopidy/mixer.sh" mute true 73)"
grep -Fqx 'set-sink-input-mute 42 1' "$PACTL_LOG" || fail 'Russian pactl labels did not resolve Mopidy stream'
unset MOCK_PACTL_RU
printf 'no\n' > "$PULSE_STATE"

# Generic GStreamer stream with empty application.name and binary must still
# match its Mopidy PID. The parser must preserve empty fields instead of
# collapsing tab delimiters and shifting PID out of its column.
MOCK_GENERIC_STREAM=1; export MOCK_GENERIC_STREAM
: > "$PACTL_LOG"; : > "$CURL_LOG"
diagnostic="$(bash "$ROOT/scripts/mopidy/mixer.sh" diagnose-pulse)"
grep -Fqx 'mopidy_matches=42' <<< "$diagnostic" || fail "diagnostic could not identify generic GStreamer stream: $diagnostic"
out="$(bash "$ROOT/scripts/mopidy/mixer.sh" mute true 73)"
grep -Fqx 'set-sink-input-mute 42 1' "$PACTL_LOG" || fail 'generic GStreamer stream was not matched through its Mopidy PID'
[[ ! -s "$CURL_LOG" ]] || fail 'generic GStreamer stream fell back to the delayed Mopidy RPC'
[[ "$(cat "$PULSE_STATE")" == yes ]] || fail 'generic stream mute did not change state'
unset MOCK_GENERIC_STREAM
printf 'no\n' > "$PULSE_STATE"

# If Mopidy does not expose a Pulse sink-input, preserve the old volume-based
# fallback for ALSA and other non-Pulse output backends.
NO_MOPIDY_STREAM=1; export NO_MOPIDY_STREAM
: > "$PACTL_LOG"; : > "$CURL_LOG"
out="$(bash "$ROOT/scripts/mopidy/mixer.sh" mute true 73)"
grep -Fqx 'set_volume:0' "$CURL_LOG" >/dev/null 2>&1 && :
# The mocked endpoint logs the request body rather than a prettified method.
grep -Fq '"method":"core.mixer.set_volume"' "$CURL_LOG" || fail 'no-stream fallback did not use Mopidy volume RPC'
if grep -Fq 'set-sink-input-mute 42 1' "$PACTL_LOG"; then fail 'fallback unexpectedly targeted the Mopidy sink input'; fi

# Migration from v782: if the stored software mixer is still zero, mute the
# Pulse stream first and restore the mixer level while the stream stays silent.
unset NO_MOPIDY_STREAM
: > "$PACTL_LOG"; : > "$CURL_LOG"
printf 'no\n' > "$PULSE_STATE"
MOCK_MIXER_VOLUME=0; export MOCK_MIXER_VOLUME
migration="$(bash "$ROOT/scripts/mopidy/mixer.sh" migrate-soft-mute 73)"
[[ "$(cat "$PULSE_STATE")" == yes ]] || fail 'legacy migration did not mute the Pulse stream first'
grep -Fqx 'set-sink-input-mute 42 1' "$PACTL_LOG" || fail 'legacy migration did not use direct stream mute'
grep -Fq '"method":"core.mixer.set_volume"' "$CURL_LOG" || fail 'legacy migration did not restore the software mixer level'
"$REAL_JQ" -e '.ok == true and .mode == "pulse-migration" and .volume == 73 and .mute == true' <<< "$migration" >/dev/null || fail "legacy software-mute migration failed: $migration"
MOCK_MIXER_VOLUME=73; export MOCK_MIXER_VOLUME

# QML should hold an optimistic mute target independently of the current
# software volume, and migrate a zero-volume state from v782 before enabling
# the next user unmute click.
python3 - "$ROOT/components/mopidy/Mopidy.qml" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
for item in ('pendingMixerTargetMuted', 'pendingMixerMatchVolume', 'root.pendingMixerTargetMuted\n                            ? actualMute', 'mixer.pulse_mute_available === true', 'migrate-soft-mute', 'mixerSoftMuteMigrationPending'):
    if item not in s:
        raise SystemExit('missing QML pending-mute guard: '+item)
print('Mopidy Pulse mute pending-state guard: OK')
PY

# Let the deliberately delayed background RPC finish before cleaning its mock files.
sleep 1.6
echo 'Mopidy Pulse mute fast path: OK'
