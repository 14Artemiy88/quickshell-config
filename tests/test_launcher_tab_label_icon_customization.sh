#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"

# New values have defaults, are persisted/restored, and participate in launcher profile reset.
for key in launcherTabLabels launcherTabIcons; do
  grep -Fq "$key" "$CONFIG"
  grep -Fq "$key" "$DEFAULTS"
  grep -Fq "$key" "$PERSIST"
  grep -Fq "$key" "$APPLY"
  grep -Fq "$key" "$RESETS"
  grep -Fq "$key" "$SECTION"
done
grep -Fq 'Config.launcherTabLabels = validLauncherLabels' "$APPLY"
grep -Fq 'Config.launcherTabIcons = validLauncherIcons' "$APPLY"
grep -Fq 'var sourceLauncherLabels = o.launcherTabLabels instanceof Array ? o.launcherTabLabels : defaultLauncherTabLabels' "$APPLY"
grep -Fq 'var sourceLauncherIcons = o.launcherTabIcons instanceof Array ? o.launcherTabIcons : defaultLauncherTabIcons' "$APPLY"
grep -Fq 'root.settings.save()' "$SECTION"
grep -Fq 'heading: "Настройка вкладок"' "$SECTION"
grep -Fq 'root.setTabLabel(launcherTabRow.modelData.id, text)' "$SECTION"
grep -Fq 'root.setTabIcon(launcherTabRow.modelData.id, text)' "$SECTION"
grep -Fq 'text: modelData.icon' "$LAUNCHER"
grep -Fq 'ToolTip.text: modelData.label' "$LAUNCHER"
grep -Fq 'return tabs[i].label' "$LAUNCHER"
grep -Fq 'var labels = Config.launcherTabLabels instanceof Array' "$LAUNCHER"
grep -Fq 'var icons = Config.launcherTabIcons instanceof Array' "$LAUNCHER"
grep -Fq '"launcherTabOrder", "launcherTabVisible", "launcherTabLabels", "launcherTabIcons", "launcherProjects"' "$RESETS"
grep -Fq 'if (profile.launcherTabLabels === undefined) config.launcherTabLabels' "$RESETS"
grep -Fq 'if (profile.launcherTabIcons === undefined) config.launcherTabIcons' "$RESETS"

# Player keeps the seven original settings subtabs; this task is specifically for the launcher.
! grep -Fq 'playerSettingsTabLabels' "$CONFIG"
! grep -Fq 'playerSettingsTabIcons' "$CONFIG"
grep -Fq 'case 2: return ["Общее", "Тишина", "Оставшееся время", "Метаданные", "Иконки", "Прогресс", "Обложка и фон"]' "$WIDGET"
! grep -Fq 'playerSettingsTabLabel' "$WIDGET"

python3 - "$CONFIG" "$DEFAULTS" <<'PY'
from pathlib import Path
import re, sys
for name in sys.argv[1:]:
    text = Path(name).read_text()
    for key in ('launcherTabLabels', 'launcherTabIcons'):
        match = re.search(rf'{key}:\s*\[([^\]]*)\]', text)
        assert match, f'{name}: missing {key} defaults'
        values = re.findall(r'"((?:[^"\\]|\\.)*)"', match.group(1))
        assert len(values) == 10, f'{name}: {key} should have ten entries, got {len(values)}'
print('Launcher tab label/icon defaults and persistence wiring: OK')
PY
printf 'launcher tab label/icon customization and Player rollback: OK\n'
