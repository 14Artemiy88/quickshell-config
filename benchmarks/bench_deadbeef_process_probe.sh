#!/usr/bin/env bash
# Compare DeaDBeeF's former two-name probe with one pgrep ERE probe.
# Usage: benchmarks/bench_deadbeef_process_probe.sh [polls=100] [trials=5]
set -euo pipefail
polls="${1:-100}"
trials="${2:-5}"
[[ "$polls" =~ ^[1-9][0-9]*$ && "$trials" =~ ^[1-9][0-9]*$ ]] || {
    echo "Usage: $0 [polls=100] [trials=5]" >&2
    exit 2
}
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin"
export DEADBEEF_PROBE_LOG="$tmp/pgrep.log"
cat > "$tmp/bin/pgrep" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DEADBEEF_PROBE_LOG"
case "${1:-}" in
    -x) ;;
    *) exit 2 ;;
esac
if [[ "${2:-}" == 'deadbeef(-main)?' ]]; then
    [[ "${DEADBEEF_PROBE_PROCESS:-absent}" == deadbeef || "${DEADBEEF_PROBE_PROCESS:-absent}" == deadbeef-main ]]
elif [[ "${2:-}" == deadbeef-main || "${2:-}" == deadbeef ]]; then
    [[ "${DEADBEEF_PROBE_PROCESS:-absent}" == "$2" ]]
else
    exit 2
fi
STUB
chmod +x "$tmp/bin/pgrep"
export PATH="$tmp/bin:$PATH"
now_us() {
    local stamp seconds fraction
    stamp="$EPOCHREALTIME"
    seconds="${stamp%.*}"
    fraction="${stamp#*.}000000"
    fraction="${fraction:0:6}"
    printf '%s' "$((10#$seconds * 1000000 + 10#$fraction))"
}
probe_before() {
    if ! pgrep -x deadbeef-main >/dev/null 2>&1; then
        pgrep -x deadbeef >/dev/null 2>&1 || true
    fi
}
probe_after() {
    pgrep -x 'deadbeef(-main)?' >/dev/null 2>&1 || true
}
measure() {
    local variant="$1" process="$2" trial i start end elapsed calls
    local -a samples=()
    DEADBEEF_PROBE_PROCESS="$process"; export DEADBEEF_PROBE_PROCESS
    for ((trial=0; trial<trials; trial++)); do
        : > "$DEADBEEF_PROBE_LOG"
        start="$(now_us)"
        for ((i=0; i<polls; i++)); do
            if [[ "$variant" == before ]]; then probe_before; else probe_after; fi
        done
        end="$(now_us)"
        elapsed=$((end-start))
        calls="$(wc -l < "$DEADBEEF_PROBE_LOG")"
        samples+=("$elapsed:$calls")
    done
    printf '%s\n' "${samples[@]}" | sort -t: -k1,1n > "$tmp/sorted"
    local median_line
    median_line="$(sed -n "$(( (trials + 1) / 2 ))p" "$tmp/sorted")"
    printf '%s\t%s\t%s\t%s\n' "$variant" "$process" "${median_line#*:}" "${median_line%%:*}"
}
printf 'DeaDBeeF process availability probe (%s polls, median of %s trials)\n' "$polls" "$trials"
printf 'variant\tprocess_state\tpgrep_calls\telapsed_us\n'
for process in deadbeef-main deadbeef absent; do
    measure before "$process"
    measure after "$process"
done
