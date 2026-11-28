#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "summary uses a read-only selectable editor": all(fragment in source for fragment in (
        'TextEdit {\n                        id: summaryText',
        'readOnly: true', 'selectByMouse: true', 'selectByKeyboard: true',
        'persistentSelection: true', 'textFormat: TextEdit.PlainText',
    )),
    "body uses a read-only selectable rich-text editor": all(fragment in source for fragment in (
        'TextEdit {\n                        id: bodyText', 'textFormat: TextEdit.RichText',
        'readOnly: true', 'selectByMouse: true', 'selectByKeyboard: true',
        'persistentSelection: true',
    )),
    "summary handles Ctrl+C and Ctrl+Insert explicitly": 'id: summaryText' in source and source.count('event.key === Qt.Key_C || event.key === Qt.Key_Insert') == 2 and source.count('if (String(selectedText || "").length > 0) copy()') == 2,
    "body handles Ctrl+C and Ctrl+Insert explicitly": 'id: bodyText' in source and 'Keys.onPressed: function(event)' in source,
    "notification window enables keyboard focus only for a text interaction": 'focusable: root.notificationTextFocusCard !== null' in source,
    "text hover temporarily requests keyboard focus": 'card.summaryTextHovered = hovered' in source and 'card.bodyTextHovered = hovered' in source and 'root.notificationTextFocusCard = card' in source,
    "focus is released using TextEdit focus state, not unsupported PanelWindow activeChanged": 'function notificationTextKeyboardFocusIsActive()' in source and 'return summaryText.activeFocus || bodyText.activeFocus' in source and 'id: notificationTextFocusLossTimer' in source and 'onActiveChanged:' not in source,
    "TextEdit does not declare unsupported acceptedMouseButtons property": 'acceptedMouseButtons:' not in source,
    "right-click remains handled by the card-level MouseArea": 'id: cardContextMouseArea' in source and 'acceptedButtons: Qt.RightButton' in source,
    "no text context menu remains": 'notificationTextContextMenu' not in source and 'summaryTextContextArea' not in source and 'bodyTextContextArea' not in source and 'text: "Копировать"' not in source,
    "provider action buttons are absent": 'id: actionRow' not in source and 'notificationButtonActions' not in source and 'modelData.invoke()' not in source,
    "freedesktop default action remains supported": 'card.defaultAction.invoke()' in source,
    "notification card height no longer includes action-row spacing": 'hasActions' not in source and '(hasActions ? 28 : 0)' not in source,
}
for label, result in checks.items():
    assert result, f"{label}: failed"
print("notification text selection/copy, transient keyboard focus and no-provider-buttons behavior: OK")
PYCODE
