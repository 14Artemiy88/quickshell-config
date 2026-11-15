#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
assert "function escapeNotificationText(value)" in source
assert 'replace(/</g, "&lt;")' in source
assert 'replace(/>/g, "&gt;")' in source
assert 'replace(/&(?!(?:#\\d+|#x[\\da-f]+|[a-z][a-z0-9]+);)/gi, "&amp;")' in source
assert "escapeNotificationText(normalized.slice(lastIndex, match.index))" in source
assert "escapeNotificationText(normalized.slice(lastIndex))" in source
assert "const markupPattern = /<\\/?(?:b|strong|i|em|u|a|br|html|tt|span)(?=\\s|\\/?>)[^<>]*>/gi" in source
assert "root.formatNotificationTag(match[0], linkStyle)" in source
assert "textFormat: Text.RichText" in source
print("notifications literal HTML character escaping: OK")
PYCODE
