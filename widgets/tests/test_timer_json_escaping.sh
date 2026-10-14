#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/timer.d/common.sh"

sample=$(printf 'quote " slash \\ tab\t newline\n carriage\r backspace\b formfeed\f vertical\v soh\001 café 🎵')
escaped=$(json_escape "$sample")

# The result must be a valid JSON string and round-trip byte-for-byte.
printf '"%s"\n' "$escaped" | jq -e --arg expected "$sample" '. == $expected' >/dev/null

# Common controls use readable JSON escapes; uncommon ones use \uXXXX.
[[ "$escaped" == *'\t'* ]]
[[ "$escaped" == *'\n'* ]]
[[ "$escaped" == *'\r'* ]]
[[ "$escaped" == *'\b'* ]]
[[ "$escaped" == *'\f'* ]]
[[ "$escaped" == *'\u000b'* ]]
[[ "$escaped" == *'\u0001'* ]]

# The timer daemon must apply escaping before embedding user comments in JSON.
grep -Fq 'comment_json=$(json_escape "$comment")' "$ROOT/scripts/timer.d/daemon.sh"
echo 'Timer JSON escaping test passed.'
