#!/usr/bin/env bash
# Compare the former RAM-only temp-file + cat path with the current streaming path.
# Usage: benchmarks/bench_top_apps_ram_only_streaming_fastpath.sh [polls=30] [rows=100] [trials=5]
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
POLLS="${1:-30}"
ROWS="${2:-100}"
TRIALS="${3:-5}"
[[ "$POLLS" =~ ^[1-9][0-9]*$ && "$ROWS" =~ ^[1-9][0-9]*$ && "$TRIALS" =~ ^[1-9][0-9]*$ ]] || {
    echo "Usage: $0 [polls=30] [rows=100] [trials=5]" >&2
    exit 2
}
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/runtime"
REAL_CAT="$(command -v cat)"
REAL_MKTEMP="$(command -v mktemp)"
export REAL_CAT REAL_MKTEMP
export MOCK_CAT_LOG="$TMP/cat.log" MOCK_SNAPSHOT_MKTEMP_LOG="$TMP/snapshot-mktemp.log"
: > "$MOCK_CAT_LOG"; : > "$MOCK_SNAPSHOT_MKTEMP_LOG"
cat > "$TMP/bin/ps" <<'PS'
#!/usr/bin/env bash
for ((i=0; i<MOCK_PROCESS_ROWS; i++)); do
    printf '%d 1 %d ram-app-%03d\n' "$((101+i))" "$((1024+i))" "$i"
done
PS
cat > "$TMP/bin/cat" <<'CAT'
#!/usr/bin/env bash
for arg in "$@"; do
    case "$arg" in */top-apps-current.*) printf 'cat\n' >> "$MOCK_CAT_LOG";; esac
done
exec "$REAL_CAT" "$@"
CAT
cat > "$TMP/bin/mktemp" <<'MK'
#!/usr/bin/env bash
for arg in "$@"; do
    case "$arg" in
        */top-apps-previous.*|*/top-apps-current.*)
            printf '%s\n' "${arg##*/}" >> "$MOCK_SNAPSHOT_MKTEMP_LOG" ;;
    esac
done
exec "$REAL_MKTEMP" "$@"
MK
chmod +x "$TMP/bin/ps" "$TMP/bin/cat" "$TMP/bin/mktemp"
export PATH="$TMP/bin:$PATH" MOCK_PROCESS_ROWS="$ROWS"
source "$ROOT/scripts/system_monitor.d/top_apps.sh"
printf -v EXPECTED_LAST_INDEX '%03d' "$((ROWS-1))"
EXPECTED_LAST_ROW="ram-app-${EXPECTED_LAST_INDEX}"

# Legacy equivalent of the old RAM-only path: create previous/current/next
# files, write rows to current, then launch cat to return them. CPU sampling is
# deliberately excluded from both variants.
legacy_ram_snapshot_unlocked() {
    local state_file="$1" runtime_dir="$2" previous_file current_file next_state
    local ps_output line pid ppid rss ps_remainder cgroup comm fd next_fd
    previous_file="$(mktemp "$runtime_dir/top-apps-previous.XXXXXX")" || return 1
    printf 'T\t-1\n' > "$previous_file"
    current_file="$(mktemp "$runtime_dir/top-apps-current.XXXXXX")" || { rm -f "$previous_file"; return 1; }
    next_state="$(mktemp "$runtime_dir/top-apps-state.XXXXXX")" || { rm -f "$previous_file" "$current_file"; return 1; }
    printf 'T\t-1\n' > "$next_state"
    ps_output="$(LC_ALL=C ps -ww --no-header -eo pid,ppid,rss,cgroup,comm 2>/dev/null)" || {
        rm -f "$previous_file" "$current_file" "$next_state"; return 1;
    }
    exec {fd}>>"$current_file"
    exec {next_fd}>>"$next_state"
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        read -r pid ppid rss ps_remainder <<< "$line"
        read -r cgroup comm <<< "${ps_remainder:-}"
        if [[ -z "${comm:-}" ]]; then comm="${cgroup:-}"; cgroup='-'; fi
        [[ "${pid:-}" =~ ^[0-9]+$ && -n "${comm:-}" ]] || continue
        [[ -n "${cgroup:-}" ]] || cgroup='-'
        printf '%s\t0.0000\t%s\t%s\t%s\n' "$comm" "${rss:-0}" "$pid" "$ppid" >&"$fd"
    done <<< "$ps_output"
    exec {fd}>&-
    exec {next_fd}>&-
    cat -- "$current_file"
    if [[ -s "$current_file" ]]; then mv -f -- "$next_state" "$state_file"; fi
    rm -f -- "$previous_file" "$current_file" "$next_state"
}
legacy_get_process_snapshot() {
    local runtime_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}" state_file="$runtime_dir/quickshell-top-apps-cpu-${UID}.tsv"
    (
        umask 077
        exec 9>"${state_file}.lock" || exit 1
        flock -x 9 || exit 1
        legacy_ram_snapshot_unlocked "$state_file" "$runtime_dir"
    )
}

clock_us() {
    local raw="$EPOCHREALTIME" sec="${EPOCHREALTIME%%.*}" fraction="${EPOCHREALTIME#*.}000000"
    fraction="${fraction:0:6}"
    CLOCK_US=$((10#$sec * 1000000 + 10#$fraction))
}
count_lines() {
    local file="$1" count=0 line
    [[ -f "$file" ]] || { printf '0'; return; }
    while IFS= read -r line; do count=$((count+1)); done < "$file"
    printf '%s' "$count"
}
measure() {
    local variant="$1" trial i start end snapshot elapsed cats temps runtime_dir
    local -a timings=()
    for ((trial=0; trial<TRIALS; trial++)); do
        runtime_dir="$TMP/runtime/$variant-$trial"
        mkdir -p "$runtime_dir"
        export XDG_RUNTIME_DIR="$runtime_dir"
        : > "$MOCK_CAT_LOG"; : > "$MOCK_SNAPSHOT_MKTEMP_LOG"
        clock_us; start=$CLOCK_US
        for ((i=0; i<POLLS; i++)); do
            if [[ "$variant" == before ]]; then snapshot="$(legacy_get_process_snapshot)"; else snapshot="$(get_process_snapshot 0)"; fi
            [[ "$snapshot" == *"${EXPECTED_LAST_ROW}"$'\t0.0000'* ]] || {
                printf 'snapshot mismatch in %s trial %d\n' "$variant" "$trial" >&2; return 1;
            }
        done
        clock_us; end=$CLOCK_US; elapsed=$((end-start)); timings+=("$elapsed")
        cats="$(count_lines "$MOCK_CAT_LOG")"
        temps="$(count_lines "$MOCK_SNAPSHOT_MKTEMP_LOG")"
        printf '%s trial=%d elapsed_us=%d cat_calls=%s cpu_snapshot_tempfiles=%s\n' "$variant" "$trial" "$elapsed" "$cats" "$temps"
        rm -rf -- "$runtime_dir"
    done
    printf '%s\n' "${timings[@]}" | sort -n > "$TMP/timings.sorted"
    local median_index=$(( (TRIALS+1)/2 )) median=0 n=0 value
    while IFS= read -r value; do n=$((n+1)); if (( n==median_index )); then median=$value; break; fi; done < "$TMP/timings.sorted"
    printf '%s median_elapsed_us=%s polls=%s rows_per_poll=%s\n' "$variant" "$median" "$POLLS" "$ROWS"
}
measure before
measure after
printf 'Both variants are smoke-checked against the final fixture row; the dedicated regression test verifies the exact RAM-only rows and empty-snapshot behavior. CPU mode is not benchmarked here.\n'
