#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "Top Apps IDE attribution: FAIL: $*" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || fail 'jq is required'
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export XDG_RUNTIME_DIR="$TMP/runtime"
export TOP_APPS_PROC_ROOT="$TMP/proc"
export TOP_APPS_PROC_STAT="$TMP/proc/stat"
mkdir -p "$XDG_RUNTIME_DIR" "$TOP_APPS_PROC_ROOT" "$TMP/bin"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"

# argv is NUL-separated in /proc/<pid>/cmdline. Ensure it survives conversion
# and includes the JetBrains product selector used for process attribution.
mkdir -p "$TOP_APPS_PROC_ROOT/401"
printf '%s\0' '/opt/jetbrains/phpstorm/jbr/bin/java' '-Didea.paths.selector=PhpStorm2025.1' 'com.intellij.idea.Main' > "$TOP_APPS_PROC_ROOT/401/cmdline"
read_back="$(read_process_cmdline "$TOP_APPS_PROC_ROOT/401/cmdline")"
[[ "$read_back" == *'-Didea.paths.selector=PhpStorm2025.1'* ]] || fail "could not read JVM selector from cmdline: $read_back"

# The live snapshot collector reads cmdline only for candidate IDE roots, and
# transports it as optional row metadata without changing the first five fields.
cat > "$TMP/bin/ps" <<'PS'
#!/usr/bin/env bash
printf '401 1 4096 /user.slice/user-1000.slice/user@1000.service/app.slice/app-phpstorm.scope java\n402 1 8192 /user.slice/user-1000.slice/user@1000.service/app.slice/app-phpstorm.scope php\n'
PS
chmod +x "$TMP/bin/ps"
export PATH="$TMP/bin:$PATH"
cat > "$TOP_APPS_PROC_ROOT/401/stat" <<'STAT'
401 (java) S 1 401 401 0 0 0 0 0 0 0 100 0 0 0 20 0 1 0 1 8192 4
STAT
mkdir -p "$TOP_APPS_PROC_ROOT/402"
cat > "$TOP_APPS_PROC_ROOT/402/stat" <<'STAT'
402 (php) S 401 402 401 0 0 0 0 0 0 0 100 0 0 0 20 0 1 0 1 8192 4
STAT
printf 'cpu 100 0 100 100 0 0 0 0 0 0\n' > "$TOP_APPS_PROC_STAT"
snapshot="$(get_process_snapshot 1)" || fail 'CPU process snapshot failed'
printf '%s\n' "$snapshot" | awk -F '\t' '$1 == "java" && $7 ~ /idea[.]paths[.]selector=PhpStorm/ { found=1 } END { exit !found }' || fail "JVM commandline did not survive snapshot: $snapshot"

# Deterministic process-tree fixture: GoLand and PhpStorm run JVM roots whose
# children have generic names. Descendants are attributed through PPID; a
# helper reparented to PID 1 remains attributable through its unique cgroup.
# Unrelated Java and compiler processes remain separate.
goland_cgroup=/user.slice/user-1000.slice/user@1000.service/app.slice/app-goland.scope
phpstorm_cgroup=/user.slice/user-1000.slice/user@1000.service/app.slice/app-phpstorm.scope
other_cgroup=/user.slice/user-1000.slice/user@1000.service/app.slice/app-other.scope
fixture=$'java\t10.0000\t1000\t501\t1\t'"$goland_cgroup"$'\t/opt/GoLand/jbr/bin/java -Didea.paths.selector=GoLand2025.1 com.intellij.idea.Main\n'\
$'go\t7.0000\t2000\t502\t501\t'"$goland_cgroup"$'\t-\n'\
$'compile\t37.0000\t3000\t503\t502\t'"$goland_cgroup"$'\t-\n'\
$'link\t11.0000\t1000\t504\t501\t'"$goland_cgroup"$'\t-\n'\
$'java\t8.0000\t1000\t601\t1\t'"$phpstorm_cgroup"$'\t/opt/PhpStorm/jbr/bin/java -Didea.paths.selector=PhpStorm2025.1 com.intellij.idea.Main\n'\
$'php\t28.0000\t2000\t602\t601\t'"$phpstorm_cgroup"$'\t-\n'\
$'node\t16.0000\t2500\t603\t601\t'"$phpstorm_cgroup"$'\t-\n'\
$'worker\t6.0000\t700\t604\t1\t'"$phpstorm_cgroup"$'\t-\n'\
$'java\t4.0000\t1000\t701\t1\t'"$other_cgroup"$'\t/usr/lib/jvm/java app.Main\n'\
$'compile\t9.0000\t500\t702\t1\t'"$other_cgroup"$'\t-\n'\
$'compile\t12.0000\t500\t703\t1\t/user.slice/user-1000.slice/user@1000.service\t-'
groups="$(printf '%s\n' "$fixture" | aggregate_process_rows cpu 0)" || fail 'IDE process grouping failed'
goland="$(printf '%s\n' "$groups" | awk -F '\t' '$1 == "goland" { print; exit }')"
phpstorm="$(printf '%s\n' "$groups" | awk -F '\t' '$1 == "phpstorm" { print; exit }')"
[[ -n "$goland" ]] || fail "GoLand JVM group missing: $groups"
[[ -n "$phpstorm" ]] || fail "PhpStorm JVM group missing: $groups"
IFS=$'\t' read -r name cpu count pid <<< "$goland"
[[ "$cpu" == "65.0000" && "$count" == 4 ]] || fail "GoLand descendants not fully grouped (cpu=$cpu count=$count)"
IFS=$'\t' read -r name cpu count pid <<< "$phpstorm"
[[ "$cpu" == "58.0000" && "$count" == 4 ]] || fail "PhpStorm descendants not fully grouped (cpu=$cpu count=$count)"
[[ "$(printf '%s\n' "$groups" | awk -F '\t' '$1 == "compile" {print $2}')" == "21.0000" ]] || fail 'compile workers outside the owning app scope were incorrectly attributed to an IDE'
[[ "$(printf '%s\n' "$groups" | awk -F '\t' '$1 == "java" {print $2}')" == "4.0000" ]] || fail 'unrelated Java process was attributed to an IDE'

# Regular RAM ranking deliberately keeps its existing process-name grouping;
# the IDE ancestry optimization is for CPU attribution only.
ram_groups="$(printf '%s\n' "$fixture" | aggregate_process_rows mem 0)" || fail 'RAM aggregation failed'
[[ "$(printf '%s\n' "$ram_groups" | awk -F '\t' '$1 == "java" {print $2; exit}')" == "3000.0000" ]] || fail 'RAM grouping unexpectedly changed due to CPU IDE attribution'

echo 'Top Apps IDE attribution: OK'
