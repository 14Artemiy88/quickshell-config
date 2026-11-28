#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'property var notificationTextFocusCard: null' in source
assert 'focusable: root.notificationTextFocusCard !== null' in source, 'notification PanelWindow must opt into keyboard focus only during text interaction'
assert 'WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand' not in source, 'do not force keyboard interactivity permanently'
assert 'onActiveChanged:' not in source, 'PanelWindow/QsWindow does not expose Window.activeChanged in Quickshell 0.3.1'
assert 'function notificationTextKeyboardFocusIsActive()' in source
assert 'return summaryText.activeFocus || bodyText.activeFocus' in source, 'use actual TextEdit keyboard focus targets'
assert 'id: notificationTextFocusLossTimer' in source and 'interval: 100' in source, 'defer focus loss to allow handoff between the two editors'
assert 'card.notificationTextFocusSessionHadFocus = false' in source
assert 'root.notificationTextFocusDeniedCard = card' in source, 'do not immediately reacquire focus after switching to another window'
assert 'root.notificationTextFocusDeniedCard === card' in source, 'focus denial is scoped to the previously focused notification only'
assert 'if (card.summaryTextHovered || card.bodyTextHovered)' in source, 'only deny reacquisition while the pointer remains over text'
assert source.count('Keys.onPressed: function(event)') >= 2
assert source.count('event.key === Qt.Key_C || event.key === Qt.Key_Insert') == 2
assert source.count('if (String(selectedText || "").length > 0) copy()') == 2
assert 'summaryTextHoverHandler' in source and 'bodyTextHoverHandler' in source
assert 'notificationTextContextMenu' not in source, 'text interaction must not show a context menu'
print('notification selectable text obtains transient keyboard focus and copies with Ctrl+C: OK')
PYCODE
