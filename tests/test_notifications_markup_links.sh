#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "markup is advertised": "bodyMarkupSupported: true",
    "hyperlinks are advertised": "bodyHyperlinksSupported: true",
    "formatted body uses RichText for functional anchors": "textFormat: Text.RichText",
    "popup viewport clips overflow rather than cutting off card body text": "clip: true",
    "links receive visible accent color and underline": "text-decoration: underline;",
    "explicit newlines become markup line breaks": 'replace(/\\r\\n|\\r|\\n/g, "<br>")',
    "literal less-than characters are escaped in text nodes": 'replace(/</g, "&lt;")',
    "literal greater-than characters are escaped in text nodes": 'replace(/>/g, "&gt;")',
    "ordinary ampersands are escaped while entities survive": 'replace(/&(?!(?:#\\d+|#x[\\da-f]+|[a-z][a-z0-9]+);)/gi, "&amp;")',
    "only the supported markup subset is passed through": "const markupPattern = /<\\/?(?:b|strong|i|em|u|a|br|html|tt|span)(?=\\s|\\/?>)[^<>]*>/gi",
    "link attributes are escaped before writing rich text": "escapeNotificationAttribute(href)",
    "link activation still has a handler": "onLinkActivated: function(link)",
    "only web and mail links are opened externally": "if (/^(https?:|mailto:)/i.test(url))",
    "height uses actual Text layout": "root.notificationCardHeight(card.measuredSummaryHeight, bodyMeasure.implicitHeight, card.buttonActions.length > 0, root.notificationHasBody(notification), Config.notificationsShowProgress && card.progressValue >= 0, card.hasNotificationImage, card.hasLeadingVisual)",
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
print("notifications markup, links, and literal HTML characters: OK")
PYCODE
