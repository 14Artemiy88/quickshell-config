#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CAVA stream filter: FAIL: $*" >&2; exit 1; }
script="$ROOT/scripts/cava"
[[ -x "$script" || -f "$script" ]] || fail "CAVA entry-point missing"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REAL_AWK="$(command -v awk)"
REAL_SED="$(command -v sed)"
cat > "$TMP/fixture" <<'FIXTURE'
1;2;3;
5;10;15

4;6;8;;
FIXTURE
cat > "$TMP/cava" <<'MOCK'
#!/usr/bin/env bash
cat "$CAVA_FIXTURE"
MOCK
cat > "$TMP/awk" <<'MOCK'
#!/usr/bin/env bash
printf 'awk\n' >> "$CAVA_FILTER_LOG"
exec "$CAVA_REAL_AWK" "$@"
MOCK
cat > "$TMP/sed" <<'MOCK'
#!/usr/bin/env bash
printf 'sed\n' >> "$CAVA_FILTER_LOG"
exec "$CAVA_REAL_SED" "$@"
MOCK
chmod +x "$TMP/cava" "$TMP/awk" "$TMP/sed"
export CAVA_FIXTURE="$TMP/fixture"
export CAVA_FILTER_LOG="$TMP/filter.log"
export CAVA_REAL_AWK="$REAL_AWK"
export CAVA_REAL_SED="$REAL_SED"
: > "$CAVA_FILTER_LOG"
PATH="$TMP:$PATH" bash "$script" 8 30 > "$TMP/output"

cat > "$TMP/expected" <<'EXPECTED'
[1,2,3]
[5,10,15]
[]
[4,6,8,]
EXPECTED
cmp -s "$TMP/expected" "$TMP/output" || {
    echo 'Expected:' >&2; cat "$TMP/expected" >&2
    echo 'Actual:' >&2; cat "$TMP/output" >&2
    fail "stream transformation changed output"
}
[[ "$(grep -c '^awk$' "$CAVA_FILTER_LOG" || true)" == 1 ]] || fail "expected one AWK filter invocation"
if grep -q '^sed$' "$CAVA_FILTER_LOG"; then fail "sed should not be launched by CAVA filter"; fi
if grep -Fq "| sed -u 's/;$//; s/;/,/g'" "$script"; then fail "old sed filter remains"; fi

echo 'CAVA stream filter single-process: OK'
