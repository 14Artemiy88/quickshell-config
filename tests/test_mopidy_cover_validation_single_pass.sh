#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/home" "$TMP_DIR/cache" "$TMP_DIR/runtime" "$TMP_DIR/config" "$TMP_DIR/data" "$TMP_DIR/state"
export HOME="$TMP_DIR/home"
export XDG_CACHE_HOME="$TMP_DIR/cache" XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state"
export TMP_DIR QS_PROJECT_DIR="$ROOT" MOPIDY_FILE_CALL_LOG="$TMP_DIR/file-calls" MOPIDY_CURL_CALL_LOG="$TMP_DIR/curl-calls"

cat > "$TMP_DIR/bin/file" <<'STUB'
#!/usr/bin/env bash
printf 'file\n' >> "$MOPIDY_FILE_CALL_LOG"
for target in "$@"; do :; done
if [[ -s "$target" ]] && IFS= read -r first_line < "$target" && [[ "$first_line" == MOCK_IMAGE:* ]]; then
    printf 'image/png\n'
else
    printf 'text/plain\n'
fi
STUB
cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
printf 'curl\n' >> "$MOPIDY_CURL_CALL_LOG"
out=''
while (($#)); do
    if [[ "$1" == '-o' ]]; then
        shift
        out="${1:-}"
    fi
    shift || true
done
[[ -n "$out" ]] || exit 2
printf 'MOCK_IMAGE:downloaded cover\n' > "$out"
STUB
chmod +x "$TMP_DIR/bin/file" "$TMP_DIR/bin/curl"
export PATH="$TMP_DIR/bin:$PATH"

bash -c '
  set -euo pipefail
  source "$QS_PROJECT_DIR/scripts/player.d/common.sh"
  source "$QS_PROJECT_DIR/scripts/mopidy/player_backend.sh"
  cache_dir="$QS_CACHE_DIR/mopidy-covers"
  mkdir -p "$cache_dir"

  seed_marker() {
    local track="$1" image_uri="$2" digest key
    digest=$(printf "%s" "$track" | sha256sum)
    key="${digest%% *}"
    printf "%s\n" "$image_uri" > "$cache_dir/$key.uri"
    printf "1\n" > "$cache_dir/$key.checked"
    printf "%s" "$key"
  }

  # A valid cached image should be validated exactly once per Player poll.
  track_uri="http://music.test/cover-cache-hit"
  key=$(seed_marker "$track_uri" "http://images.test/cover.png")
  cover_path="$cache_dir/$key.png"
  printf "MOCK_IMAGE:cached cover\n" > "$cover_path"
  : > "$MOPIDY_FILE_CALL_LOG"
  : > "$MOPIDY_CURL_CALL_LOG"
  for _ in {1..8}; do
    mopidy_cover_for_track "$track_uri" > "$TMP_DIR/result"
    [[ "$(<"$TMP_DIR/result")" == "$cover_path" ]] || { echo "cached cover path changed" >&2; exit 1; }
  done
  [[ "$(wc -l < "$MOPIDY_FILE_CALL_LOG")" -eq 8 ]] || { echo "valid warm-cache hit must call file exactly once per lookup" >&2; exit 1; }
  [[ ! -s "$MOPIDY_CURL_CALL_LOG" ]] || { echo "warm-cache hit unexpectedly launched curl" >&2; exit 1; }

  # Downloaded bytes are validated before rename; do not validate the same
  # file a second time after publication.
  track_uri="http://music.test/cover-download"
  key=$(seed_marker "$track_uri" "http://images.test/downloaded.png")
  cover_path="$cache_dir/$key.png"
  rm -f "$cover_path" "$cover_path.part."*
  : > "$MOPIDY_FILE_CALL_LOG"
  : > "$MOPIDY_CURL_CALL_LOG"
  mopidy_cover_for_track "$track_uri" > "$TMP_DIR/result"
  [[ "$(<"$TMP_DIR/result")" == "$cover_path" ]] || { echo "downloaded cover path changed" >&2; exit 1; }
  [[ -s "$cover_path" ]] || { echo "downloaded cover was not published" >&2; exit 1; }
  [[ "$(wc -l < "$MOPIDY_FILE_CALL_LOG")" -eq 1 ]] || { echo "downloaded image should be validated only before atomic rename" >&2; exit 1; }
  [[ "$(wc -l < "$MOPIDY_CURL_CALL_LOG")" -eq 1 ]] || { echo "expected a single image download" >&2; exit 1; }

  # Corrupt cached bytes still get removed and fetched again. The bad cached
  # file and the good temporary download each require one validation.
  track_uri="http://music.test/corrupt-cover-cache"
  key=$(seed_marker "$track_uri" "http://images.test/replacement.png")
  cover_path="$cache_dir/$key.png"
  printf "NOT_AN_IMAGE\n" > "$cover_path"
  : > "$MOPIDY_FILE_CALL_LOG"
  : > "$MOPIDY_CURL_CALL_LOG"
  mopidy_cover_for_track "$track_uri" > "$TMP_DIR/result"
  [[ "$(<"$TMP_DIR/result")" == "$cover_path" ]] || { echo "corrupt cache did not recover to the downloaded cover" >&2; exit 1; }
  [[ "$(wc -l < "$MOPIDY_FILE_CALL_LOG")" -eq 2 ]] || { echo "corrupt cache should validate bad entry and new temporary image once each" >&2; exit 1; }
  [[ "$(wc -l < "$MOPIDY_CURL_CALL_LOG")" -eq 1 ]] || { echo "corrupt cache should trigger one download" >&2; exit 1; }
' _
printf 'Mopidy cover validity checks are single-pass for cache hits and downloads: OK\n'
