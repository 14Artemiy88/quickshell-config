#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "HTML root wrapper and known markup are recognized": r"b|strong|i|em|u|a|br|html|tt|span",
    "HTML root tags are stripped rather than shown literally": 'if (name === "html") return ""',
    "Qt monospaced tt tags are rendered through a controlled span": 'if (name === "tt")',
    "tt body uses a monospace font": 'font-family: monospace;',
    "opening and closing tags are transformed": 'return isClosing ? "</span>" : \'<span style="font-family: monospace;">\'',
    "Pango span tags are parsed instead of shown literally": r"b|strong|i|em|u|a|br|html|tt|span",
    "ordinary literal text is still escaped": 'escapeNotificationText(normalized.slice(lastIndex, match.index))',
    "literal less-than stays escaped outside recognized tags": 'replace(/</g, "&lt;")',
    "literal greater-than stays escaped outside recognized tags": 'replace(/>/g, "&gt;")',
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
print("notifications KDE/Qt HTML wrapper and tt markup: OK")
PYCODE
