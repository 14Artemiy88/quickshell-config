#!/usr/bin/env bash
# Compare repeated cache-directory setup before and after the warm-path guard.
set -euo pipefail
ITERATIONS="${1:-100}"
TRIALS="${2:-5}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
CACHE_DIR="$TMP_DIR/cache/mopidy-covers"
mkdir -p "$CACHE_DIR"

measure() {
  local mode="$1" start end i
  start="${EPOCHREALTIME/./}"
  for ((i=0; i<ITERATIONS; i++)); do
    if [[ "$mode" == before ]]; then
      mkdir -p "$CACHE_DIR"
    else
      [[ -d "$CACHE_DIR" ]] || mkdir -p "$CACHE_DIR"
    fi
  done
  end="${EPOCHREALTIME/./}"
  printf '%s\n' "$((end - start))"
}

before=() after=()
for ((trial=1; trial<=TRIALS; trial++)); do
  before+=("$(measure before)")
  after+=("$(measure after)")
done
mid="$(((TRIALS + 1) / 2))"
before_us="$(printf '%s\n' "${before[@]}" | sort -n | sed -n "${mid}p")"
after_us="$(printf '%s\n' "${after[@]}" | sort -n | sed -n "${mid}p")"
printf 'iterations per trial: %s; trials: %s\n' "$ITERATIONS" "$TRIALS"
printf 'before: median %d.%03d ms; mkdir launches %s per trial\n' "$((before_us / 1000))" "$((before_us % 1000))" "$ITERATIONS"
printf 'after:  median %d.%03d ms; mkdir launches 0 per trial\n' "$((after_us / 1000))" "$((after_us % 1000))"
