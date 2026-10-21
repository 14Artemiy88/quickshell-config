#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source_file="$ROOT/scripts/system_monitor.d/network_connections.sh"
fail() { printf 'System monitor network connection inline status: FAIL: %s\n' "$*" >&2; exit 1; }

# Each row on a cache refresh used to capture a tiny `printf` conditional in a
# command substitution. Keep the per-row status assignment in the current shell.
grep -Fq 'if [[ -n "${device:-}" ]]; then' "$source_file" || fail 'inline device status branch missing'
grep -Fq 'status=on' "$source_file" || fail 'connected state assignment missing'
grep -Fq 'status=off' "$source_file" || fail 'disconnected state assignment missing'
if grep -Eq 'status=\$\(\[\[.*device.*printf' "$source_file"; then
    fail 'per-connection command-substitution status assignment returned'
fi
printf 'System monitor network connection inline status: OK (no per-row command substitution)\n'
