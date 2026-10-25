#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/share"
export XDG_STATE_HOME="$HOME/state"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$TMP_ROOT/bin"
SETTINGS="$ROOT/scripts/settings"
DIR="$XDG_CONFIG_HOME/quickshell-widgets"
CFG="$DIR/settings.json"
PROFILES="$DIR/profiles.json"
TXN="$DIR/.settings-profile-transaction"
fail() { printf 'settings profile transaction crash recovery failed: %s\n' "$1" >&2; exit 1; }

initial='{"activeProfile":"Old","profileOverrides":{"fontSize":12},"profiles":{"Old":{"fontSize":12}},"weatherToken":""}'
"$SETTINGS" set-json-ui "$initial" '' >/dev/null
cp "$CFG" "$TMP_ROOT/old-settings.json"
cp "$PROFILES" "$TMP_ROOT/old-profiles.json"

# Simulate SIGKILL immediately after the new profile catalog is atomically
# published but before the matching settings snapshot can be committed.
cat > "$TMP_ROOT/bin/mv" <<'MV'
#!/usr/bin/env bash
/bin/mv "$@" || exit $?
for arg in "$@"; do
    if [[ -n "${KILL_ON_DEST:-}" && "$arg" == "$KILL_ON_DEST" ]]; then
        kill -KILL "$PPID" 2>/dev/null || true
        sleep 0.1
        exit 137
    fi
    if [[ "${KILL_AFTER_COMMITTED_BACKUP:-0}" == 1 && "$arg" == */.settings.json.bak && "$(cat "${TXN_FILE:-/nonexistent}" 2>/dev/null || true)" == committed ]]; then
        kill -KILL "$PPID" 2>/dev/null || true
        sleep 0.1
        exit 137
    fi
done
MV
chmod +x "$TMP_ROOT/bin/mv"
new='{"activeProfile":"New","profileOverrides":{"fontSize":22},"profiles":{"Old":{"fontSize":12},"New":{"fontSize":22}},"weatherToken":""}'
set +e
KILL_ON_DEST="$PROFILES" PATH="$TMP_ROOT/bin:$PATH" "$SETTINGS" set-json-ui "$new" '' >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail 'fault injector did not terminate the writer'
[[ -f "$TXN" ]] || fail 'transaction journal was not left after interruption'
jq -e '.activeProfile == "Old" and .profileOverrides.fontSize == 12' "$CFG" >/dev/null || fail 'fault did not occur before settings commit'
jq -e 'has("New")' "$PROFILES" >/dev/null || fail 'fault did not occur after profile publish'

readback=$("$SETTINGS" get 2>"$TMP_ROOT/recovery.log")
jq -e '.activeProfile == "Old" and .profileOverrides.fontSize == 12 and (.profiles | has("Old")) and ((.profiles | has("New")) | not)' <<<"$readback" >/dev/null || fail 'startup recovery did not roll both files back to one consistent snapshot'
[[ ! -e "$TXN" ]] || fail 'transaction journal was not cleared after recovery'
cmp -s "$CFG" "$DIR/.settings.json.bak" || fail 'settings backup diverged after recovery'
cmp -s "$PROFILES" "$DIR/.profiles.json.bak" || fail 'profiles backup diverged after recovery'

# A second fault point terminates the writer after settings.json is published,
# while the journal is still pending. Recovery must roll both primaries back.
new_after_profile='{"activeProfile":"Later","profileOverrides":{"fontSize":33},"profiles":{"Old":{"fontSize":12},"Later":{"fontSize":33}},"weatherToken":""}'
set +e
KILL_ON_DEST="$CFG" PATH="$TMP_ROOT/bin:$PATH" "$SETTINGS" set-json-ui "$new_after_profile" '' >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail 'settings-publish fault injector did not terminate the writer'
[[ -f "$TXN" ]] || fail 'transaction journal missing after settings-publish interruption'
readback=$("$SETTINGS" get 2>"$TMP_ROOT/recovery-after-settings.log")
jq -e '.activeProfile == "Old" and .profileOverrides.fontSize == 12 and (.profiles | has("Old")) and ((.profiles | has("Later")) | not)' <<<"$readback" >/dev/null || fail 'recovery after settings publish did not roll both files back'
[[ ! -e "$TXN" ]] || fail 'transaction journal remained after second recovery'
cmp -s "$CFG" "$DIR/.settings.json.bak" || fail 'settings backup diverged after second recovery'
cmp -s "$PROFILES" "$DIR/.profiles.json.bak" || fail 'profiles backup diverged after second recovery'

# If the commit marker is already published but backup refresh is interrupted,
# recovery must keep the new pair and finish the settings backup refresh.
new_committed='{"activeProfile":"Final","profileOverrides":{"fontSize":44},"profiles":{"Old":{"fontSize":12},"Final":{"fontSize":44}},"weatherToken":""}'
set +e
TXN_FILE="$TXN" KILL_AFTER_COMMITTED_BACKUP=1 PATH="$TMP_ROOT/bin:$PATH" "$SETTINGS" set-json-ui "$new_committed" '' >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]] || fail 'committed-backup fault injector did not terminate the writer'
[[ "$(cat "$TXN")" == committed ]] || fail 'committed journal state was not retained after interruption'
readback=$("$SETTINGS" get 2>"$TMP_ROOT/recovery-committed.log")
jq -e '.activeProfile == "Final" and .profileOverrides.fontSize == 44 and (.profiles | has("Final"))' <<<"$readback" >/dev/null || fail 'committed recovery rolled back or mixed the new state'
[[ ! -e "$TXN" ]] || fail 'committed transaction journal was not cleared'
cmp -s "$CFG" "$DIR/.settings.json.bak" || fail 'committed recovery did not refresh settings backup'

echo 'Interrupted settings/profile transaction recovery: OK'
