#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "short-body height uses measured rich-text height": "Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace)",
    "short-body minimum remains compact with a lower floor when summary is empty": "const minimumCardHeight = hasAvatar ? 64 : (measuredSummaryHeight > 0 ? 68 : 52)",
    "measured body height determines the final card height": "return Math.max(minimumCardHeight, Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace))",
    "text is measured independently of card geometry": "width: card.textColumnWidth",
    "actions reserve bottom space when present": "const bottomSpace = hasActions ? 42 : 14",
    "empty bodies keep their separate compact layout": "const actionMinimum = hasActions ? 76 : 52",
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing expected source fragment {needle!r}"
assert "Math.max(124, Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace))" not in source, "old large minimum height must not return"
print("notifications short-body compact height: OK")
PYCODE
