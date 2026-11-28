#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLAYER="$ROOT/components/Player.qml"
OSD="$ROOT/components/osd/SystemOsd.qml"
SHELL_QML="$ROOT/shell.qml"
CONFIG="$ROOT/Config.qml"
PAGE="$ROOT/components/settings/pages/SettingsPlayerPage.qml"
SECTION="$ROOT/components/settings/sections/SettingsOsdSection.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
RESETS="$ROOT/js/settings/SettingsResets.js"
PERSISTENCE="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplyBehaviour.js"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"
CHECK="$ROOT/CHECK.sh"
for file in "$PLAYER" "$OSD" "$SHELL_QML" "$CONFIG" "$PAGE" "$SECTION" "$REGISTRY" "$NAV" "$RESETS" "$PERSISTENCE" "$APPLY" "$PROFILES" "$CHECK"; do
  test -f "$file" || { echo "Player media OSD test: missing $file" >&2; exit 1; }
done
python3 - "$PLAYER" "$OSD" "$SHELL_QML" "$CONFIG" "$PAGE" "$SECTION" "$REGISTRY" "$NAV" "$RESETS" "$PERSISTENCE" "$APPLY" "$PROFILES" "$CHECK" <<'PYCODE'
from pathlib import Path
import sys
(player_path, osd_path, shell_path, config_path, page_path, section_path,
 registry_path, nav_path, resets_path, persistence_path, apply_path,
 profiles_path, check_path) = map(Path, sys.argv[1:])
player = player_path.read_text(encoding="utf-8")
osd = osd_path.read_text(encoding="utf-8")
shell = shell_path.read_text(encoding="utf-8")
config = config_path.read_text(encoding="utf-8")
page = page_path.read_text(encoding="utf-8")
section = section_path.read_text(encoding="utf-8")
registry = registry_path.read_text(encoding="utf-8")
nav = nav_path.read_text(encoding="utf-8")
resets = resets_path.read_text(encoding="utf-8")
persistence = persistence_path.read_text(encoding="utf-8")
apply = apply_path.read_text(encoding="utf-8")
profiles = profiles_path.read_text(encoding="utf-8")
check = check_path.read_text(encoding="utf-8")
checks = {
    "selected Player snapshot is the single media event source": 'signal mediaTrackChanged(var snapshot)' in player and 'root.acceptPlayerSnapshot(JSON.parse(this.text))' in player,
    "media identity excludes progress/status and includes backend metadata": 'return [backend, title, artist, album].join("\\u001f")' in player and 'root.mediaOsdTrackSignature' in player,
    "first snapshot is suppressed but later track/backend changes are emitted": 'var wasInitialized = root.mediaOsdSnapshotInitialized' in player and 'if (wasInitialized && nextSignature !== previousSignature)' in player,
    "shell connects the selected Player event to the shared OSD": 'SystemOsd { id: systemOsd }' in shell and 'onMediaTrackChanged: function(snapshot) { systemOsd.showMediaOsd(snapshot) }' in shell,
    "media OSD uses existing Player metadata and artwork normalization": 'extractMediaTitle' in osd and 'extractMediaArtist' in osd and 'PlayerImage.imageSourceForPath' in osd,
    "DeaDBeeF title and Mopidy/DeaDBeeF artist metadata are normalized": 'backend === "deadbeef" ? (data.third_line || data.first_line || "")' in osd and 'backend === "deadbeef" || backend === "mopidy"' in osd,
    "media OSD shares one click-through non-focusable overlay": 'PanelWindow {' in osd and 'focusable: false' in osd and 'mask: Region {}' in osd and 'presentationMode === "media"' in osd,
    "media view contains album art, title, artist, and source": all(key in osd for key in ['root.mediaImagePath', 'root.mediaTitle', 'root.mediaArtist', 'root.mediaBackend']),
    "volume mode remains available in the same shared OSD": 'root.showVolumeOsd()' in osd and 'root.presentationMode = "volume"' in osd and 'ProgressTrack' in osd,
    "media OSD is independently configurable": all(key in config for key in ['property bool playerOsdEnabled: true', 'property int playerOsdHideDelay: 3200', 'property int playerOsdAnimationDuration: 220', 'property string animationPlayerOsdMorphProfile: "ease-in-out"']),
    "media OSD lives on the shared OSD page": '{ id: "osd", saveScope: "osd", subTabs: ["Громкость", "Плеер", "Не беспокоить"] }' in registry and 'экранный индикатор' in registry and 'selectedMode === 1' in section and 'SettingsOsdSection' in (section_path.parent.parent / "SettingsPageContent.qml").read_text(encoding="utf-8") and 'SettingsPlayerOsdSection' not in page,
    "player OSD settings change tracking and shared reset scope are registered": '"osd": [' in nav and all(key in resets for key in ['"playerOsdEnabled"', '"playerOsdHideDelay"', '"playerOsdAnimationDuration"', '"animationPlayerOsdMorphProfile"']) and 'function resetOsdSettings' in resets,
    "player module reset no longer owns OSD profile values": '"playerOsdEnabled"' not in resets[resets.find('} else if (moduleName === "player")'):resets.find('} else if (moduleName === "cava")')] and '"playerOsdEnabled"' not in resets[resets.find('function resetPlayerSettings'):resets.find('function resetMopidySettings')],
    "player OSD settings persist and are validated on profile restore": all(key in persistence for key in ['playerOsdEnabled: config.playerOsdEnabled', 'playerOsdHideDelay: config.playerOsdHideDelay', 'playerOsdAnimationDuration: config.playerOsdAnimationDuration', 'animationPlayerOsdMorphProfile: config.animationPlayerOsdMorphProfile']) and all(key in apply for key in [
        'if (o.playerOsdEnabled !== undefined)',
        'if (o.playerOsdHideDelay !== undefined)',
        'applyMorphProfile(Config, o, "animationPlayerOsdMorphProfile")',
        '["playerOsdAnimationDuration", 0, 5000]'
    ]),
    "player page profile scope excludes OSD values": 'if (scope === "player")' in profiles and 'playerOsd' in profiles and 'animationPlayerOsd' in profiles,
    "media OSD test is registered in CHECK": 'test_player_osd_media.sh' in check,
}
for label, ok in checks.items():
    if not ok:
        raise SystemExit(f"Missing Player media OSD behavior: {label}")
print("Player media OSD integration and settings contract: OK")
PYCODE
