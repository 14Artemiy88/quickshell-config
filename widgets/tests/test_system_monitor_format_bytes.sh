#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/system_monitor.d/common.sh"
fail() { echo "System monitor byte formatter: FAIL: $*" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
# If format_bytes attempts to call bc, make the test fail even on hosts where
# the real utility happens to be installed.
cat > "$TMP/bin/bc" <<'MOCK'
#!/usr/bin/env bash
echo called >> "$BC_CALLED_FILE"
exit 97
MOCK
chmod +x "$TMP/bin/bc"
export BC_CALLED_FILE="$TMP/bc-called"
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
assert_format '' '0 B'
assert_format 'not-a-number' '0 B'
[[ ! -e "$BC_CALLED_FILE" ]] || fail 'format_bytes still invoked bc'

echo 'System monitor byte formatter without bc: OK'
