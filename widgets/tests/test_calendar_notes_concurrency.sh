#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/share"
export XDG_STATE_HOME="$HOME/state"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
export QS_PROJECT_DIR="$ROOT"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
SCRIPT="$ROOT/scripts/calendar_notes"

fail() { printf 'calendar notes concurrency test failed: %s\n' "$1" >&2; exit 1; }

[[ "$("$SCRIPT" get | jq -r 'type')" == object ]] || fail 'initial get did not create an object JSON file'
FILE="$XDG_DATA_HOME/quickshell-widgets/calendar-notes.json"
[[ -f "$FILE" ]] || fail 'notes JSON was not initialized'
[[ "$(stat -c '%a' "$FILE")" == 600 ]] || fail 'new notes file permissions are not 600'

# Different-date writes must not overwrite one another when many editor
# actions fire in parallel. Each operation reads and updates a JSON object.
pids=()
expected=()
for i in $(seq 1 40); do
  date_key="$(date -d "2026-01-01 +$((i - 1)) days" +%F)"
  expected+=("$date_key")
  "$SCRIPT" set "$date_key" "note-$i" >/dev/null &
  pids+=("$!")
done
for pid in "${pids[@]}"; do wait "$pid" || fail 'a concurrent note write failed'; done

for i in $(seq 1 40); do
  date_key="${expected[$((i - 1))]}"
  actual="$(jq -r --arg key "$date_key" '.[$key] // ""' "$FILE")"
  [[ "$actual" == "note-$i" ]] || fail "lost concurrent note update for $date_key (got '$actual')"
done
jq -e 'type == "object" and length == 40' "$FILE" >/dev/null || fail 'final notes JSON is invalid or missing entries'

# Readers always see one complete JSON object while writers are replacing it.
reader_failed="$TMP_ROOT/reader-failed"
(
  for _ in $(seq 1 20); do
    "$SCRIPT" get | jq -e 'type == "object"' >/dev/null || { : > "$reader_failed"; exit 1; }
  done
) & reader_pid=$!
pids=()
for i in $(seq 1 10); do
  date_key="$(date -d "2027-01-01 +$((i - 1)) days" +%F)"
  "$SCRIPT" set "$date_key" "parallel-$i" >/dev/null &
  pids+=("$!")
done
wait "$reader_pid" || fail 'reader observed invalid JSON during concurrent writes'
for pid in "${pids[@]}"; do wait "$pid" || fail 'parallel reader/writer operation failed'; done
[[ ! -e "$reader_failed" ]] || fail 'reader saw invalid JSON'

# Invalid pre-existing data must not be overwritten by a set operation.
printf '{invalid json\n' > "$FILE"
if "$SCRIPT" set 2027-02-01 replacement >/dev/null 2>&1; then
  fail 'set accepted invalid existing JSON'
fi
[[ "$(cat "$FILE")" == '{invalid json' ]] || fail 'invalid existing data was overwritten'
if find "$XDG_DATA_HOME/quickshell-widgets" -maxdepth 1 -type f \( \( -name '.calendar-notes.*' ! -name '.calendar-notes.lock' \) -o -name '.calendar-notes-init.*' \) | grep -q .; then
  fail 'temporary calendar-note files were leaked'
fi
[[ "$(stat -c '%a' "$XDG_DATA_HOME/quickshell-widgets/.calendar-notes.lock")" == 600 ]] || fail 'lock file permissions are not 600'

grep -Fq 'flock -x "$lock_fd"' "$SCRIPT" || fail 'calendar notes operations are not serialized'
grep -Fq 'mv -f -- "$tmp" "$FILE"' "$SCRIPT" || fail 'atomic note update missing'

echo 'Calendar notes concurrency: OK'
