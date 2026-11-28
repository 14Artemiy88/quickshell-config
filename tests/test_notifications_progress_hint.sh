#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/notifications/Notifications.qml"
python3 - "$FILE" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
checks = {
    "progress parser reads the standard int:value hint": 'const rawValue = hints["value"]',
    "missing progress hints are ignored": 'if (notification === null || notification.hints === null || notification.hints === undefined)',
    "progress parser rejects values outside 0..100": 'value < 0 || value > 100',
    "progress parser accepts only integral percentages": 'Math.floor(value) !== value',
    "each card binds its progress value from notification hints": 'property int progressValue: root.notificationProgressValue(notification)',
    "card height reserves space only when progress is present": 'card.progressValue >= 0, card.hasNotificationImage, card.hasLeadingVisual)',
    "progress track appears only for valid values": 'visible: Config.notificationsShowProgress && card.progressValue >= 0',
    "progress fill maps percentage to available bar width": 'width: parent.width * card.progressValue / 100',
    "progress fill uses the accent color": 'color: Config.accent',
    "progress bar contributes to measured card height": 'const progressSpace = hasProgress ? progressBarGap + progressBarHeight : 0',
    "progress bar height and gap follow the notification module scale": 'readonly property int progressBarHeight: Math.max(1, Math.round(5 * root.notificationUiScale))' and 'readonly property int progressBarGap: Math.round(8 * root.notificationUiScale)',
}
for description, needle in checks.items():
    assert needle in source, f"{description}: missing {needle!r}"
print("notifications int:value progress bar and adaptive-height wiring: OK")
PYCODE
