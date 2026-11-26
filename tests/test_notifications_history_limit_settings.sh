#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / 'Config.qml').read_text()
defaults = (root / 'js/settings/SettingsDefaults.js').read_text()
persist = (root / 'js/settings/SettingsPersistence.js').read_text()
apply = (root / 'js/settings/SettingsApplyCore.js').read_text()
schema = (root / 'js/settings/SettingsSchema.js').read_text()
resets = (root / 'js/settings/SettingsResets.js').read_text()
section = (root / 'components/settings/sections/SettingsNotificationsSection.qml').read_text()
nav = (root / 'components/settings/SettingsNavigationController.qml').read_text()
assert 'property int notificationsHistoryLimit: 30' in config
assert 'notificationsHistoryLimit: 30' in defaults
assert 'notificationsHistoryLimit: config.notificationsHistoryLimit' in persist
assert 'o.notificationsHistoryLimit !== undefined' in apply and 'Math.max(1, Math.min(200' in apply
assert 'p.notificationsHistoryLimit' in schema and 'Math.max(1, Math.min(200' in schema
assert 'notificationsHistoryLimit' in resets
assert 'label: "Размер истории"' in section and 'maximum: 200' in section and 'minimum: 1' in section
assert 'notificationsHistoryLimit' in nav
assert 'property int notificationsHistoryRetentionDays: 0' in config
assert 'notificationsHistoryRetentionDays: 0' in defaults
assert 'notificationsHistoryRetentionDays: config.notificationsHistoryRetentionDays' in persist
assert 'o.notificationsHistoryRetentionDays !== undefined' in apply
assert 'p.notificationsHistoryRetentionDays' in schema and 'Math.max(0, Math.min(365' in schema
assert 'profile.notificationsHistoryRetentionDays === undefined' in resets
assert 'label: "Срок хранения, дни"' in section and 'maximum: 365' in section and 'minimum: 0' in section
assert 'notificationsHistoryRetentionDays' in nav
print('Notification history size/age settings, profile persistence, validation and reset: OK')
PY
