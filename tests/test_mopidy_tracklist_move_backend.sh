#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/mopidy/tracklist.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
export MOPIDY_FAKE_STATE="$TMP/state.json"
export MOPIDY_FAKE_LOG="$TMP/calls.log"

cat > "$TMP/bin/curl" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
payload=""
while (($#)); do
    case "$1" in
        -d) payload="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done
method="$(jq -r '.method // empty' <<< "$payload")"
params="$(jq -c '.params // {}' <<< "$payload")"
printf '%s\n' "$method" >> "$MOPIDY_FAKE_LOG"
state="$(cat "$MOPIDY_FAKE_STATE")"
response='{}'
case "$method" in
    core.tracklist.get_version)
        response="$(jq -cn --argjson result "$(jq -r '.version' <<< "$state")" '{jsonrpc:"2.0",id:1,result:$result}')" ;;
    core.tracklist.get_length)
        response="$(jq -cn --argjson result "$(jq '.tlids | length' <<< "$state")" '{jsonrpc:"2.0",id:1,result:$result}')" ;;
    core.tracklist.index)
        tlid="$(jq -r '.tlid' <<< "$params")"
        index="$(jq -r --argjson tlid "$tlid" '.tlids | index($tlid) // empty' <<< "$state")"
        if [[ "$(jq -r '.bump_after_index // false' <<< "$state")" == true ]]; then
            jq '.version += 1 | .bump_after_index = false' <<< "$state" > "$MOPIDY_FAKE_STATE"
        fi
        if [[ -n "$index" ]]; then response="$(jq -cn --argjson result "$index" '{jsonrpc:"2.0",id:1,result:$result}')"
        else response='{"jsonrpc":"2.0","id":1,"error":{"message":"track not found"}}'; fi ;;
    core.tracklist.move)
        if [[ "$(jq -r '.fail_move // false' <<< "$state")" == true ]]; then
            response='{"jsonrpc":"2.0","id":1,"error":{"message":"move rejected"}}'
        elif [[ "$(jq -r '.ignore_move // false' <<< "$state")" == true ]]; then
            response='{"jsonrpc":"2.0","id":1,"result":null}'
        else
            start="$(jq -r '.start' <<< "$params")"
            end="$(jq -r '.end' <<< "$params")"
            to="$(jq -r '.to_position' <<< "$params")"
            next="$(jq --argjson start "$start" --argjson end "$end" --argjson to "$to" '
                .tlids as $all
                | ($all[0:$start] + $all[$end:]) as $rest
                | .tlids = ($rest[0:$to] + [$all[$start]] + $rest[$to:])
                | .version = ((.version // 0) + 1)
            ' <<< "$state")"
            printf '%s\n' "$next" > "$MOPIDY_FAKE_STATE"
            response='{"jsonrpc":"2.0","id":1,"result":null}'
        fi ;;
    core.tracklist.get_tl_tracks)
        result="$(jq -c '[.tlids[] | {tlid:.,track:{}}]' <<< "$state")"
        response="$(jq -cn --argjson result "$result" '{jsonrpc:"2.0",id:1,result:$result}')" ;;
    core.tracklist.remove)
        tlids="$(jq -c '.criteria.tlid // []' <<< "$params")"
        next="$(jq --argjson tlids "$tlids" '
            .tlids = [.tlids[] | select(. as $id | ($tlids | index($id)) == null)]
            | .version = ((.version // 0) + 1)
        ' <<< "$state")"
        printf '%s\n' "$next" > "$MOPIDY_FAKE_STATE"
        response='{"jsonrpc":"2.0","id":1,"result":null}' ;;
    *) response="$(jq -cn --arg method "$method" '{jsonrpc:"2.0",id:1,error:{message:("unexpected method: " + $method)}}')" ;;
esac
printf '%s\n' "$response"
MOCK
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"

reset_state() {
    printf '%s\n' '{"version":7,"tlids":[11,22,33],"fail_move":false,"ignore_move":false,"bump_after_index":false}' > "$MOPIDY_FAKE_STATE"
    : > "$MOPIDY_FAKE_LOG"
}
assert_order() {
    local expected="$1"
    local actual
    actual="$(jq -c '.tlids' "$MOPIDY_FAKE_STATE")"
    [[ "$actual" == "$expected" ]] || { echo "queue order: expected $expected, got $actual" >&2; exit 1; }
}
assert_error() {
    local expected="$1" output
    shift
    output="$("$SCRIPT" "$@")"
    [[ "$(jq -r '.error // empty' <<< "$output")" == "$expected" ]] || {
        echo "expected error $expected, got $output" >&2; exit 1;
    }
}

reset_state
out="$("$SCRIPT" move 11 2 7)"
[[ "$(jq -r '.ok' <<< "$out")" == true ]]
[[ "$(jq -r '.from' <<< "$out")" == 0 && "$(jq -r '.to' <<< "$out")" == 2 ]]
assert_order '[22,33,11]'

reset_state
out="$("$SCRIPT" move 33 0 7)"
[[ "$(jq -r '.ok' <<< "$out")" == true ]]
assert_order '[33,11,22]'

reset_state
jq '.tlids=[0,11,22]' "$MOPIDY_FAKE_STATE" > "$TMP/state.next" && mv "$TMP/state.next" "$MOPIDY_FAKE_STATE"
out="$("$SCRIPT" move 0 2 7)"
[[ "$(jq -r '.ok' <<< "$out")" == true ]]
assert_order '[11,22,0]'

reset_state
out="$("$SCRIPT" move 22 1 7)"
[[ "$(jq -r '.ok' <<< "$out")" == true && "$(jq -r '.unchanged' <<< "$out")" == true ]]
assert_order '[11,22,33]'
! grep -Fxq 'core.tracklist.move' "$MOPIDY_FAKE_LOG"

reset_state
assert_error queue_changed move 11 2 6
assert_order '[11,22,33]'

reset_state
assert_error invalid_argument move nope 2 7
assert_error invalid_position move 11 3 7
assert_error track_not_found move 99 1 7

reset_state
jq '.fail_move=true' "$MOPIDY_FAKE_STATE" > "$TMP/state.next" && mv "$TMP/state.next" "$MOPIDY_FAKE_STATE"
assert_error move_rejected move 11 2 7
assert_order '[11,22,33]'

reset_state
jq '.ignore_move=true' "$MOPIDY_FAKE_STATE" > "$TMP/state.next" && mv "$TMP/state.next" "$MOPIDY_FAKE_STATE"
assert_error move_unconfirmed move 11 2 7
assert_order '[11,22,33]'

# A concurrent edit after the source index lookup is rejected by the second version check.
reset_state
jq '.bump_after_index=true' "$MOPIDY_FAKE_STATE" > "$TMP/state.next" && mv "$TMP/state.next" "$MOPIDY_FAKE_STATE"
assert_error queue_changed move 11 2 7
assert_order '[11,22,33]'
! grep -Fxq 'core.tracklist.move' "$MOPIDY_FAKE_LOG"

# Existing remove command must remain intact after adding the move command.
reset_state
"$SCRIPT" remove 22
assert_order '[11,33]'
grep -Fxq 'core.tracklist.remove' "$MOPIDY_FAKE_LOG"

echo 'Mopidy tracklist async move backend and remove compatibility: OK'
