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
CFG="$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
PROFILES="$XDG_CONFIG_HOME/quickshell-widgets/profiles.json"
fail() { printf 'profile overlay file pruning failed: %s\n' "$1" >&2; exit 1; }

initial=$(jq -cn '{
  weatherToken:"base-token",font:"Legacy Font",fontSize:12,
  modules:{time:true,futureSensor:true},
  geometry:{time:[1,2,300,60],futureWidget:[4,5,6,7]},
  colors:{accent:"#abcdef",futureAccent:"#123456"},
  futureRoot:{revision:7,nested:{keep:true}},
  profiles:{Old:{fontSize:12}},activeProfile:"Old",profileStorageFormat:"sparse-v1"
}')
"$SETTINGS" set-json "$initial"

payload=$(jq -cn '{
  settingsPersistenceFormat:"profile-overrides-v1",
  weatherToken:"base-token",
  profiles:{Work:{fontSize:15}},profileStorageFormat:"sparse-v1",activeProfile:"Work",
  customThemes:{},profileOverrides:{fontSize:17},
  managedKeys:["weatherToken","font","fontSize","modules","geometry","colors","playerControlIconSize"],
  managedNestedKeys:{modules:["time"],geometry:["time"],colors:["accent"]}
}')
"$SETTINGS" set-json-ui "$payload" base-token >/dev/null
jq -e '
  .settingsPersistenceFormat == "profile-overrides-v1" and
  (.font == null) and (.fontSize == null) and
  .profileOverrides == {fontSize:17} and
  .modules.futureSensor == true and (.modules.time == null) and
  .geometry.futureWidget == [4,5,6,7] and (.geometry.time == null) and
  .colors.futureAccent == "#123456" and (.colors.accent == null) and
  .futureRoot.revision == 7 and .futureRoot.nested.keep == true and
  (.profiles == null)
' "$CFG" >/dev/null || fail 'compact write retained duplicate settings or discarded unknown extensions'
jq -e 'keys == ["Work"] and .Work.fontSize == 15' "$PROFILES" >/dev/null || fail 'profile catalog was not stored in profiles.json'

# A later profile save must replace, not deep-merge, the prior override object.
payload=$(jq -cn '{
  settingsPersistenceFormat:"profile-overrides-v1",weatherToken:"base-token",
  profiles:{Work:{fontSize:17}},profileStorageFormat:"sparse-v1",activeProfile:"Work",
  customThemes:{},profileOverrides:{},
  managedKeys:["weatherToken","font","fontSize","modules","geometry","colors"],
  managedNestedKeys:{modules:["time"],geometry:["time"],colors:["accent"]}
}')
"$SETTINGS" set-json-ui "$payload" base-token >/dev/null
jq -e '.profileOverrides == {} and (.profiles == null) and .futureRoot.revision == 7 and .modules.futureSensor == true and .geometry.futureWidget == [4,5,6,7] and .colors.futureAccent == "#123456"' "$CFG" >/dev/null || fail 'empty overrides were merged with stale fields or unknown data was lost'
jq -e '.Work.fontSize == 17' "$PROFILES" >/dev/null || fail 'profile save did not replace the separate catalog'
cmp -s "$CFG" "$XDG_CONFIG_HOME/quickshell-widgets/.settings.json.bak" || fail 'backup does not track compact settings snapshot'
echo 'Settings profile overlay pruning preserves unknown extensions and replaces override map: OK'
