#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/common.sh"
fail() { echo "System monitor batch byte formatter: FAIL: $*" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REAL_AWK="$(command -v awk)"
mkdir -p "$TMP/bin"
cat > "$TMP/bin/awk" <<'MOCK'
#!/usr/bin/env bash
printf 'x' >> "$BATCH_AWK_CALLS"
exec "$BATCH_REAL_AWK" "$@"
MOCK
chmod +x "$TMP/bin/awk"
export BATCH_REAL_AWK="$REAL_AWK"
export BATCH_AWK_CALLS="$TMP/awk-calls"
PATH="$TMP/bin:$PATH"
export PATH

values=(0 1023 1024 1536 1048575 1048576 1234567890 1099511627776 '' 'not-a-number' 123.45 -5)
expected=()
for value in "${values[@]}"; do
    expected+=("$(format_bytes "$value")")
done

: > "$BATCH_AWK_CALLS"
mapfile -t actual < <(format_bytes_batch "${values[@]}")
[[ "${#actual[@]}" -eq "${#expected[@]}" ]] || fail "expected ${#expected[@]} output rows, got ${#actual[@]}"
for i in "${!expected[@]}"; do
    [[ "${actual[$i]}" == "${expected[$i]}" ]] || fail "input '${values[$i]}' expected '${expected[$i]}', got '${actual[$i]}'"
done
calls="$(wc -c < "$BATCH_AWK_CALLS")"
[[ "$calls" -eq 0 ]] || fail "batch formatter launched awk $calls times, expected 0"

: > "$BATCH_AWK_CALLS"
empty="$(format_bytes_batch)"
[[ -z "$empty" ]] || fail "empty batch should return empty output, got '$empty'"
[[ ! -s "$BATCH_AWK_CALLS" ]] || fail 'empty batch should not launch awk'

echo 'System monitor batch byte formatter: OK (format parity, no awk calls, empty-input fast path)'
