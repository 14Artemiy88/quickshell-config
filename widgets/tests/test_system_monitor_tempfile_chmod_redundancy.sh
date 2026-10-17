#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# These files are all created by mktemp, whose default private mode is 0600.
# Keep permission enforcement on persistent lock files, but avoid starting a
# chmod process just to re-apply the same mode to every freshly-created temp.
if grep -Eq 'chmod[[:space:]]+600.*(previous_file|current_file|next_state|state_tmp|cache_tmp|time_tmp)' \
    "$ROOT/scripts/system_monitor.d/top_apps.sh" \
    "$ROOT/scripts/system_monitor.d/network_stat.sh" \
    "$ROOT/scripts/system_monitor.d/network_connections.sh"; then
    fail "redundant chmod for a freshly-created temporary file returned"
fi

grep -Fq 'mktemp "$runtime_dir/top-apps-current.XXXXXX"' "$ROOT/scripts/system_monitor.d/top_apps.sh" || fail "Top Apps no longer uses mktemp for snapshot temp files"
grep -Fq 'mktemp "${state_file}.tmp.XXXXXX"' "$ROOT/scripts/system_monitor.d/network_stat.sh" || fail "network-stat atomic temp file missing"
grep -Fq 'mktemp "${cache_file}.tmp.XXXXXX"' "$ROOT/scripts/system_monitor.d/network_connections.sh" || fail "network cache atomic temp file missing"
# Persistent lock hardening remains important and must not be removed.
grep -Fq 'chmod 600 "${state_file}.lock"' "$ROOT/scripts/system_monitor.d/network_stat.sh" || fail "network-stat lock permissions are no longer enforced"
grep -Fq 'chmod 600 "${cache_file}.lock"' "$ROOT/scripts/system_monitor.d/network_connections.sh" || fail "network cache lock permissions are no longer enforced"
grep -Fq 'chmod 600 "${state_file}.lock"' "$ROOT/scripts/system_monitor.d/top_apps.sh" || fail "Top Apps lock permissions are no longer enforced"

printf 'PASS: mktemp temp-file permissions are not redundantly chmodded; persistent lock modes remain enforced\n'
