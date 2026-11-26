#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PYTHON'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
persistence = (root / "js/settings/SettingsPersistence.js").read_text()
match = re.search(r"function snapshotObject\(owner, config\) \{(.*?)\n\}", persistence, re.S)
assert match, "SettingsPersistence.snapshotObject not found"
snapshot_body = match.group(1)
persisted = set(re.findall(r"\bconfig\.([A-Za-z_]\w*)", snapshot_body))
payload_match = re.search(r"function payloadObject\(owner, config\) \{(.*?)\n\}", persistence, re.S)
assert payload_match, "SettingsPersistence.payloadObject not found"
standalone_persisted = set(re.findall(r"\bconfig\.([A-Za-z_]\w*)", payload_match.group(1)))

metadata = (root / "js/settings/SettingsMetadata.js").read_text()
color_match = re.search(r"var colorNames\s*=\s*\[(.*?)\]", metadata, re.S)
assert color_match, "SettingsMetadata.colorNames not found"
color_names = set(re.findall(r'[\"\']([A-Za-z_]\w*)[\"\']', color_match.group(1)))

config_source = (root / "Config.qml").read_text()
defaults_source = (root / "js/settings/SettingsDefaults.js").read_text()
assert "property var settingsTabOrder:" not in config_source, "obsolete flat order remains a Config runtime property"
assert "settingsTabOrder:" not in defaults_source, "obsolete flat order remains in new profile defaults"
settings_ui = "\n".join(p.read_text(errors="ignore") for p in (root / "components/settings").rglob("*.qml"))
mutated = set(re.findall(r"\bConfig\.([A-Za-z_]\w*)\s*=", settings_ui))

apply_files = list((root / "js/settings").glob("SettingsApply*.js"))
apply_source = "\n".join(p.read_text() for p in apply_files)
# Loader fields are either read directly from `o.field`, enumerated in helper
# tables, or handled as part of the common color map. Catch the literal names
# so new settings added to parameter tables are covered automatically.
loadable = set(re.findall(r"\bo\.([A-Za-z_]\w*)", apply_source))
loadable.update(re.findall(r'[\"\']([A-Za-z_]\w*)[\"\']', apply_source))
# The weather icon/font keys are generated from a shared direction list.
if "weatherWindDirectionKeys" in apply_source:
    loadable.update(f"weatherWind{direction}{suffix}"
                    for direction in ("Calm", "N", "NE", "E", "SE", "S", "SW", "W", "NW")
                    for suffix in ("Icon", "Font"))

# These former module-level animation master toggles are retained only as
# migration/runtime compatibility bridges. New profiles and snapshots encode
# their state through the explicit MorphProfile value instead.
legacy_animation_compatibility = {
    "animationMopidyMorphEnabled", "animationPlayerMorphEnabled",
    "animationWeatherMorphEnabled", "animationTimerMorphEnabled"
}
# settingsTabOrder is a migration-only input from old settings files. It is
# deliberately absent from Config/defaults/runtime snapshots and is pruned on write.
legacy_navigation_compatibility = {"settingsTabOrder"}
# Runtime sender identities are learned from NotificationServer during the
# current Quickshell process. Only DND rules persist; the observed catalog must
# never be serialized into settings snapshots or profile payloads.
runtime_only = {"notificationsSeenSenders"}
not_saved = sorted(mutated - persisted - standalone_persisted - color_names - legacy_animation_compatibility - legacy_navigation_compatibility - runtime_only)
not_loaded = sorted(mutated - loadable - color_names - runtime_only)
persisted_not_loaded = sorted(persisted - loadable - color_names)
for key in legacy_animation_compatibility:
    assert f"{key}: config.{key}" not in snapshot_body, f"legacy-only key unexpectedly returned to snapshots: {key}"
assert "settingsNavigationCollapsedGroups" in standalone_persisted, "navigation expansion is not persisted as standalone UI state"
assert "settingsNavigationCollapsedGroups" not in persisted, "navigation expansion leaked back into profile snapshots"
assert "settingsNavigationOrder" in persisted, "hierarchical navigation order is missing from profile snapshots"
assert "settingsTabOrder" not in persisted, "legacy flat navigation order leaked into profile snapshots"
assert "notificationsSeenSenders" not in persisted and "notificationsSeenSenders" not in standalone_persisted, "runtime-only sender catalog leaked into persistent settings"
assert not not_saved, "Settings UI fields missing from snapshots, standalone persistence or color map: " + ", ".join(not_saved)
assert not not_loaded, "Settings UI fields missing load handling: " + ", ".join(not_loaded)
assert not persisted_not_loaded, "Persisted settings without detected loader handling: " + ", ".join(persisted_not_loaded)

# Explicitly retain coverage for the former player-time-font regression.
assert "playerTimeFont" in persisted, "playerTimeFont is no longer in the saved snapshot"
assert re.search(r"o\.playerTimeFont\s*!==\s*undefined", apply_source), "playerTimeFont is no longer restored from disk"
print(f"Settings persistence field coverage: OK ({len(mutated)} UI fields, {len(persisted)} profile snapshot fields, {len(standalone_persisted)} standalone fields, {len(color_names)} color fields)")
PYTHON
