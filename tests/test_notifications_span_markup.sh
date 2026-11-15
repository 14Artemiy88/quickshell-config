#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "span is part of the parsed notification markup subset": r"b|strong|i|em|u|a|br|html|tt|span",
    "Pango foreground is parsed explicitly": r"const foregroundMatch = /\bforeground\s*=\s*",
    "foreground color goes through a sanitizer": "root.safeNotificationColor(foregroundMatch[2])",
    "color sanitizer permits common color names": "if (/^[a-z]{1,24}$/i.test(color)) return color.toLowerCase()",
    "color sanitizer permits hexadecimal colors": r"/^#(?:[0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(color)",
    "color sanitizer permits numeric rgb/rgba forms": r"/^rgba?\(",
    "span style is rebuilt from sanitized style fragments": "root.escapeNotificationAttribute(styles.join(\" \"))",
    "foreground is mapped to CSS color": 'styles.push("color: " + foreground + ";")',
    "background is mapped to CSS background-color": 'styles.push("background-color: " + background + ";")',
    "text weight and style use bounded value sets": "^(?:normal|bold|bolder|lighter|[1-9]00)$",
    "font-family rejects CSS delimiters": "^[a-z0-9 _,-]{1,64}$",
    "span tags are matched for transformation": r"const markupPattern = /<\/?(?:b|strong|i|em|u|a|br|html|tt|span)",
    "ordinary text remains escaped": 'escapeNotificationText(normalized.slice(lastIndex, match.index))',
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
print("notifications Pango span markup and safe color handling: OK")
PYCODE
