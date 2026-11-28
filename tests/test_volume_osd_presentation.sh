#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OSD="$ROOT/components/osd/SystemOsd.qml"
SHELL_QML="$ROOT/shell.qml"
CONFIG="$ROOT/Config.qml"
SECTION="$ROOT/components/settings/sections/SettingsOsdSection.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
SETTINGS="$ROOT/Settings.qml"
PERSISTENCE="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplyBehaviour.js"
CHECK="$ROOT/CHECK.sh"
for file in "$OSD" "$SHELL_QML" "$CONFIG" "$SECTION" "$REGISTRY" "$RESETS" "$SETTINGS" "$PERSISTENCE" "$APPLY" "$CHECK"; do
  test -f "$file" || { echo "Volume OSD test: missing $file" >&2; exit 1; }
done

python3 - "$OSD" "$SHELL_QML" "$CONFIG" "$SECTION" "$REGISTRY" "$RESETS" "$SETTINGS" "$PERSISTENCE" "$APPLY" "$CHECK" <<'PYCODE'
from pathlib import Path
import sys
osd_path, shell_path, config_path, section_path, registry_path, resets_path, settings_path, persistence_path, apply_path, check_path = map(Path, sys.argv[1:])
osd = osd_path.read_text(encoding="utf-8")
shell = shell_path.read_text(encoding="utf-8")
config = config_path.read_text(encoding="utf-8")
section = section_path.read_text(encoding="utf-8")
registry = registry_path.read_text(encoding="utf-8")
resets = resets_path.read_text(encoding="utf-8")
settings = settings_path.read_text(encoding="utf-8")
persistence = persistence_path.read_text(encoding="utf-8")
apply = apply_path.read_text(encoding="utf-8")
check = check_path.read_text(encoding="utf-8")

checks = {
    "native PipeWire API is used": 'import Quickshell.Services.Pipewire' in osd and 'PwObjectTracker' in osd,
    "default sink is tracked reactively": 'Pipewire.defaultAudioSink' in osd and 'objects: root.sink ? [root.sink] : []' in osd,
    "volume and mute notifications trigger updates": 'function onVolumeChanged() { root.syncAudioState() }' in osd and 'function onMutedChanged() { root.syncAudioState() }' in osd,
    "startup and sink swaps only prime state": 'if (!root.audioStateReady || root.trackedSinkId !== nextId)' in osd,
    "OSD is shown only after a real state change": 'Math.abs(nextVolume - root.volume) >= 0.5' in osd and 'nextMuted !== root.muted' in osd and 'root.showVolumeOsd()' in osd,
    "OSD window does not steal clicks or focus": 'focusable: false' in osd and 'mask: Region {}' in osd and 'WlrLayer.Overlay' in osd,
    "OSD has animated show and hide": 'Primitives.AnimatedVisibility' in osd and 'shown: root.osdVisible' in osd and 'unloadTimer.restart()' in osd,
    "volume glyph, percent, and muted label are rendered": 'Config.volumeIcon' in osd and 'Config.volumeMutedIcon' in osd and 'Без звука' in osd and 'ProgressTrack' in osd,
    "OSD works without enabling the Volumes widget": 'Settings.volumes' not in osd and 'SystemOsd { id: systemOsd }' in shell,
    "shell imports the dedicated OSD component directory": 'import "components/osd"' in shell,
    "OSD defaults and animation controls exist": 'property bool volumeOsdEnabled: true' in config and 'property int volumeOsdHideDelay: 1400' in config and 'property int volumeOsdAnimationDuration: 180' in config and 'property string animationVolumeOsdMorphProfile: "ease-in-out"' in config,
    "shared OSD page exposes a dedicated volume mode": '{ id: "osd", saveScope: "osd", subTabs: ["Громкость", "Плеер", "Не беспокоить"] }' in registry and 'selectedMode === 0' in section,
    "OSD settings can be disabled and timed": 'volumeOsdEnabled' in section and 'volumeOsdHideDelay' in section and 'settings-search-page:osd' in (section_path.parent.parent / "SettingsPageContent.qml").read_text(encoding="utf-8"),
    "OSD animation is configurable": 'animationVolumeOsdMorphProfile' in section and 'volumeOsdAnimationDuration' in section,
    "dedicated OSD reset restores volume settings": all(key in resets for key in ['"volumeOsdEnabled"', '"volumeOsdHideDelay"', '"volumeOsdAnimationDuration"', '"animationVolumeOsdMorphProfile"']) and 'function resetOsdSettings' in resets,
    "volume OSD settings are persisted": all(key in persistence for key in ['volumeOsdEnabled: config.volumeOsdEnabled', 'volumeOsdHideDelay: config.volumeOsdHideDelay', 'volumeOsdAnimationDuration: config.volumeOsdAnimationDuration', 'animationVolumeOsdMorphProfile: config.animationVolumeOsdMorphProfile']),
    "volume OSD settings are restored and validated": all(key in apply for key in [
        'if (o.volumeOsdEnabled !== undefined)',
        'if (o.volumeOsdHideDelay !== undefined)',
        'applyMorphProfile(Config, o, "animationVolumeOsdMorphProfile")',
        '["volumeOsdAnimationDuration", 0, 5000]'
    ]),
    "volume page save/reset scope excludes OSD settings": 'if (scope === "volume")' in settings and '"volumeOsdEnabled"' in settings and 'function resetOsdSettings' in resets,
    "test is registered in CHECK": 'test_volume_osd_presentation.sh' in check,
}
for message, ok in checks.items():
    if not ok:
        raise SystemExit(f"Missing Volume OSD behavior: {message}")

# The OSD must not introduce polling/process loops; PipeWire property notifications are the event source.
if 'Process {' in osd or 'Timer {' not in osd:
    raise SystemExit("OSD must use PipeWire notifications and only short-lived hide/unload timers")
print("Volume OSD presentation and settings contract: OK")
PYCODE
