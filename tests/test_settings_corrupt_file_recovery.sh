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
BACKUP="$XDG_CONFIG_HOME/quickshell-widgets/.settings.json.bak"
fail() { printf 'settings corrupt-file recovery test failed: %s\n' "$1" >&2; exit 1; }

# Create two known-good snapshots so the latest backup is unambiguous.
"$SETTINGS" get >/dev/null
baseline='{"weatherToken":"last-known-good","custom":{"preserve":42},"modules":{"time":true,"timer":true},"geometry":{"time":[1,2,300,50]}}'
next='{"weatherToken":"newer-current","custom":{"preserve":99},"modules":{"time":false,"timer":true},"geometry":{"time":[8,9,310,60]}}'
"$SETTINGS" set-json "$baseline"
"$SETTINGS" set-json "$next"
jq -e '.weatherToken == "newer-current" and .custom.preserve == 99 and .modules.time == false' "$BACKUP" >/dev/null || fail 'backup does not track the newest successful settings write'
cmp -s "$CFG" "$BACKUP" || fail 'backup and primary settings differ after a successful write'
[[ "$(stat -c '%a' "$BACKUP")" == 600 ]] || fail 'backup file permissions are not 600'

# A truncated settings file should be preserved, then recovered from the valid backup.
printf '{"weatherToken":"truncated","custom":' > "$CFG"
recovered=$("$SETTINGS" get 2>"$TMP_ROOT/recovery.log")
jq -e '.weatherToken == "newer-current" and .custom.preserve == 99 and .modules.time == false' <<<"$recovered" >/dev/null || fail 'truncated file did not recover the newest successful snapshot'
cmp -s "$CFG" <(printf '%s\n' "$recovered") || fail 'recovered output and canonical file differ'
corrupt_file=$(find "$(dirname "$CFG")" -maxdepth 1 -type f -name '.settings.json.corrupt.*' -print -quit)
[[ -n "$corrupt_file" ]] || fail 'truncated source file was not preserved for manual recovery'
grep -q '"truncated"' "$corrupt_file" || fail 'preserved damaged file does not contain original bytes'
[[ "$(stat -c '%a' "$corrupt_file")" == 600 ]] || fail 'preserved damaged file permissions are not 600'
jq -e 'type == "object"' "$CFG" >/dev/null || fail 'canonical settings file is not valid JSON after recovery'
[[ "$(stat -c '%a' "$CFG")" == 600 ]] || fail 'recovered canonical settings permissions are not 600'
grep -q 'last known-good' "$TMP_ROOT/recovery.log" || fail 'recovery diagnostic was not emitted on stderr'

# Empty-file recovery should follow the same path.
: > "$CFG"
recovered=$("$SETTINGS" get 2>"$TMP_ROOT/empty-recovery.log")
jq -e '.weatherToken == "newer-current" and .custom.preserve == 99' <<<"$recovered" >/dev/null || fail 'empty settings file did not recover the newest valid backup'

# Read-modify-write and whole-snapshot updates should recover first, then apply
# the requested action without dropping unrelated keys from the backup.
printf '{"weatherToken":"half-written"' > "$CFG"
"$SETTINGS" token 'token-after-recovery'
jq -e '.weatherToken == "token-after-recovery" and .custom.preserve == 99' "$CFG" >/dev/null || fail 'token update did not recover a corrupt source before applying the token'
printf '{"weatherToken":"half-written-again"' > "$CFG"
replacement='{"weatherToken":"fresh-write","migration":"set-json"}'
"$SETTINGS" set-json "$replacement"
jq -e '.weatherToken == "fresh-write" and .migration == "set-json"' "$CFG" >/dev/null || fail 'valid set-json update did not recover from a corrupt source'

# Invalid payloads must not trigger recovery, rotate backups, or alter the source.
printf '{"still":"damaged"' > "$CFG"
cp "$CFG" "$TMP_ROOT/before-invalid-payload.json"
if "$SETTINGS" set-json '{invalid' >/dev/null 2>&1; then fail 'malformed set-json payload was accepted'; fi
cmp -s "$CFG" "$TMP_ROOT/before-invalid-payload.json" || fail 'invalid payload changed the existing damaged file before validation'

# Explicitly deleting the file is a reset: stale backups must not later restore
# the old user configuration if the newly initialized defaults are damaged.
rm -f "$CFG"
reset_output=$("$SETTINGS" get)
jq -e '.weatherToken == "" and .modules.time == true' <<<"$reset_output" >/dev/null || fail 'deleting settings did not reset to defaults'
jq -e '.weatherToken == "" and .modules.time == true' "$BACKUP" >/dev/null || fail 'explicit reset retained a stale user backup'
printf '{"weatherToken":"fresh-defaults-now-damaged' > "$CFG"
reset_recovery=$("$SETTINGS" get 2>"$TMP_ROOT/reset-recovery.log")
jq -e '.weatherToken == "" and .modules.time == true' <<<"$reset_recovery" >/dev/null || fail 'corrupted post-reset defaults resurrected old settings'

# If there is no valid backup, preserve the bad bytes and initialize safe defaults.
export XDG_CONFIG_HOME="$HOME/no-backup-config"
NO_BACKUP_CFG="$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
"$SETTINGS" get >/dev/null
rm -f "$XDG_CONFIG_HOME/quickshell-widgets/.settings.json.bak"
printf 'not-json backup\n' > "$XDG_CONFIG_HOME/quickshell-widgets/.settings.json.bak"
printf '{"modules":{"time":false' > "$NO_BACKUP_CFG"
defaulted=$("$SETTINGS" get 2>"$TMP_ROOT/default-recovery.log")
jq -e 'type == "object" and .weatherToken == "" and .modules.time == true and .modules.timer == true' <<<"$defaulted" >/dev/null || fail 'defaults were not initialized after corruption without a valid backup'
[[ -n "$(find "$(dirname "$NO_BACKUP_CFG")" -maxdepth 1 -type f -name '.settings.json.corrupt.*' -print -quit)" ]] || fail 'bad file without a backup was not preserved'
backup_corrupt=$(find "$(dirname "$NO_BACKUP_CFG")" -maxdepth 1 -type f -name '.settings.json.backup-corrupt.*' -print -quit)
[[ -n "$backup_corrupt" ]] || fail 'invalid backup was not preserved'
[[ "$(stat -c '%a' "$backup_corrupt")" == 600 ]] || fail 'preserved invalid backup permissions are not 600'
[[ "$(stat -c '%a' "$NO_BACKUP_CFG")" == 600 ]] || fail 'new default settings permissions are not 600'

# A deliberately removed settings file remains a reset, not a backup restore.
rm -f "$NO_BACKUP_CFG"
reset_output=$("$SETTINGS" get)
jq -e '.weatherToken == "" and .modules.time == true' <<<"$reset_output" >/dev/null || fail 'missing settings file did not initialize defaults'

# Valid but sparse object JSON is allowed; QML fills absent fields from defaults.
printf '{}\n' | "$SETTINGS" set-json '{}'
jq -e 'type == "object" and length == 0' < <("$SETTINGS" get) >/dev/null || fail 'valid sparse settings object was rejected'

# A later write must recreate a valid backup atomically.
"$SETTINGS" token 'recovered-token' >/dev/null
jq -e '.weatherToken == "recovered-token"' "$NO_BACKUP_CFG" >/dev/null || fail 'token update failed after recovery/reset scenarios'
jq -e 'type == "object"' "$XDG_CONFIG_HOME/quickshell-widgets/.settings.json.bak" >/dev/null || fail 'valid backup was not recreated after a successful write'

if find "$(dirname "$NO_BACKUP_CFG")" -maxdepth 1 -type f -name '.settings.json.*' -name '*.tmp*' | grep -q .; then
    fail 'temporary settings files leaked'
fi

echo 'Settings corrupt-file recovery: OK'
