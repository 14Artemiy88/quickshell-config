#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAIN="$ROOT/components/mopidy/Mopidy.qml"

# The add/error notice stays mounted until the complete exit animation ends.
grep -Fq 'progress: root.addNoticeVisible ? 1 : 0' "$MAIN"
grep -Fq 'visible: root.addNoticeVisible || normalizedProgress > 0.001' "$MAIN"
grep -Fq 'animationDuration: Config.animationDuration(180, "appearance")' "$MAIN"
grep -Fq 'animationEasing: Config.animationEasingType("standard", root.addNoticeVisible ? "enter" : "exit")' "$MAIN"
# The toast keeps a stable 28px-high geometry, while the inner content scales and fades.
grep -Fq 'toGeometry: fromGeometry' "$MAIN"
grep -Fq 'opacity: addNoticeMorph.normalizedProgress' "$MAIN"
grep -Fq 'scale: 0.96 + 0.04 * addNoticeMorph.normalizedProgress' "$MAIN"
grep -Fq 'parent.height - 36, noticeWidth, 28)' "$MAIN"
# Existing message timeout and success/error styling are retained.
grep -Fq 'interval: 1600' "$MAIN"
grep -Fq 'onTriggered: root.addNoticeVisible = false' "$MAIN"
grep -Fq 'border.color: root.addNoticeError ? "#ff5555" : Config.accent' "$MAIN"
grep -Fq 'text: root.addNoticeText' "$MAIN"
echo 'Mopidy add/error notice MorphGeometry: OK'
