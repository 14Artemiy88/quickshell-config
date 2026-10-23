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

metadata = (root / "js/settings/SettingsMetadata.js").read_text()
color_match = re.search(r"var colorNames\s*=\s*\[(.*?)\]", metadata, re.S)
assert color_match, "SettingsMetadata.colorNames not found"
color_names = set(re.findall(r'[\"\']([A-Za-z_]\w*)[\"\']', color_match.group(1)))

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

not_saved = sorted(mutated - persisted - color_names)
not_loaded = sorted(mutated - loadable - color_names)
persisted_not_loaded = sorted(persisted - loadable - color_names)
assert not not_saved, "Settings UI fields missing from snapshots or color map: " + ", ".join(not_saved)
assert not not_loaded, "Settings UI fields missing load handling: " + ", ".join(not_loaded)
assert not persisted_not_loaded, "Persisted settings without detected loader handling: " + ", ".join(persisted_not_loaded)

# Explicitly retain coverage for the former player-time-font regression.
assert "playerTimeFont" in persisted, "playerTimeFont is no longer in the saved snapshot"
assert re.search(r"o\.playerTimeFont\s*!==\s*undefined", apply_source), "playerTimeFont is no longer restored from disk"
print(f"Settings persistence field coverage: OK ({len(mutated)} UI fields, {len(persisted)} persisted scalar fields, {len(color_names)} color fields)")
PYTHON
