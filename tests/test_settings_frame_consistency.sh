#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECTIONS="$ROOT/components/settings/sections"

# Most settings sections use the shared framed group primitive. Modules and Themes
# are intentional exceptions: the user requested an unframed layout for those tabs.
for file in \
    SettingsGeneralSection.qml \
    SettingsTimersSection.qml \
    SettingsPlayerSection.qml \
    SettingsWeatherSection.qml \
    SettingsCalendarSection.qml \
    SettingsCavaSection.qml \
    SettingsCpuRamSection.qml \
    SettingsNetworkSection.qml \
    SettingsVolumeSection.qml \
    SettingsWindowSection.qml \
    SettingsLauncherSection.qml
do
    path="$SECTIONS/$file"
    test -f "$path"
    grep -Fq 'SettingsGroup {' "$path" || {
        echo "Missing settings group in $file" >&2
        exit 1
    }
    grep -Fq 'showFrame: true' "$path" || {
        echo "Missing visible frame configuration in $file" >&2
        exit 1
    }
done

for file in SettingsModulesSection.qml SettingsColorsSection.qml; do
    path="$SECTIONS/$file"
    test -f "$path"
    grep -Fq 'SettingsGroup {' "$path" || {
        echo "Missing shared layout group in intentional frameless tab $file" >&2
        exit 1
    }
    if grep -Fq 'showFrame: true' "$path"; then
        echo "Unexpected frame in intentionally frameless tab $file" >&2
        exit 1
    fi
done

for file in \
    SettingsMopidySection.qml \
    SettingsMopidyTimeSection.qml \
    SettingsMopidyIconsSection.qml \
    SettingsMopidyStatusSection.qml
do
    path="$SECTIONS/mopidy/$file"
    test -f "$path"
    grep -Fq 'SettingsGroup {' "$path" || {
        echo "Missing framed settings group in $file" >&2
        exit 1
    }
    grep -Fq 'showFrame: true' "$path" || {
        echo "Missing visible frame configuration in $file" >&2
        exit 1
    }
done

python3 - "$ROOT/components/settings/SettingsWidget.qml" <<'PYWIDGET'
import re, sys
from pathlib import Path
source = Path(sys.argv[1]).read_text(encoding="utf-8")
pattern = re.compile(
    r'SettingsGroup\s*\{\s*'
    r'visible:\s*root\.currentOtherTab\s*===\s*2\s*&&\s*root\.currentOtherSubTab\s*===\s*0'
    r'.*?SettingsNumberField\s*\{[^}]*label:\s*"Плеер \(мс\)"',
    re.S
)
assert pattern.search(source), "Player update interval is not inside a framed group"
PYWIDGET

python3 - "$SECTIONS/mopidy/SettingsMopidyIconsSection.qml" "$SECTIONS/SettingsCpuRamSection.qml" <<'PYLAYOUT'
import re, sys
from pathlib import Path
mopidy = Path(sys.argv[1]).read_text(encoding="utf-8")
cpu = Path(sys.argv[2]).read_text(encoding="utf-8")

def groups(text):
    out = []
    for match in re.finditer(r"SettingsGroup\s*\{", text):
        start = match.start()
        open_brace = text.find("{", match.start())
        depth = 0
        quote = None
        escaped = False
        for pos in range(open_brace, len(text)):
            ch = text[pos]
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
                    out.append(text[start:pos + 1])
                    break
    return out

mg = groups(mopidy)
for title in ("Порядок верхней панели", "Иконки"):
    matches = [g for g in mg if title in g]
    assert len(matches) == 1, f"Expected one framed Mopidy group for {title!r}"
    assert "showFrame: true" in matches[0], f"{title!r} must have its own frame"
assert sum("showFrame: true" in g for g in mg) == 3, "Mopidy Icons should have separate panel, order and icon-settings frames"

cg = groups(cpu)
for title in ("Top Apps — отображение", "Список приложений"):
    matches = [g for g in cg if title in g]
    assert len(matches) == 1, f"Expected one Top Apps block for {title!r}"

# Each controlling checkbox now owns a single frame that also contains the
# conditional settings. The frame remains visible while unchecked, so the user
# can turn the feature back on without an empty detached frame appearing below.
control_groups = [
    ("Показывать заголовки CPU и памяти", "Заголовки", "Config.topAppsShowHeaders"),
    ("Показывать полосы нагрузки", "Положение и размер полос", "Config.topAppsShowBars"),
    ("Показывать строку «Система/прочее»", "Строка «Система/прочее»", "Config.topAppsShowSystemRemainder"),
]
for toggle, revealed, guard in control_groups:
    matches = [g for g in cg if toggle in g]
    assert len(matches) == 1, f"Expected one framed group for {toggle!r}"
    group = matches[0]
    assert "showFrame: true" in group, f"Checkbox {toggle!r} must have a frame"
    assert revealed in group, f"Revealed controls {revealed!r} are not inside the checkbox frame"
    outer_visible = next((line.strip() for line in group.splitlines() if re.match(r"\s*visible:", line)), "")
    assert "host.currentOtherTab === 5" in outer_visible and guard not in outer_visible, f"Frame for {toggle!r} should remain visible when unchecked"
    assert guard in group, f"Revealed controls for {toggle!r} are not conditional"

# Top Apps keeps its three toggle frames, splits bar geometry from bar colours,
# and retains a separate application-list settings frame.
assert sum("showFrame: true" in g for g in cg if "host.currentOtherTab === 5 && host.currentOtherSubTab === 2" in g) == 5, "Top Apps should have three toggle frames, a separate bar-colour frame, and one list-settings frame"
color_groups = [g for g in cg if 'heading: "Цвета полос нагрузки"' in g]
assert len(color_groups) == 1 and re.search(r"visible:\s*host\s*&&.*Config\.topAppsShowBars", color_groups[0]), "Bar-colour frame must be separate and hidden with bars disabled"
for title in ("topAppsCpuHeaderTitleField", "topAppsRamHeaderTitleField", "Положение и размер полос", "Цвета полос нагрузки", "Строка «Система/прочее»"):
    matches = [g for g in cg if title in g]
    assert len(matches) == 1, f"Expected {title!r} inside a single Top Apps group"
PYLAYOUT

echo 'Settings frame layout consistency: OK'
