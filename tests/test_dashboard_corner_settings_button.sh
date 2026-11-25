#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/components/Dashboard.qml" <<'PY'
from pathlib import Path
import sys

qml = Path(sys.argv[1]).read_text()
assert 'component QuickAction:' not in qml and 'QuickAction {' not in qml, 'the redundant quick-action component and surfaces are removed'
assert 'label: "Лаунчер"' not in qml and 'label: "Календарь"' not in qml, 'Launcher and Calendar are not duplicated inside Dashboard'
assert 'Настроить карточки' not in qml, 'the empty state must use the existing Edit control instead of another action button'
assert 'id: settingsButton' in qml, 'Dashboard retains a dedicated Settings icon button'
button = qml[qml.index('id: settingsButton'):qml.index('id: closeButton')]
assert 'Layout.preferredWidth: 36' in button and 'Layout.preferredHeight: 36' in button, 'the Settings affordance is a compact square target'
assert 'text: "󰒓"' in button and 'font.family: "Symbols Nerd Font Mono"' in button and 'font.pixelSize: 20' in button, 'the Settings action uses the requested Nerd Font cog glyph'
assert 'color: "#55000000"' not in qml, 'Dashboard must not dim the applications behind its overlay'
dismiss_start = qml.index('id: dashboardDismissLayer')
dismiss_end = qml.index('Rectangle {\n        id: drawer', dismiss_start)
dismiss_layer = qml[dismiss_start:dismiss_end]
assert 'visible: root.open' in dismiss_layer and 'MouseArea {' in dismiss_layer and 'onClicked: root.closeRequested()' in dismiss_layer, 'the transparent dismissal layer still closes Dashboard when clicking outside the drawer'
assert 'color:' not in dismiss_layer and 'opacity:' not in dismiss_layer, 'the dismissal layer captures clicks without painting or dimming the desktop'
assert 'Accessible.role: Accessible.Button' in button and 'Accessible.name: "Открыть настройки"' in button, 'the icon has an explicit accessible name'
assert 'ToolTip.visible: settingsMouse.containsMouse' in button and 'ToolTip.text: "Настройки"' in button, 'the icon explains its purpose on hover'
assert 'root.registerNavigationTarget(settingsButton)' in button and 'root.unregisterNavigationTarget(settingsButton)' in button, 'the icon participates in spatial keyboard navigation'
assert 'root.closeRequested()' in button and 'root.settingsRequested()' in button, 'activating the icon closes Dashboard and opens general Settings'
assert 'id: cardEditButton' in qml and 'text: root.cardEditMode ? "Готово" : "Изменить"' in qml, 'card composition remains editable from the header'
assert 'Нажми «Изменить» в заголовке' in qml, 'the empty state directs users to the single card-edit entry point'
print('Dashboard icon-only corner Settings button: PASS')
PY
