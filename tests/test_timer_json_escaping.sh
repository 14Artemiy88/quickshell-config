#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/timer.d/common.sh"

sample=$(printf 'quote " slash \\ tab\t newline\n carriage\r backspace\b formfeed\f vertical\v soh\001 café 🎵')
escaped=$(json_escape "$sample")
json_escape_into escaped_into "$sample"
[[ "$escaped_into" == "$escaped" ]] || { echo 'json_escape_into differs from json_escape' >&2; exit 1; }

# Assignment must resolve to a variable local to the actual caller.
assign_in_scope() {
    local comment_json file_json
    json_escape_into comment_json "$sample"
    json_escape_into file_json '/tmp/has "quotes" and spaces'
    [[ "$comment_json" == "$escaped" && "$file_json" == "$(json_escape '/tmp/has "quotes" and spaces')" ]]
}
assign_in_scope || { echo 'json_escape_into failed caller-scope assignment' >&2; exit 1; }

# The result must be a valid JSON string and round-trip byte-for-byte.
printf '"%s"\n' "$escaped" | jq -e --arg expected "$sample" '. == $expected' >/dev/null
printf '"%s"\n' "$escaped_into" | jq -e --arg expected "$sample" '. == $expected' >/dev/null

# Common controls use readable JSON escapes; uncommon ones use \uXXXX.
[[ "$escaped" == *'\t'* ]]
[[ "$escaped" == *'\n'* ]]
[[ "$escaped" == *'\r'* ]]
[[ "$escaped" == *'\b'* ]]
[[ "$escaped" == *'\f'* ]]
[[ "$escaped" == *'\u000b'* ]]
[[ "$escaped" == *'\u0001'* ]]

# The timer daemon must assign both escaped strings directly, without
# creating a command-substitution subshell per string on each poll.
grep -Fq 'json_escape_into comment_json "$comment"' "$ROOT/scripts/timer.d/daemon.sh"
grep -Fq 'json_escape_into file_json "$file"' "$ROOT/scripts/timer.d/daemon.sh"
if grep -Fq 'comment_json=$(json_escape "$comment")' "$ROOT/scripts/timer.d/daemon.sh"; then
    echo 'timer daemon still creates a subshell for comment escaping' >&2
    exit 1
fi
if grep -Fq 'file_json=$(json_escape "$file")' "$ROOT/scripts/timer.d/daemon.sh"; then
    echo 'timer daemon still creates a subshell for file-path escaping' >&2
    exit 1
fi
echo 'Timer JSON escaping parity and inline-assignment test passed.'
