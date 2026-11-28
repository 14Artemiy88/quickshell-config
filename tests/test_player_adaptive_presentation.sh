#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import math
import sys
root = Path(sys.argv[1])
qml = (root / "components/Player.qml").read_text(encoding="utf-8")

def mode_and_scale(width):
    if width <= 260:
        mode = "compact"
        scale = max(0.72, min(1.0, width / 315.0))
    elif width >= 420:
        mode = "wide"
        scale = min(1.16, max(1.0, width / 420.0))
    else:
        mode, scale = "regular", 1.0
    return mode, scale

expected = {
    220: ("compact", 0.72),
    260: ("compact", 260 / 315),
    261: ("regular", 1.0),
    315: ("regular", 1.0),
    419: ("regular", 1.0),
    420: ("wide", 1.0),
    500: ("wide", 1.16),
    600: ("wide", 1.16),
}
for width, (wanted_mode, wanted_scale) in expected.items():
    mode, scale = mode_and_scale(width)
    assert mode == wanted_mode and math.isclose(scale, wanted_scale), (width, mode, scale)

required = (
    'readonly property real playerPresentationScale: root.compactPresentation',
    'Math.max(0.72, Math.min(1, Number(root.width) / 315))',
    'Math.min(1.16, Math.max(1, Number(root.width) / 420)) : 1',
    'function scaledPlayerSize(value, minimumValue)',
    'function scaledPlayerOffset(value)',
    'root.compactPresentation ? Math.min(configured, Math.max(1, root.width - 12)) : configured',
    'root.effectivePlayerMetaFontSize',
    'root.effectivePlayerMetaSecondaryFontSize',
    'root.effectivePlayerPlayingIconSize',
    'root.effectivePlayerPausedIconSize',
    'root.effectivePlayerNextIconSize',
    'root.effectivePlayerTimeFontSize',
    'root.effectivePlayerProgressTrackHeight',
    'root.effectivePlayerProgressY',
    'root.effectivePlayerMetadataY',
)
for token in required:
    assert token in qml, f"missing adaptive Player contract: {token}"

# Regular remains a strict 1:1 rendering mode; all persisted values are read
# from Config and are never rewritten by this presentation layer.
assert ': root.widePresentation ? Math.min(1.16, Math.max(1, Number(root.width) / 420)) : 1' in qml
assert 'Config.playerMetaFontSize =' not in qml
assert 'Config.playerNextIconSize =' not in qml
assert 'Config.playerProgressTrackHeight =' not in qml

# Artwork remains aspect-preserving and fills the available surface; this
# allows it to grow/shrink with the host geometry without cropping or changing
# the artwork path selected by the backend.
cover_start = qml.index('Image {\n        id: coverImage')
cover_end = qml.index('\n    }', cover_start) + 6
cover = qml[cover_start:cover_end]
assert 'anchors.fill: parent' in cover and 'fillMode: Image.PreserveAspectFit' in cover
assert 'source: root.imageSourceForPath(root.imagePath)' in cover

# Keep transport, source selection and optimistic seek routes intact.
for token in (
    'root.togglePlaybackForBackend(root.player.player)',
    'function selectDashboardPlayer(backendValue)',
    'root.setDashboardPlayers(JSON.parse(this.text))',
    'root.requestSeek(target)',
    'onMoved: root.requestSeek(value)',
    '"position",',
    'root.pendingSeekPlayer',
    'root.mediaTrackChanged(data)',
):
    assert token in qml, f"Player behavior route missing: {token}"

print('Player adaptive presentation: compact/regular/wide boundaries, responsive metrics, artwork and transport routes: OK')
PYTEST
