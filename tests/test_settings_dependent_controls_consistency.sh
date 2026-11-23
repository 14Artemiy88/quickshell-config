#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
sections = root / "components/settings/sections"
expected = {
    "SettingsVolumeSection.qml": {
        "volumeStreamTrackOffsetMorph": "Config.volumeShowStreams",
        "volumeStreamLabelFontMorph": "Config.volumeShowStreams",
    },
    "SettingsColorsSection.qml": {
        "expandedThemeList": "root.themesExpanded",
        "customThemeRenameMorph": "root.editingColors && settings.isCustomTheme(settings.activeTheme) && !settings.currentThemeModified",
        "customThemeColorsMorph": "root.editingColors",
    },
    "SettingsWeatherSection.qml": {
        "windDirectionRowsMorph": "weatherSection.windDirectionSettingsExpanded",
        "weatherComfortOptionsMorph": "Config.weatherShowComfort",
    },
    "SettingsCavaSection.qml": {
        "cavaHideZeroBarsMorph": "Config.cavaHideWhenSilent",
    },
    "SettingsCpuRamSection.qml": {
        "topAppsHeadersMorph": "Config.topAppsShowHeaders",
        "topAppsBarGeometryMorph": "Config.topAppsShowBars",
        "topAppsBarColorsMorph": "Config.topAppsShowBars",
        "topAppsSystemRemainderMorph": "Config.topAppsShowSystemRemainder",
    },
    "SettingsCalendarSection.qml": {
        "calendarPastDaysColorMorph": "Config.calendarPastDaysColorEnabled",
    },
    "SettingsPlayerSection.qml": {
        "playerTextOutlineColorMorph": "Config.playerTextOutlineEnabled",
        "playerProgressOptionsMorph": "Config.playerShowProgress",
    },
    "SettingsTimersSection.qml": {
        "timerRandomCustomColorsMorph": 'Config.timerRandomColorMode === "custom"',
        "timerFinishedImageOptionsMorph": "Config.timerFinishedImageEnabled",
        "timerFinishedTitleColorMorph": "!Config.timerFinishedTitleUsesTimerColor",
        "timerFinishedBackgroundColorMorph": "!Config.timerFinishedBackgroundUsesTimerColor",
    },
}

def block_for_id(text: str, ident: str) -> str:
    marker = f"id: {ident}"
    pos = text.find(marker)
    assert pos >= 0, f"missing MorphGeometry id {ident}"
    start = text.rfind("MorphGeometry", 0, pos)
    brace = text.find("{", start)
    assert start >= 0 and brace >= 0, f"cannot locate MorphGeometry block for {ident}"
    depth = 0
    quote = None
    escaped = False
    for i in range(brace, len(text)):
        ch = text[i]
        if quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
            continue
        if ch in ("'", '"'):
            quote = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start:i+1]
    raise AssertionError(f"unclosed MorphGeometry block for {ident}")

count = 0
for filename, ids in expected.items():
    text = (sections / filename).read_text(encoding="utf-8")
    for ident, enabled in ids.items():
        block = block_for_id(text, ident)
        assert f"enabled: {enabled}" in block, f"{filename}:{ident} does not disable children with its controlling option"
        assert "progress:" in block, f"{filename}:{ident} lost its animated collapse/expand progress"
        count += 1

primitives = root / "components/settings/primitives"
checks = {
    "SettingsInputField.qml": "opacity: root.enabled ? 1 : 0.55",
    "SettingsComboBox.qml": "opacity: root.enabled ? 1 : 0.55",
    "SettingsCheckBox.qml": "opacity: root.enabled ? 1 : 0.55",
    "SettingsLabel.qml": "color: root.enabled ? Config.text : Config.textMuted",
    "SettingsRow.qml": "color: root.enabled ? root.labelColor : Config.textMuted",
}
for filename, token in checks.items():
    source = (primitives / filename).read_text(encoding="utf-8")
    assert token in source, f"{filename} does not follow shared disabled-control appearance"

# Parent disablement must block pointer/keyboard input while preserving exit animation bindings.
for filename, ident, flag in (
    ("SettingsVolumeSection.qml", "volumeStreamTrackOffsetMorph", "Config.volumeShowStreams"),
    ("SettingsCpuRamSection.qml", "topAppsBarColorsMorph", "Config.topAppsShowBars"),
    ("SettingsPlayerSection.qml", "playerProgressOptionsMorph", "Config.playerShowProgress"),
    ("SettingsTimersSection.qml", "timerFinishedImageOptionsMorph", "Config.timerFinishedImageEnabled"),
):
    text = (sections / filename).read_text(encoding="utf-8")
    block = block_for_id(text, ident)
    assert f"enabled: {flag}" in block
    assert "normalizedProgress > 0.001" in block, f"{ident} no longer keeps its exit animation visible"

print(f"dependent settings and control consistency: OK ({count} dependent groups, {len(checks)} shared primitives)")
PY
