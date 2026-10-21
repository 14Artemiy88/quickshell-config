#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'Built-in script directory fast path: FAIL: %s\n' "$1" >&2; exit 1; }

for file in \
    "$ROOT/scripts/cpu_stats_once" \
    "$ROOT/scripts/mem_stats_once" \
    "$ROOT/scripts/system_monitor.d/top_apps.sh"; do
    grep -Fq 'SCRIPT_PATH="${BASH_SOURCE[0]}"' "$file" || \
        grep -Fq 'TOP_APPS_SCRIPT_PATH="${BASH_SOURCE[0]}"' "$file" || \
        fail "missing direct BASH_SOURCE path handling in $file"
    if grep -Eq 'dirname[[:space:]]+--[[:space:]]+"\$\{BASH_SOURCE\[0\]\}"' "$file"; then
        fail "external dirname remains in $file"
    fi
done

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
space_root="$work/Project With Spaces"
mkdir -p "$space_root/scripts/cpu_stats.d" "$space_root/scripts/system_monitor.d" "$work/bin"
cp "$ROOT/scripts/cpu_stats_once" "$ROOT/scripts/mem_stats_once" "$space_root/scripts/"
cp "$ROOT/scripts/system_monitor.d/top_apps.sh" "$space_root/scripts/system_monitor.d/"
cat > "$space_root/scripts/cpu_stats.d/common.sh" <<'STUB'
#!/usr/bin/env bash
cpu_read_counters_with_ids_into() { local target="$1"; printf -v "$target" '%s' 'cpu0 100 200'; }
cpu_usage_snapshot_percentages_into() { local target="$1"; printf -v "$target" '%s' 'cpu0 51'; }
mem_usage_percent_into() { local target="$1"; printf -v "$target" '%s' '43'; }
mem_usage_percent() { printf '43'; }
STUB

real_dirname="$(command -v dirname)"
export TEST_REAL_DIRNAME="$real_dirname" TEST_DIRNAME_LOG="$work/dirname.log"
cat > "$work/bin/dirname" <<'WRAPPER'
#!/usr/bin/env bash
printf 'dirname\n' >> "$TEST_DIRNAME_LOG"
exec "$TEST_REAL_DIRNAME" "$@"
WRAPPER
chmod +x "$work/bin/dirname"
export PATH="$work/bin:$PATH"

cpu_output="$(CPU_STATS_SAMPLE_INTERVAL=0 bash "$space_root/scripts/cpu_stats_once")"
[[ "$cpu_output" == '{"cpu":[51],"ram":43}' ]] || fail "absolute path with spaces did not source the sibling library: $cpu_output"
mem_output="$(bash "$space_root/scripts/mem_stats_once")"
[[ "$mem_output" == 43 ]] || fail "memory collector did not source the sibling library: $mem_output"

relative_topapps="$(cd "$space_root" && bash -c 'source "scripts/system_monitor.d/top_apps.sh"; declare -F get_top_apps >/dev/null && printf OK')"
[[ "$relative_topapps" == OK ]] || fail 'relative Top Apps path did not source cpu_stats.d/common.sh'

[[ ! -s "$TEST_DIRNAME_LOG" ]] || fail "script startup still launched dirname: $(cat "$TEST_DIRNAME_LOG")"
echo 'Built-in script directory fast path and absolute/relative paths with spaces: OK'
