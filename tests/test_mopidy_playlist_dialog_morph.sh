#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIALOG="$ROOT/components/mopidy/MopidyPlaylistDialog.qml"

# The management dialog remains mounted through both its enter and exit transitions.
grep -Fq 'visible: controller.playlistDialogVisible || dialogOverlayMorph.normalizedProgress > 0.001' "$DIALOG"
grep -Fq 'progress: controller.playlistDialogVisible ? 1 : 0' "$DIALOG"
grep -Fq 'animationDuration: Config.animationDuration(180, "appearance")' "$DIALOG"
grep -Fq 'animationEasing: Config.animationEasingType("standard", controller.playlistDialogVisible ? "enter" : "exit")' "$DIALOG"
# The overlay dims progressively while the fixed-size dialog panel scales in place.
grep -Fq 'color: Qt.rgba(0, 0, 0, 0.5333333 * dialogOverlayMorph.normalizedProgress)' "$DIALOG"
grep -Fq 'opacity: dialogOverlayMorph.normalizedProgress' "$DIALOG"
grep -Fq 'scale: 0.96 + 0.04 * dialogOverlayMorph.normalizedProgress' "$DIALOG"
grep -Fq 'enabled: controller.playlistDialogVisible' "$DIALOG"
# Keep the backdrop shield active during exit; focus is acquired only for an actually open dialog.
grep -Fq 'enabled: playlistDialogOverlay.visible' "$DIALOG"
grep -Fq 'if (!playlistDialogOverlay.visible || !controller.playlistDialogVisible) return' "$DIALOG"
# Existing actions remain connected to the controller.
grep -Fq 'onClicked: controller.closePlaylistDialog()' "$DIALOG"
grep -Fq 'onClicked: controller.submitPlaylistDialog()' "$DIALOG"
grep -Fq 'onAccepted: controller.submitPlaylistDialog()' "$DIALOG"
echo 'Mopidy playlist dialog MorphGeometry: OK'
