#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/mopidy/playlists.sh"
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
case "$method" in
    core.playlists.lookup)
        state="$(jq '.lookup_count = ((.lookup_count // 0) + 1)' <<< "$state")"
        if [[ "$(jq -r '.change_on_second_lookup // false' <<< "$state")" == true \
                && "$(jq -r '.lookup_count' <<< "$state")" == 2 ]]; then
            state="$(jq '.playlist.tracks = [.playlist.tracks[2], .playlist.tracks[1], .playlist.tracks[0]]' <<< "$state")"
        fi
        printf '%s\n' "$state" > "$MOPIDY_FAKE_STATE"
        playlist="$(jq -c '.playlist // null' <<< "$state")"
        response="$(jq -cn --argjson result "$playlist" '{jsonrpc:"2.0",id:1,result:$result}')" ;;
    core.playlists.save)
        if [[ "$(jq -r '.fail_save // false' <<< "$state")" == true ]]; then
            response='{"jsonrpc":"2.0","id":1,"error":{"message":"save rejected"}}'
        elif [[ "$(jq -r '.ignore_save // false' <<< "$state")" == true ]]; then
            response='{"jsonrpc":"2.0","id":1,"result":null}'
        else
            playlist="$(jq -c '.playlist' <<< "$params")"
            next="$(jq --argjson playlist "$playlist" '.playlist=$playlist' <<< "$state")"
            printf '%s\n' "$next" > "$MOPIDY_FAKE_STATE"
            if [[ "$(jq -r '.return_saved_playlist // false' <<< "$state")" == true ]]; then
                response="$(jq -cn --argjson result "$playlist" '{jsonrpc:"2.0",id:1,result:$result}')"
            else
                response='{"jsonrpc":"2.0","id":1,"result":null}'
            fi
        fi ;;
    *) response="$(jq -cn --arg method "$method" '{jsonrpc:"2.0",id:1,error:{message:("unexpected method: " + $method)}}')" ;;
esac
printf '%s\n' "$response"
MOCK
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"

reset_state() {
    cat > "$MOPIDY_FAKE_STATE" <<'JSON'
{"playlist":{"uri":"local:demo","name":"Demo","tracks":[{"uri":"uri:a","name":"Track A"},{"uri":"uri:b","name":"Track B"},{"uri":"uri:c","name":"Track C"}]},"fail_save":false,"ignore_save":false,"return_saved_playlist":false,"lookup_count":0,"change_on_second_lookup":false}
JSON
    : > "$MOPIDY_FAKE_LOG"
}
assert_order() {
    local expected="$1" actual
    actual="$(jq -c '[.playlist.tracks[].uri]' "$MOPIDY_FAKE_STATE")"
    [[ "$actual" == "$expected" ]] || { echo "playlist order: expected $expected, got $actual" >&2; exit 1; }
}
assert_error() {
    local expected="$1" output
    shift
    output="$("$SCRIPT" move_item "$@")"
    [[ "$(jq -r '.error // empty' <<< "$output")" == "$expected" ]] || {
        echo "expected error $expected, got $output" >&2; exit 1;
    }
}

reset_state
out="$("$SCRIPT" move_item local:demo 0 2 uri:a '["uri:a","uri:b","uri:c"]')"
[[ "$(jq -r '.ok' <<< "$out")" == true ]]
assert_order '["uri:b","uri:c","uri:a"]'
[[ "$(jq -r '.playlist.name' "$MOPIDY_FAKE_STATE")" == Demo ]]
[[ "$(jq -r '.playlist.tracks[2].name' "$MOPIDY_FAKE_STATE")" == 'Track A' ]]

reset_state
out="$("$SCRIPT" move_item local:demo 2 0 uri:c '["uri:a","uri:b","uri:c"]')"
[[ "$(jq -r '.ok' <<< "$out")" == true ]]
assert_order '["uri:c","uri:a","uri:b"]'

reset_state
out="$("$SCRIPT" move_item local:demo 1 1 uri:b '[ "uri:a", "uri:b", "uri:c" ]')"
[[ "$(jq -r '.ok' <<< "$out")" == true && "$(jq -r '.unchanged' <<< "$out")" == true ]]
! grep -Fxq 'core.playlists.save' "$MOPIDY_FAKE_LOG"

reset_state
assert_error playlist_changed local:demo 0 2 uri:a '["uri:a","uri:stale","uri:c"]'
! grep -Fxq 'core.playlists.save' "$MOPIDY_FAKE_LOG"

reset_state
assert_error playlist_changed local:demo 0 2 uri:wrong '["uri:a","uri:b","uri:c"]'
assert_error item_not_found local:demo 0 3 uri:a '["uri:a","uri:b","uri:c"]'

reset_state
jq '.change_on_second_lookup=true' "$MOPIDY_FAKE_STATE" > "$TMP/state.next" && mv "$TMP/state.next" "$MOPIDY_FAKE_STATE"
assert_error playlist_changed local:demo 0 2 uri:a '["uri:a","uri:b","uri:c"]'
! grep -Fxq 'core.playlists.save' "$MOPIDY_FAKE_LOG"

reset_state
jq '.fail_save=true' "$MOPIDY_FAKE_STATE" > "$TMP/state.next" && mv "$TMP/state.next" "$MOPIDY_FAKE_STATE"
assert_error playlist_save_failed local:demo 0 2 uri:a '["uri:a","uri:b","uri:c"]'
assert_order '["uri:a","uri:b","uri:c"]'

reset_state
jq '.ignore_save=true' "$MOPIDY_FAKE_STATE" > "$TMP/state.next" && mv "$TMP/state.next" "$MOPIDY_FAKE_STATE"
assert_error move_unconfirmed local:demo 0 2 uri:a '["uri:a","uri:b","uri:c"]'
assert_order '["uri:a","uri:b","uri:c"]'

# Existing remove-item saves still work with the legacy provider response shape.
reset_state
jq '.return_saved_playlist=true' "$MOPIDY_FAKE_STATE" > "$TMP/state.next" && mv "$TMP/state.next" "$MOPIDY_FAKE_STATE"
out="$("$SCRIPT" remove_item local:demo 1)"
[[ "$(jq -r '.ok' <<< "$out")" == true ]]
assert_order '["uri:a","uri:c"]'

echo 'Mopidy playlist async move backend and stale-state handling: OK'
