#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OSD="$ROOT/components/osd/SystemOsd.qml"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
SCHEMA="$ROOT/js/settings/SettingsSchema.js"
PERSISTENCE="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplyBehaviour.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
SECTION="$ROOT/components/settings/sections/SettingsOsdSection.qml"
CHECK="$ROOT/CHECK.sh"
for file in "$OSD" "$CONFIG" "$DEFAULTS" "$SCHEMA" "$PERSISTENCE" "$APPLY" "$RESETS" "$NAV" "$SECTION" "$CHECK"; do
  test -f "$file" || { echo "Notification DND OSD test: missing $file" >&2; exit 1; }
done
python3 - "$ROOT" <<'PYCODE'
from pathlib import Path
import sys
root = Path(sys.argv[1])
osd = (root / "components/osd/SystemOsd.qml").read_text(encoding="utf-8")
config = (root / "Config.qml").read_text(encoding="utf-8")
defaults = (root / "js/settings/SettingsDefaults.js").read_text(encoding="utf-8")
persistence = (root / "js/settings/SettingsPersistence.js").read_text(encoding="utf-8")
apply = (root / "js/settings/SettingsApplyBehaviour.js").read_text(encoding="utf-8")
resets = (root / "js/settings/SettingsResets.js").read_text(encoding="utf-8")
nav = (root / "components/settings/SettingsNavigationController.qml").read_text(encoding="utf-8")
section = (root / "components/settings/sections/SettingsOsdSection.qml").read_text(encoding="utf-8")
check = (root / "CHECK.sh").read_text(encoding="utf-8")

keys = [
    "notificationsDndOsdEnabled",
    "notificationsDndOsdHideDelay",
    "notificationsDndOsdAnimationDuration",
    "animationNotificationsDndOsdMorphProfile",
]
checks = {
    "DND OSD observes the existing Config source of truth": 'function onNotificationsDoNotDisturbChanged() { root.syncDndState() }' in osd and 'Config.notificationsDoNotDisturb === true' in osd,
    "startup profile restoration primes state without flashing OSD": 'if (!Settings.loaded)' in osd and 'if (!root.dndStateInitialized)' in osd and 'function onLoadedChanged()' in osd,
    "only an actual post-load state change presents DND OSD": 'if (nextEnabled === root.dndEnabled)' in osd and 'root.showDndOsd(nextEnabled)' in osd,
    "DND OSD reuses shared click-through overlay and animation pipeline": 'PanelWindow {' in osd and 'focusable: false' in osd and 'Primitives.AnimatedVisibility' in osd and 'presentationMode === "dnd"' in osd,
    "DND state has distinct enabled and disabled presentation": 'Не беспокоить включён' in osd and 'Не беспокоить выключен' in osd and 'Всплывающие уведомления фильтруются' in osd,
    "DND OSD duration and animation profile are mode-specific": 'Config.notificationsDndOsdHideDelay' in osd and 'Config.notificationsDndOsdAnimationDuration' in osd and 'Config.animationNotificationsDndOsdMorphProfile' in osd,
    "DND OSD respects Notifications module availability and can be disabled while displayed": 'if (!Settings.notifications || !Config.notificationsDndOsdEnabled)' in osd and 'onNotificationsDndOsdEnabledChanged()' in osd,
    "DND OSD defaults are declared in Config and default profile": all(k in config and k in defaults for k in keys),
    "shared OSD page exposes DND enable and display time": 'notificationsDndOsdEnabledCheck' in section and 'notificationsDndOsdHideDelay' in section and 'selectedMode === 2' in section,
    "shared OSD page exposes configurable DND entrance animation": 'SettingsAnimationGroup' in section and 'notifications-dnd-osd-animation-profile' in section and 'notificationsDndOsdAnimationDuration' in section,
    "DND OSD settings have their own dirty/reset scope": all(k in nav for k in keys) and '"osd": [' in nav and 'function resetOsdSettings' in resets,
    "DND OSD settings are persisted in profile snapshots": all(f'{k}: config.{k}' in persistence for k in keys),
    "DND OSD settings are restored and clamped": all(k in apply for k in keys),
    "DND OSD defaults are restored by the dedicated OSD reset helper": 'function resetOsdDefaults' in resets and 'resetOsdDefaults(owner, config, profile)' in resets and all(k in resets[resets.find('function resetOsdDefaults'):resets.find('function resetOsdSettings') ] for k in keys),
    "DND OSD regression test is registered in CHECK": 'test_notifications_dnd_osd.sh' in check,
}
for label, ok in checks.items():
    if not ok:
        raise SystemExit(f"Missing Notification DND OSD behavior: {label}")
print("Notification DND OSD integration and profile settings contract: OK")
PYCODE
node - "$SCHEMA" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const source = fs.readFileSync(process.argv[2], 'utf8')
  .replace(/^\.pragma library\s*/m, '')
  .replace(/^\.import .*$/gm, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.normalizeProfileForTest = normalizeProfile;', context);
const normalize = context.normalizeProfileForTest;
const legacyFull = normalize({ notificationsDoNotDisturb: false }, false);
assert.strictEqual(legacyFull.notificationsDndOsdEnabled, true, 'legacy full profiles receive default enabled OSD');
assert.strictEqual(legacyFull.notificationsDndOsdHideDelay, 1800, 'legacy full profiles receive default display duration');
assert.strictEqual(legacyFull.notificationsDndOsdAnimationDuration, 180, 'legacy full profiles receive default animation duration');
assert.strictEqual(legacyFull.animationNotificationsDndOsdMorphProfile, 'ease-in-out', 'legacy full profiles receive default animation profile');
const sparseEmpty = normalize({}, true);
assert(!Object.prototype.hasOwnProperty.call(sparseEmpty, 'notificationsDndOsdEnabled'), 'empty sparse profile must not gain an override');
const sparse = normalize({ notificationsDndOsdEnabled: false, notificationsDndOsdHideDelay: 25000, notificationsDndOsdAnimationDuration: -10, animationNotificationsDndOsdMorphProfile: 'invalid' }, true);
assert.strictEqual(sparse.notificationsDndOsdEnabled, false, 'sparse false override is preserved');
assert.strictEqual(sparse.notificationsDndOsdHideDelay, 10000, 'duration is capped');
assert.strictEqual(sparse.notificationsDndOsdAnimationDuration, 0, 'animation duration is clamped');
assert(!Object.prototype.hasOwnProperty.call(sparse, 'animationNotificationsDndOsdMorphProfile'), 'invalid sparse animation profile is removed');
console.log('Notification DND OSD profile migration, sparse override and bounds: OK');
NODE
