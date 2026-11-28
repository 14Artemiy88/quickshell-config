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
    "short-body minimum follows configured leading visual size while remaining compact without one": "const minimumCardHeight = hasLeadingVisual\n            ? root.notificationLeadingVisualSize + root.notificationCardPadding * 2\n            : (measuredSummaryHeight > 0 ? summaryTopOffset + measuredSummaryHeight + root.notificationCardPadding : appNameBottomOffset + root.notificationCardPadding)",
    "measured body height determines the final card height": "return Math.max(minimumCardHeight, Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace))",
    "text is measured independently of card geometry": "width: card.textColumnWidth",
    "action buttons no longer reserve bottom space": "const bottomSpace = root.notificationCardPadding",
    "empty bodies keep their compact layout without action rows": "return Math.max(leadingVisualMinimum, Math.round(52 * root.notificationUiScale), Math.ceil(summaryTopOffset + measuredSummaryHeight + summaryBottomSpace + progressSpace))",
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing expected source fragment {needle!r}"
assert "Math.max(124, Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace))" not in source, "old large minimum height must not return"
print("notifications short-body compact height: OK")
PYCODE
