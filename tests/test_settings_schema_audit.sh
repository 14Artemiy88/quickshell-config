#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
CORE="$ROOT/js/settings/SettingsApplyCore.js"
PLAYER="$ROOT/js/settings/SettingsApplyTimerPlayer.js"
STATE="$ROOT/js/settings/SettingsApplyState.js"
SCHEMA="$ROOT/js/settings/SettingsSchema.js"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"

# New snapshots must omit obsolete aliases. Legacy full snapshots remain
# readable and are converted to sparse deltas when loaded.
! grep -Fq 'playerControlIconSize: config.playerControlIconSize' "$PERSIST"
! grep -Fq 'timerFinishedImageTopMargin: config.timerFinishedImageMargin' "$PERSIST"
! grep -Fq 'timerFinishedImageBottomMargin: config.timerFinishedImageMargin' "$PERSIST"
! grep -Fq 'mopidyShowMoveButtons: config.mopidyShowMoveButtons' "$PERSIST"

# Legacy formats must remain readable, and the damaged QColor-object shape
# must be normalized instead of stringifying to "[object Object]".
grep -Fq 'String(o.weatherToken).trim()' "$CORE"
grep -Fq 'Schema.normalizeSavedColor(o.timerFinishedBackgroundColor' "$CORE"
grep -Fq 'Schema.normalizeSavedColor(o.timerFinishedTitleColor' "$CORE"
grep -Fq 'o.playerTimeFont !== undefined' "$ROOT/js/settings/SettingsApplyTimerPlayer.js"
grep -Fq 'o.timerFinishedImageTopMargin' "$CORE"
grep -Fq 'o.mopidyShowMoveButtons' "$PLAYER"
grep -Fq 'Schema.normalizeProfiles(o.profiles, sparseProfiles)' "$STATE"
grep -Fq 'delete p.playerControlIconSize' "$SCHEMA"
grep -Fq 'delete p.timerFinishedImageTopMargin' "$SCHEMA"
grep -Fq 'delete p.mopidyShowMoveButtons' "$SCHEMA"
grep -Fq 'mopidyAlbumBold: true' "$DEFAULTS"

# Test the exact saved-settings sample structure provided by the user when it
# is available in the active workspace, without copying it into the project.
python3 - "$ROOT" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
source = pathlib.Path('/mnt/data/settings(1).json')
if source.exists():
    data = json.loads(source.read_text())
    active = data.get('activeProfile', '')
    profile = (data.get('profiles') or {}).get(active)
    root_state = {k: v for k, v in data.items() if k not in ('profiles', 'customThemes', 'activeProfile', 'profileStorageFormat')}
    assert isinstance(profile, dict), 'active profile missing'
    if data.get('profileStorageFormat') == 'sparse-v1':
        assert 'weatherToken' not in profile, 'weather token must stay global, not in profile'
        assert len(profile) < len(root_state), 'sparse active profile should be smaller than root state'
    else:
        # The original user-provided copy is the migration fixture: it contains
        # a legacy full snapshot and should be converted by the app at runtime.
        assert root_state == profile, 'legacy fixture no longer matches expected full-snapshot format'
print('settings schema audit: OK')
PY
