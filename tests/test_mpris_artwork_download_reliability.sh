#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/runtime"
export XDG_RUNTIME_DIR="$TMP_DIR/runtime"
export XDG_CONFIG_HOME="$TMP_DIR/config"
export XDG_DATA_HOME="$TMP_DIR/data"
export XDG_STATE_HOME="$TMP_DIR/state"
export XDG_CACHE_HOME="$TMP_DIR/cache"
export CURL_URL_LOG="$TMP_DIR/curl-urls.log"
export CURL_ARGS_LOG="$TMP_DIR/curl-args.log"
export CURL_FAIL=0
export PATH="$TMP_DIR/bin:$PATH"

cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" >> "$CURL_ARGS_LOG"
output=""
url=""
while (($#)); do
    case "$1" in
        --output|-o) output="$2"; shift 2 ;;
        *) url="$1"; shift ;;
    esac
done
printf '%s\n' "$url" >> "$CURL_URL_LOG"
if [[ "${CURL_DELAY:-0}" != "0" ]]; then sleep "$CURL_DELAY"; fi
[[ "${CURL_FAIL:-0}" == "1" ]] && exit 28
[[ -n "$output" ]] || exit 2
printf 'fake-downloaded-image:%s\n' "$url" > "$output"
STUB
cat > "$TMP_DIR/bin/mogrify" <<'STUB'
#!/bin/bash
input="${@: -1}"
[[ -s "$input" ]] || exit 2
[[ "${MOGRIFY_FAIL:-0}" == "1" ]] && exit 1
printf 'fake-png:%s\n' "$(cat "$input")" > "${input%.*}.png"
STUB
cat > "$TMP_DIR/bin/playerctl" <<'STUB'
#!/bin/bash
printf '%s\n' 'https://cdn.example/metadata/cover.jpg'
STUB
chmod +x "$TMP_DIR/bin/curl" "$TMP_DIR/bin/mogrify" "$TMP_DIR/bin/playerctl"

source "$ROOT/scripts/player.d/common.sh"

# The full URL is hashed, so two different artwork URLs with the same basename
# cannot incorrectly share the same local cache entry.
first_url='https://cdn.example/album-one/cover.jpg?version=1'
second_url='https://cdn.example/album-two/cover.jpg?version=1'
first="$(get_image "$first_url")"
second="$(get_image "$second_url")"
[[ -s "$first" && -s "$second" ]] || { echo 'remote artwork was not cached' >&2; exit 1; }
[[ "$first" != "$second" ]] || { echo 'different artwork URLs collided in cache' >&2; exit 1; }
[[ "${first##*/}" =~ ^mpris-art-[a-f0-9]{32}\.png$ ]] || { echo "unexpected artwork cache name: $first" >&2; exit 1; }
[[ "$(wc -l < "$CURL_URL_LOG")" -eq 2 ]] || { echo 'expected two unique downloads' >&2; exit 1; }

# A cached URL is returned without another curl/mogrify invocation.
first_again="$(get_image "$first_url")"
[[ "$first_again" == "$first" ]] || { echo 'cached artwork path changed' >&2; exit 1; }
[[ "$(wc -l < "$CURL_URL_LOG")" -eq 2 ]] || { echo 'cached artwork was downloaded again' >&2; exit 1; }

# Remote fetches must carry explicit timeouts.
grep -F -- '--connect-timeout 2' "$CURL_ARGS_LOG" >/dev/null || { echo 'curl connect timeout missing' >&2; exit 1; }
grep -F -- '--max-time 4' "$CURL_ARGS_LOG" >/dev/null || { echo 'curl maximum time missing' >&2; exit 1; }
grep -F -- 'timeout 5s curl' "$ROOT/scripts/player.d/common.sh" >/dev/null || { echo 'overall artwork timeout missing' >&2; exit 1; }

# Failed fetches return the default image, clean temporary files, and are
# throttled so every Player poll does not retry a broken URL.
export CURL_FAIL=1
broken_url='https://cdn.example/unavailable/cover.jpg'
failed="$(get_image "$broken_url")"
[[ "$failed" == "$DEFAULT_IMG" ]] || { echo 'failed artwork did not return default image' >&2; exit 1; }
count_after_failure="$(wc -l < "$CURL_URL_LOG")"
failed_again="$(get_image "$broken_url")"
[[ "$failed_again" == "$DEFAULT_IMG" ]] || { echo 'throttled failure did not return default image' >&2; exit 1; }
[[ "$(wc -l < "$CURL_URL_LOG")" -eq "$count_after_failure" ]] || { echo 'failed URL retried before cooldown' >&2; exit 1; }
if find "$IMG_PATH" -maxdepth 1 -type f \( -name '.mpris-art-*.??????' -o -name '.mpris-art-*.png' \) -print -quit | grep -q .; then
    echo 'temporary artwork download file was left behind' >&2
    exit 1
fi

# A successful download followed by failed image conversion must also fall back,
# clean temporary files, and obey the retry cooldown.
export CURL_FAIL=0
export MOGRIFY_FAIL=1
bad_format_url='https://cdn.example/bad-format/cover.jpg'
failed_conversion="$(get_image "$bad_format_url")"
[[ "$failed_conversion" == "$DEFAULT_IMG" ]] || { echo 'conversion failure did not return default image' >&2; exit 1; }
count_after_conversion_failure="$(wc -l < "$CURL_URL_LOG")"
failed_conversion_again="$(get_image "$bad_format_url")"
[[ "$failed_conversion_again" == "$DEFAULT_IMG" ]] || { echo 'throttled conversion failure did not return default image' >&2; exit 1; }
[[ "$(wc -l < "$CURL_URL_LOG")" -eq "$count_after_conversion_failure" ]] || { echo 'conversion failure was retried before cooldown' >&2; exit 1; }
if find "$IMG_PATH" -maxdepth 1 -type f \
    \( -name '.mpris-art-*.download' -o -name '.mpris-art-*.png' \) -print -quit | grep -q .; then
    echo 'temporary file was left after failed conversion' >&2
    exit 1
fi

# Empty metadata lookup should go through the same safe cache path.
export CURL_FAIL=0
export MOGRIFY_FAIL=0
from_playerctl="$(get_image '')"
[[ -s "$from_playerctl" ]] || { echo 'playerctl artwork fallback was not cached' >&2; exit 1; }
[[ "$from_playerctl" =~ mpris-art-[a-f0-9]{32}\.png$ ]] || { echo 'playerctl fallback bypassed safe cache' >&2; exit 1; }

# Concurrent callers for the same URL must perform at most one fetch. The
# non-winning caller may use the fallback for this poll, but must not start a
# duplicate curl/ImageMagick pipeline or corrupt the winning cache entry.
export CURL_FAIL=0
export MOGRIFY_FAIL=0
export CURL_DELAY=0.4
concurrent_url='https://cdn.example/concurrent/cover.jpg'
count_before="$(wc -l < "$CURL_URL_LOG")"
bash -c 'source "$1"; get_image "$2"' _ "$ROOT/scripts/player.d/common.sh" "$concurrent_url" > "$TMP_DIR/concurrent-1.out" &
pid1=$!
bash -c 'source "$1"; get_image "$2"' _ "$ROOT/scripts/player.d/common.sh" "$concurrent_url" > "$TMP_DIR/concurrent-2.out" &
pid2=$!
wait "$pid1"
wait "$pid2"
count_after="$(wc -l < "$CURL_URL_LOG")"
[[ $((count_after - count_before)) -eq 1 ]] || { echo 'concurrent callers started duplicate artwork downloads' >&2; exit 1; }
concurrent_key="$(printf '%s' "$concurrent_url" | sha256sum | awk '{print substr($1, 1, 32)}')"
concurrent_image="$IMG_PATH/mpris-art-${concurrent_key}.png"
[[ -s "$concurrent_image" ]] || { echo 'concurrent artwork winner did not publish a cache image' >&2; exit 1; }
for output in "$TMP_DIR/concurrent-1.out" "$TMP_DIR/concurrent-2.out"; do
    value="$(cat "$output")"
    [[ "$value" == "$DEFAULT_IMG" || "$value" == "$concurrent_image" ]] || { echo "unexpected concurrent caller result: $value" >&2; exit 1; }
done
[[ -f "$IMG_PATH/.mpris-art-${concurrent_key}.lock" ]] || { echo 'per-URL artwork lock file missing' >&2; exit 1; }

grep -Fq 'flock -n "$lock_fd"' "$ROOT/scripts/player.d/common.sh" || { echo 'non-blocking artwork lock missing' >&2; exit 1; }

printf 'MPRIS artwork download reliability: OK\n'
