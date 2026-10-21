#!/usr/bin/env bash
# Compare the prior Python URI-classification path with the Bash fast path.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACK_URI='http://music.test/stream/123'
ITERATIONS="${1:-3}"
TRIALS="${2:-5}"
source "$ROOT/scripts/mopidy/player_backend.sh"

legacy_local_track_path() {
    local uri="$1"
    command -v python3 >/dev/null 2>&1 || return 0
    python3 - "$uri" <<'PYURI'
import sys
from urllib.parse import urlsplit, unquote
uri = sys.argv[1]
try:
    parsed = urlsplit(uri)
    if parsed.scheme == "file" and parsed.netloc in ("", "localhost"):
        print(unquote(parsed.path))
    elif not parsed.scheme and uri.startswith("/"):
        print(unquote(parsed.path))
except Exception:
    pass
PYURI
}

measure() {
    local mode="$1" start end path i
    start="${EPOCHREALTIME/./}"
    for ((i=0; i<ITERATIONS; i++)); do
        if [[ "$mode" == before ]]; then
            path="$(legacy_local_track_path "$TRACK_URI")"
        else
            path="$(mopidy_local_track_path "$TRACK_URI")"
        fi
        [[ -z "$path" ]] || return 1
    done
    end="${EPOCHREALTIME/./}"
    printf '%s\n' "$((end - start))"
}

before=() after=()
for ((trial=1; trial<=TRIALS; trial++)); do
    before+=("$(measure before)")
    after+=("$(measure after)")
done
mid="$(((TRIALS + 1) / 2))"
before_us="$(printf '%s\n' "${before[@]}" | sort -n | sed -n "${mid}p")"
after_us="$(printf '%s\n' "${after[@]}" | sort -n | sed -n "${mid}p")"
printf 'iterations per trial: %s; trials: %s\n' "$ITERATIONS" "$TRIALS"
printf 'before: median %s ms; Python launches %s\n' "$((before_us / 1000))" "$((ITERATIONS * TRIALS))"
printf 'after:  median %s ms; Python launches 0\n' "$((after_us / 1000))"
