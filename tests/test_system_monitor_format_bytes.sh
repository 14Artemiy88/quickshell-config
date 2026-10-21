#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/common.sh"
fail() { echo "System monitor byte formatter: FAIL: $*" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
# Fail the test if either formatter reintroduces an AWK process.
cat > "$TMP/bin/awk" <<'MOCK'
#!/usr/bin/env bash
echo called >> "$AWK_CALLED_FILE"
exit 97
MOCK
chmod +x "$TMP/bin/awk"
export AWK_CALLED_FILE="$TMP/awk-called"
PATH="$TMP/bin:$PATH"
export PATH

assert_format() {
    local input="$1" expected="$2" actual
    actual="$(format_bytes "$input")"
    [[ "$actual" == "$expected" ]] || fail "format_bytes($input) expected '$expected', got '$actual'"
}

assert_format 0 '0 B'
assert_format 1023 '1023 B'
assert_format 1024 '1.00 KB'
assert_format 1536 '1.50 KB'
assert_format 1048575 '1023.99 KB'
assert_format 1048576 '1.00 MB'
assert_format 1234567890 '1.14 GB'
assert_format 1099511627776 '1.00 TB'
assert_format 1099511627775 '1023.99 GB'
assert_format 00001024 '1.00 KB'
assert_format '' '0 B'
assert_format 'not-a-number' '0 B'
assert_format -5 '0 B'
assert_format 123.45 '123 B'
[[ ! -e "$AWK_CALLED_FILE" ]] || fail 'format_bytes invoked awk'

# Exercise the same-shell batch path as network_stat and check boundaries.
format_bytes_batch_values 0 1023 1024 1536 1048575 1048576 1234567890 1099511627776 '' bad 123.45 -5
expected=('0 B' '1023 B' '1.00 KB' '1.50 KB' '1023.99 KB' '1.00 MB' '1.14 GB' '1.00 TB' '0 B' '0 B' '123 B' '0 B')
[[ "${#FORMATTED_BYTES_BATCH[@]}" -eq "${#expected[@]}" ]] || fail 'same-shell batch formatter returned the wrong number of values'
for i in "${!expected[@]}"; do
    [[ "${FORMATTED_BYTES_BATCH[$i]}" == "${expected[$i]}" ]] || fail "batch value $i expected '${expected[$i]}', got '${FORMATTED_BYTES_BATCH[$i]}'"
done
[[ ! -e "$AWK_CALLED_FILE" ]] || fail 'batch formatter invoked awk'

echo 'System monitor byte formatter without external processes: OK'
