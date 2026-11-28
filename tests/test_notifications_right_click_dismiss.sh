#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")

assert 'id: cardContextMouseArea' in source, "notification card needs a dedicated secondary-click handler"
handler = source.split('id: cardContextMouseArea', 1)[1].split('\n                    Timer {', 1)[0]
assert 'anchors.fill: parent' in handler, "secondary click must work across the whole card"
assert 'acceptedButtons: Qt.RightButton' in handler, "handler must accept only right-clicks"
assert 'enabled: !root.layoutEditMode && card.notification !== null && !card.removalPending' in handler, "right-click dismissal must be disabled in layout edit mode and during removal"
assert 'mouse.button === Qt.RightButton' in handler, "left-clicks must not use the dismissal path"
assert 'card.notification.dismiss()' in handler, "right-click must dismiss the current notification"
assert 'card.defaultAction.invoke()' not in handler, "right-click must not invoke the freedesktop default action"
assert 'notificationTextContextMenu' not in source, "right-click must not open a text context menu"
assert 'summaryTextContextArea' not in source and 'bodyTextContextArea' not in source, "text areas must not intercept right-clicks"
assert 'acceptedMouseButtons:' not in source, "TextEdit does not expose acceptedMouseButtons as a QML property"
assert 'id: cardContextMouseArea' in source and 'acceptedButtons: Qt.RightButton' in handler, "card-level MouseArea receives right-click"
assert 'id: summaryText' in source and 'id: bodyText' in source, "both text editors remain selectable"

body = source.split('id: cardBodyMouseArea', 1)[1].split('\n                    }', 1)[0]
assert 'acceptedButtons: Qt.LeftButton' in body, "ordinary card click remains left-button only"
assert 'card.defaultAction.invoke()' in body, "left-click default action must remain intact"
assert 'id: closeButton' in source and 'card.notification.dismiss()' in source, "existing close button must remain available"
assert 'enabled: !root.layoutEditMode' in handler, "layout edit overlay must not dismiss notifications by right-click"
print('notification right-click dismissal and existing left-click actions: OK')
PYCODE
