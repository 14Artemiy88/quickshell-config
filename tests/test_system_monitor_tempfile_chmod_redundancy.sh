#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Temporary files from mktemp already have mode 0600. Persistent lock files
# are secured at creation with umask 077, not by spawning chmod on every poll.
if grep -Eq 'chmod[[:space:]]+600.*(previous_file|current_file|next_state|state_tmp|cache_tmp|time_tmp)' \
    "$ROOT/scripts/system_monitor.d/top_apps.sh" \
    "$ROOT/scripts/system_monitor.d/network_stat.sh" \
    "$ROOT/scripts/system_monitor.d/network_connections.sh"; then
    fail "redundant chmod for a freshly-created temporary file returned"
fi

grep -Fq 'mktemp "$runtime_dir/top-apps-current.XXXXXX"' "$ROOT/scripts/system_monitor.d/top_apps.sh" || fail "Top Apps no longer uses mktemp for snapshot temp files"
grep -Fq 'mktemp "${state_file}.tmp.XXXXXX"' "$ROOT/scripts/system_monitor.d/network_stat.sh" || fail "network-stat atomic temp file missing"
grep -Fq 'mktemp "${cache_file}.tmp.XXXXXX"' "$ROOT/scripts/system_monitor.d/network_connections.sh" || fail "network cache atomic temp file missing"

for lock_script in \
    "$ROOT/scripts/system_monitor.d/network_stat.sh" \
    "$ROOT/scripts/system_monitor.d/network_connections.sh" \
    "$ROOT/scripts/system_monitor.d/top_apps.sh"; do
    grep -Fq 'umask 077' "$lock_script" || fail "restrictive lock-file umask missing in $lock_script"
    if grep -Eq 'chmod[[:space:]]+600.*\.lock' "$lock_script"; then
        fail "per-poll chmod for persistent lock file returned in $lock_script"
    fi
done

printf 'PASS: temporary-file modes are not redundantly chmodded; persistent locks use umask 077 without per-poll chmod\n'
