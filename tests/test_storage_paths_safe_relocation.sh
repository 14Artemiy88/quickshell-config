#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config-home"
export XDG_DATA_HOME="$TMP/data-home"
export XDG_STATE_HOME="$TMP/state-home"
export XDG_CACHE_HOME="$TMP/cache-home"
export XDG_RUNTIME_DIR="$TMP/runtime"
mkdir -p "$HOME"

CONFIG="$XDG_CONFIG_HOME/quickshell-widgets"
DATA="$XDG_DATA_HOME/quickshell-widgets"
mkdir -p "$CONFIG" "$DATA"

# Settings data and the recovery copy move together and the new writer uses
# the selected location, including paths containing spaces.
"$ROOT/scripts/settings" set-json '{"probe":"settings-relocated","weatherToken":"keep-me","modules":{"time":true,"timer":true},"geometry":{}}' >/dev/null
SETTINGS_TARGET="$TMP/custom settings/settings.json"
result="$("$ROOT/scripts/storage_paths" set settings "$SETTINGS_TARGET")"
jq -e '.ok == true and (.path | endswith("/custom settings/settings.json"))' <<<"$result" >/dev/null
[[ "$("$ROOT/scripts/storage_paths" | jq -r '.entries[]|select(.id=="settings")|.path')" == "$SETTINGS_TARGET" ]]
"$ROOT/scripts/settings" get | jq -e '.probe == "settings-relocated" and .weatherToken == "keep-me"' >/dev/null
[[ -f "$TMP/custom settings/.settings.json.bak" ]]
compgen -G "$CONFIG/settings.json.qsw-backup-*" >/dev/null
"$ROOT/scripts/settings" token "updated-after-move"
"$ROOT/scripts/settings" get | jq -e '.weatherToken == "updated-after-move"' >/dev/null

# The profile catalog has its own configurable path, independent of settings.json.
"$ROOT/scripts/settings" set-json-ui '{"profiles":{"Work":{"fontSize":15}},"activeProfile":"Work","profileOverrides":{"fontSize":17},"weatherToken":"updated-after-move"}' updated-after-move >/dev/null
PROFILES_SOURCE="$CONFIG/profiles.json"
PROFILES_TARGET="$TMP/custom profiles/profiles.json"
"$ROOT/scripts/storage_paths" set profiles "$PROFILES_TARGET" | jq -e '.ok == true and (.path | endswith("/custom profiles/profiles.json"))' >/dev/null
[[ "$($ROOT/scripts/storage_paths 2>/dev/null | jq -r '.entries[]|select(.id=="profiles")|.path')" == "$PROFILES_TARGET" ]]
"$ROOT/scripts/settings" get | jq -e '.profiles.Work.fontSize == 15 and .activeProfile == "Work" and .profileOverrides.fontSize == 17' >/dev/null
[[ -f "$TMP/custom profiles/.profiles.json.bak" ]]
compgen -G "$PROFILES_SOURCE.qsw-backup-*" >/dev/null
"$ROOT/scripts/settings" set-json-ui '{"profiles":{"Work":{"fontSize":19}},"activeProfile":"Work","profileOverrides":{"fontSize":18},"weatherToken":"updated-after-move"}' updated-after-move >/dev/null
jq -e '.Work.fontSize == 19' "$PROFILES_TARGET" >/dev/null

# Refuse an existing destination rather than overwriting unrelated content.
NOTES_SOURCE="$DATA/calendar-notes.json"
"$ROOT/scripts/calendar_notes" set 2026-10-24 "preserve this note"
EXISTING="$TMP/existing/calendar-notes.json"
mkdir -p "$(dirname "$EXISTING")"
printf '{"foreign":"do-not-overwrite"}\n' > "$EXISTING"
if "$ROOT/scripts/storage_paths" set calendarNotes "$EXISTING" > "$TMP/collision.json"; then
    echo 'existing destination should have been rejected' >&2
    exit 1
fi
jq -e '.foreign == "do-not-overwrite"' "$EXISTING" >/dev/null
[[ "$("$ROOT/scripts/storage_paths" | jq -r '.entries[]|select(.id=="calendarNotes")|.path')" == "$NOTES_SOURCE" ]]

# Notes and marks preserve existing entries and all subsequent writes use the
# new file. Their previous locations remain as dated rollback copies.
NOTES_TARGET="$TMP/custom notes/calendar-notes.json"
"$ROOT/scripts/storage_paths" set calendarNotes "$NOTES_TARGET" | jq -e '.ok == true' >/dev/null
"$ROOT/scripts/calendar_notes" get | jq -e '.["2026-10-24"] == "preserve this note"' >/dev/null
"$ROOT/scripts/calendar_notes" set 2026-10-25 "new path write"
"$ROOT/scripts/calendar_notes" get | jq -e '.["2026-10-25"] == "new path write"' >/dev/null
compgen -G "$NOTES_SOURCE.qsw-backup-*" >/dev/null

"$ROOT/scripts/calendar_marks" set 2026-10-24 true
MARKS_SOURCE="$DATA/calendar-marks.json"
MARKS_TARGET="$TMP/custom marks/calendar-marks.json"
"$ROOT/scripts/storage_paths" set calendarMarks "$MARKS_TARGET" | jq -e '.ok == true' >/dev/null
"$ROOT/scripts/calendar_marks" get | jq -e '.["2026-10-24"] == true' >/dev/null
"$ROOT/scripts/calendar_marks" set 2026-10-25 true
"$ROOT/scripts/calendar_marks" get | jq -e '.["2026-10-25"] == true' >/dev/null
compgen -G "$MARKS_SOURCE.qsw-backup-*" >/dev/null

# Invalid JSON refuses the migration without deleting the source or publishing
# a partial target.
printf '{not valid json\n' > "$MARKS_TARGET"
BAD_TARGET="$TMP/invalid-source/calendar-marks.json"
if "$ROOT/scripts/storage_paths" set calendarMarks "$BAD_TARGET" > "$TMP/invalid-source.json"; then
    echo 'invalid JSON source should have been rejected' >&2
    exit 1
fi
[[ -f "$MARKS_TARGET" && ! -e "$BAD_TARGET" ]]
[[ "$("$ROOT/scripts/storage_paths" | jq -r '.entries[]|select(.id=="calendarMarks")|.path')" == "$MARKS_TARGET" ]]

# The writer processes must re-read the registry after obtaining their old
# file lock; otherwise an operation queued during migration could write to the
# rollback path instead of the selected active file.
python3 - "$ROOT" <<'PYCODE'
from pathlib import Path
import sys
root = Path(sys.argv[1])
checks = {
    "settings writer refreshes selected path under lock": "qs_refresh_storage_file_paths" in (root / "scripts/settings").read_text() and (root / "scripts/settings").read_text().index("flock -x \"$settings_lock_fd\"") < (root / "scripts/settings").read_text().index("qs_refresh_storage_file_paths"),
    "calendar notes writer refreshes selected path under lock": "qs_refresh_storage_file_paths" in (root / "scripts/calendar_notes").read_text(),
    "calendar marks writer refreshes selected path under lock": "qs_refresh_storage_file_paths" in (root / "scripts/calendar_marks").read_text(),
}
failed = [name for name, okay in checks.items() if not okay]
if failed:
    raise SystemExit("path relocation concurrency wiring failed: " + ", ".join(failed))
PYCODE

# Paths must remain absolute and keep the canonical filename.
if "$ROOT/scripts/storage_paths" set calendarMarks 'relative/calendar-marks.json' > "$TMP/relative.json"; then
    echo 'relative target should have been rejected' >&2
    exit 1
fi
if "$ROOT/scripts/storage_paths" set calendarMarks "$TMP/not-the-right-name.json" > "$TMP/basename.json"; then
    echo 'incorrect filename should have been rejected' >&2
    exit 1
fi

# Moving settings back to its default path removes that per-file override.
"$ROOT/scripts/storage_paths" set settings "$CONFIG/settings.json" | jq -e '.ok == true' >/dev/null
[[ "$("$ROOT/scripts/storage_paths" | jq -r '.entries[]|select(.id=="settings")|.path')" == "$CONFIG/settings.json" ]]
"$ROOT/scripts/settings" get | jq -e '.weatherToken == "updated-after-move"' >/dev/null

printf 'storage paths safe relocation: OK\n'
