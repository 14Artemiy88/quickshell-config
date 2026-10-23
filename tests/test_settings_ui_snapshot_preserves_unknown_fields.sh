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
fail() { printf 'settings UI unknown-field preservation failed: %s\n' "$1" >&2; exit 1; }

initial=$(jq -cn '{
  weatherToken:"baseline-token",
  launcherWidth:800,
  futureRoot:{revision:7,nested:{alpha:1,beta:2}},
  modules:{time:true,futureSensor:true},
  geometry:{launcher:[10,20,800,600],futureWidget:[1,2,3,4]},
  moduleFrames:{futureWidget:false},
  colors:{accent:"#abcdef",futureAccent:"#123456"},
  customThemes:{Legacy:{accent:"#abcdef",legacyPaletteField:"keep-until-deleted"}},
  profiles:{LegacyProfile:{launcherWidth:800}}
}')
"$SETTINGS" set-json "$initial"

# An older UI snapshot omits future fields. Unknown settings should survive,
# but explicit changes and deletions of complete UI-managed collections apply.
payload=$(jq -cn '{
  weatherToken:"baseline-token",
  launcherWidth:920,
  modules:{time:false},
  geometry:{launcher:[30,40,920,680]},
  moduleFrames:{launcher:true},
  colors:{accent:"#fedcba"},
  customThemes:{NewTheme:{accent:"#fedcba"}},
  profiles:{NewProfile:{launcherWidth:920}}
}')
"$SETTINGS" set-json-ui "$payload" baseline-token >/dev/null

jq -e '
  .weatherToken == "baseline-token" and
  .launcherWidth == 920 and
  .futureRoot.revision == 7 and
  .futureRoot.nested.alpha == 1 and .futureRoot.nested.beta == 2 and
  .modules.time == false and .modules.futureSensor == true and
  .geometry.launcher == [30,40,920,680] and .geometry.futureWidget == [1,2,3,4] and
  .moduleFrames.launcher == true and .moduleFrames.futureWidget == false and
  .colors.accent == "#fedcba" and .colors.futureAccent == "#123456" and
  (.customThemes | keys == ["NewTheme"]) and
  (.profiles | keys == ["NewProfile"])
' "$CFG" >/dev/null || fail 'UI snapshot lost unknown settings or failed to apply intentional collection replacements'

cmp -s "$CFG" "$XDG_CONFIG_HOME/quickshell-widgets/.settings.json.bak" || fail 'backup did not follow the merged snapshot'
echo 'Settings UI snapshot preserves unknown fields and intentional collection deletions: OK'
