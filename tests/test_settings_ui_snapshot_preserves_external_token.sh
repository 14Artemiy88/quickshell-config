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
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
SETTINGS="$ROOT/scripts/settings"
DIR="$XDG_CONFIG_HOME/quickshell-widgets"
CFG="$DIR/settings.json"
BACKUP="$DIR/.settings.json.bak"
fail() { printf 'settings UI snapshot token concurrency test failed: %s\n' "$1" >&2; exit 1; }

"$SETTINGS" get >/dev/null
"$SETTINGS" set-json '{"weatherToken":"initial-token","oldOption":1}'
baseline='initial-token'

# Simulate an external token update after QML has read the old value, followed
# by an unrelated UI save containing a stale full snapshot. The newer token
# must win while the UI's unrelated change is still persisted.
"$SETTINGS" token 'external-token'
stale_payload='{"weatherToken":"initial-token","oldOption":1,"newUiOption":true}'
result=$("$SETTINGS" set-json-ui "$stale_payload" "$baseline")
[[ "$result" == 'external-token' ]] || fail 'UI save did not return the concurrently preserved token'
jq -e '.weatherToken == "external-token" and .newUiOption == true and .oldOption == 1' "$CFG" >/dev/null || fail 'stale full snapshot overwrote external token or dropped UI changes'
cmp -s "$CFG" "$BACKUP" || fail 'backup did not track the merged UI snapshot'

# A deliberate token edit in the UI differs from the baseline and must be
# committed when the on-disk token is still the baseline.
user_payload='{"weatherToken":"user-edited-token","newUiOption":false}'
result=$("$SETTINGS" set-json-ui "$user_payload" 'external-token')
[[ "$result" == 'user-edited-token' ]] || fail 'intentional UI token change was not returned'
jq -e '.weatherToken == "user-edited-token" and .newUiOption == false' "$CFG" >/dev/null || fail 'intentional UI token change was not committed'
cmp -s "$CFG" "$BACKUP" || fail 'backup differs after intentional UI token change'

# If both sources changed the token from the same baseline, the already
# committed external token wins over a queued UI snapshot. This protects newer
# disk state when a UI edit was queued behind another writer.
"$SETTINGS" token 'latest-external-token'
conflicting_payload='{"weatherToken":"queued-user-token","newUiOption":true,"conflictCase":true}'
result=$("$SETTINGS" set-json-ui "$conflicting_payload" 'user-edited-token')
[[ "$result" == 'latest-external-token' ]] || fail 'conflicting stale UI token overrode newer external token'
jq -e '.weatherToken == "latest-external-token" and .conflictCase == true' "$CFG" >/dev/null || fail 'conflict resolution lost the latest disk token or unrelated UI fields'
cmp -s "$CFG" "$BACKUP" || fail 'backup differs after conflict resolution'

# A payload that omits weatherToken altogether must preserve the current value.
without_token='{"newUiOption":true,"custom":{"v":7}}'
result=$("$SETTINGS" set-json-ui "$without_token" 'does-not-matter')
[[ "$result" == 'latest-external-token' ]] || fail 'snapshot without weatherToken did not preserve current token'
jq -e '.weatherToken == "latest-external-token" and .custom.v == 7' "$CFG" >/dev/null || fail 'snapshot without token lost the current token or unrelated data'
cmp -s "$CFG" "$BACKUP" || fail 'backup differs after token-preserving merge'

# The QML writer must pass a persisted baseline and reconcile its committed
# token result before the queued newest snapshot is flushed.
node - "$ROOT" <<'JS'
const fs = require('fs');
const assert = require('assert');
const path = require('path');
const root = process.argv[2];
const qml = fs.readFileSync(path.join(root, 'Settings.qml'), 'utf8');
const persist = fs.readFileSync(path.join(root, 'js/settings/SettingsPersistence.js'), 'utf8');
assert(qml.includes('property string persistedWeatherToken'), 'Settings singleton must track the last disk token');
assert(qml.includes('root.persistedWeatherToken = String(root.weatherToken || "").trim()'), 'initial load must seed the token baseline');
assert(qml.includes('root.persistedWeatherToken = committedToken'), 'successful UI writes must reconcile the baseline');
assert(qml.includes('commandMode, payload, tokenBaseline'), 'writer must send the baseline with each full snapshot');
assert(qml.includes('property string tokenRequested'), 'writer must remember the token requested by its in-flight snapshot');
assert(qml.includes('root.weatherToken || "").trim() === requestedToken'), 'token reconciliation must not overwrite a newer UI edit');
assert(persist.includes('owner.writer.tokenBaseline = String(owner.persistedWeatherToken || "").trim()'), 'save helper must capture the persisted baseline');
console.log('Settings UI token concurrency wiring: OK');
JS

echo 'Settings UI snapshot preserves external token: OK'
