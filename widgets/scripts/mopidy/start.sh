#!/usr/bin/env bash
set -euo pipefail

# Avoid starting a second Mopidy instance if the process is already running,
# even if its RPC service is still warming up or has temporarily failed.
if pgrep -x mopidy >/dev/null 2>&1; then
    exit 0
fi

if ! command -v mopidy >/dev/null 2>&1; then
    printf 'mopidy executable was not found in PATH\n' >&2
    exit 127
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/env"
state_dir="$QS_STATE_DIR"
mkdir -p "$state_dir"
log_file="$state_dir/mopidy-start.log"

# Keep Mopidy independent of Quickshell's process lifecycle while preserving
# its output for troubleshooting startup failures.
nohup mopidy >>"$log_file" 2>&1 </dev/null &
