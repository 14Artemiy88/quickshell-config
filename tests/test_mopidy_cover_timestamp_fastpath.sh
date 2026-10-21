#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/home" "$TMP_DIR/cache" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state"
export HOME="$TMP_DIR/home"
export XDG_CACHE_HOME="$TMP_DIR/cache" XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state"
export QS_PROJECT_DIR="$ROOT" DATE_CALL_LOG="$TMP_DIR/date-calls" CURL_CALL_LOG="$TMP_DIR/curl-calls"
REAL_DATE="$(command -v date)"
export REAL_DATE
cat > "$TMP_DIR/bin/date" <<'STUB'
#!/usr/bin/env bash
printf 'date\n' >> "$DATE_CALL_LOG"
exec "$REAL_DATE" "$@"
STUB
cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf 'curl\n' >> "$CURL_CALL_LOG"
exit 22
STUB
chmod +x "$TMP_DIR/bin/date" "$TMP_DIR/bin/curl"
export PATH="$TMP_DIR/bin:$PATH"

bash -c '
  set -euo pipefail
  source "$QS_PROJECT_DIR/scripts/player.d/common.sh"
  source "$QS_PROJECT_DIR/scripts/mopidy/player_backend.sh"
  # No image metadata: create a negative cache marker without making an RPC.
  MOCK_MOPIDY_IMAGES_JSON="{\"result\":{}}"
  mopidy_rpc() { printf "%s\n" "$MOCK_MOPIDY_IMAGES_JSON"; }
  track_uri="http://music.test/track-without-cover"
  cache_dir="$QS_CACHE_DIR/mopidy-covers"
  mkdir -p "$cache_dir"
  key_output=$(printf "%s" "$track_uri" | sha256sum)
  key="${key_output%% *}"
  marker="$cache_dir/$key.uri"
  stamp="$cache_dir/$key.checked"
  rm -f "$marker" "$stamp"
  : > "$DATE_CALL_LOG"
  result=$(mopidy_cover_for_track "$track_uri")
  [[ "$result" == "$DEFAULT_IMG" ]] || { echo "unexpected fallback after no-image response: $result" >&2; exit 1; }
  [[ -f "$marker" ]] && [[ -z "$(<"$marker")" ]] || { echo "negative cover marker not written" >&2; exit 1; }
  [[ -f "$stamp" ]] || { echo "negative cover timestamp not written" >&2; exit 1; }
  [[ "$(cat "$stamp")" =~ ^[0-9]+$ ]] || { echo "negative cover timestamp is not numeric" >&2; exit 1; }
  [[ ! -s "$DATE_CALL_LOG" ]] || { echo "date spawned on cache-marker write" >&2; exit 1; }

  # Fresh negative cache hit must return immediately without `date` as well.
  : > "$DATE_CALL_LOG"
  result=$(mopidy_cover_for_track "$track_uri")
  [[ "$result" == "$DEFAULT_IMG" ]] || { echo "unexpected fallback for negative cache hit: $result" >&2; exit 1; }
  [[ ! -s "$DATE_CALL_LOG" ]] || { echo "date spawned on fresh negative-cache hit" >&2; exit 1; }

  # The helper sets a caller-owned variable without command substitution. On
  # modern Bash, the EPOCHSECONDS fast path should not enter the date wrapper.
  mopidy_set_epoch_seconds epoch_value
  [[ "$epoch_value" =~ ^[0-9]+$ ]] || { echo "epoch helper returned invalid value" >&2; exit 1; }
  [[ ! -s "$DATE_CALL_LOG" ]] || { echo "date spawned on EPOCHSECONDS fast path" >&2; exit 1; }

  # Download-failure timestamps use the same fast path and suppress retries
  # for the established 30-second interval.
  track_uri="http://music.test/track-download-fails"
  cache_dir="$QS_CACHE_DIR/mopidy-covers"
  key_output=$(printf "%s" "$track_uri" | sha256sum)
  key="${key_output%% *}"
  marker="$cache_dir/$key.uri"
  stamp="$cache_dir/$key.checked"
  failed_stamp="$cache_dir/$key.download-failed"
  output_path="$cache_dir/$key.png"
  rm -f "$marker" "$stamp" "$failed_stamp" "$output_path"
  MOCK_MOPIDY_IMAGES_JSON="{\"result\":{\"$track_uri\":[{\"uri\":\"http://image.test/cover.png\",\"width\":640,\"height\":480}]}}"
  : > "$DATE_CALL_LOG"
  : > "$CURL_CALL_LOG"
  result=$(mopidy_cover_for_track "$track_uri")
  [[ "$result" == "$DEFAULT_IMG" ]] || { echo "unexpected fallback after failed image download: $result" >&2; exit 1; }
  [[ -f "$failed_stamp" && "$(cat "$failed_stamp")" =~ ^[0-9]+$ ]] || { echo "failed-download timestamp is missing or invalid" >&2; exit 1; }
  [[ ! -s "$DATE_CALL_LOG" ]] || { echo "date spawned while writing failed-download timestamp" >&2; exit 1; }
  [[ "$(wc -l < "$CURL_CALL_LOG")" -eq 1 ]] || { echo "expected one mocked download attempt" >&2; exit 1; }

  : > "$DATE_CALL_LOG"
  result=$(mopidy_cover_for_track "$track_uri")
  [[ "$result" == "$DEFAULT_IMG" ]] || { echo "unexpected fallback for fresh failed-download cache" >&2; exit 1; }
  [[ ! -s "$DATE_CALL_LOG" ]] || { echo "date spawned on fresh failed-download cache hit" >&2; exit 1; }
  [[ "$(wc -l < "$CURL_CALL_LOG")" -eq 1 ]] || { echo "failed-download cache retried too early" >&2; exit 1; }
'
printf 'Mopidy artwork cache timestamps use EPOCHSECONDS without launching date: OK\n'
