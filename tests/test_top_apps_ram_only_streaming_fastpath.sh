#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'Top Apps RAM-only streaming fast path: FAIL: %s\n' "$*" >&2; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/runtime" "$TMP/proc"
REAL_CAT="$(command -v cat)"
REAL_MKTEMP="$(command -v mktemp)"
export REAL_CAT REAL_MKTEMP
export XDG_RUNTIME_DIR="$TMP/runtime"
export TOP_APPS_PROC_ROOT="$TMP/proc"
export MOCK_CAT_LOG="$TMP/cat-log"
export MOCK_SNAPSHOT_MKTEMP_LOG="$TMP/snapshot-mktemp-log"
: > "$MOCK_CAT_LOG"
: > "$MOCK_SNAPSHOT_MKTEMP_LOG"

cat > "$TMP/bin/ps" <<'MOCK_PS'
#!/usr/bin/env bash
printf '%s\n' \
  '101 1 4096 ram-app' \
  '202 1 2048 second-app'
MOCK_PS
cat > "$TMP/bin/cat" <<'MOCK_CAT'
#!/usr/bin/env bash
for arg in "$@"; do
    case "$arg" in
        */top-apps-current.*) printf 'cat\n' >> "$MOCK_CAT_LOG" ;;
    esac
done
exec "$REAL_CAT" "$@"
MOCK_CAT
cat > "$TMP/bin/mktemp" <<'MOCK_MKTEMP'
#!/usr/bin/env bash
for arg in "$@"; do
    case "$arg" in
        */top-apps-previous.*|*/top-apps-current.*)
            printf '%s\n' "${arg##*/}" >> "$MOCK_SNAPSHOT_MKTEMP_LOG" ;;
    esac
done
exec "$REAL_MKTEMP" "$@"
MOCK_MKTEMP
chmod +x "$TMP/bin/ps" "$TMP/bin/cat" "$TMP/bin/mktemp"
PATH="$TMP/bin:$PATH"
export PATH
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

uid="${UID:-$(id -u)}"
state="$XDG_RUNTIME_DIR/quickshell-top-apps-cpu-${uid}.tsv"
printf 'T\t999999\nP\t101\t12345\t800\n' > "$state"
snapshot="$(get_process_snapshot 0)" || fail 'RAM-only snapshot failed'
[[ "$snapshot" == $'ram-app\t0.0000\t4096\t101\t1\nsecond-app\t0.0000\t2048\t202\t1' ]] || fail "RAM-only rows changed: $snapshot"
[[ ! -s "$MOCK_CAT_LOG" ]] || fail 'RAM-only poll still launches cat to return an intermediate snapshot'
[[ ! -s "$MOCK_SNAPSHOT_MKTEMP_LOG" ]] || fail "RAM-only poll still creates CPU-only snapshot temp files: $(<"$MOCK_SNAPSHOT_MKTEMP_LOG")"
[[ "$(<"$state")" == $'T\t-1' ]] || fail "RAM-only poll did not reset the CPU baseline: $(<"$state")"

# An empty process snapshot must not replace the saved baseline, matching the
# established non-empty-snapshot contract.
cat > "$TMP/bin/ps" <<'MOCK_EMPTY_PS'
#!/usr/bin/env bash
exit 0
MOCK_EMPTY_PS
chmod +x "$TMP/bin/ps"
printf 'T\t123\nP\t303\t555\t10\n' > "$state"
snapshot="$(get_process_snapshot 0)" || fail 'empty RAM-only snapshot returned an error'
[[ -z "$snapshot" ]] || fail "empty process inventory should remain empty: $snapshot"
[[ "$(<"$state")" == $'T\t123\nP\t303\t555\t10' ]] || fail 'empty process inventory unexpectedly overwrote state'
[[ ! -s "$MOCK_CAT_LOG" && ! -s "$MOCK_SNAPSHOT_MKTEMP_LOG" ]] || fail 'empty RAM-only poll launched cat or created snapshot temp files'

echo 'Top Apps RAM-only streaming fast path: OK'
