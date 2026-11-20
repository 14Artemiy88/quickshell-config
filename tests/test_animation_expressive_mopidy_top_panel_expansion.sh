#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
panel = (root / "components/mopidy/MopidyTopPanel.qml").read_text(encoding="utf-8")
main = (root / "components/mopidy/Mopidy.qml").read_text(encoding="utf-8")

# The top-panel morphs retain their existing state targets and now use the
# module-owned duration and curve profile, with phase derived from target state.
checks = {
    "top panel reveal": (panel, "id: topPanelRevealMorph", "topPanelWrapper.topPanelRevealed ? \"enter\" : \"exit\""),
    "queue duration": (panel, "id: queueDurationMorph", "topPanelRow.queueDurationTargetVisible ? \"enter\" : \"exit\""),
    "volume percentage": (panel, "id: volumeControl", "Config.mopidyShowVolumePercent ? \"enter\" : \"exit\""),
    "add notice": (main, "id: addNoticeMorph", "root.addNoticeVisible ? \"enter\" : \"exit\""),
}
for label, (source, marker, phase) in checks.items():
    start = source.find(marker)
    assert start >= 0, f"{label}: MorphGeometry marker missing"
    end = source.find("\n            }", start)
    block = source[start:end if end >= 0 else len(source)]
    assert 'animationProfile: Config.animationMopidyMorphProfile' in block, f"{label}: configurable motion profile missing"
    assert f'animationPhase: {phase}' in block, f"{label}: phase is not derived from the target state"
    assert 'animationDuration: Config.animationDurationForProfile(' in block and 'Config.animationMopidyMorphDuration' in block, f"{label}: profile-aware module duration missing"
    assert 'animationEasing: Config.animationEasingType("standard"' not in block, f"{label}: old standard override remains"

# Preserve the visible-state wiring and the geometry/content contracts.
for token in (
    'progress: topPanelWrapper.topPanelRevealed ? 1 : 0',
    'progress: topPanelRow.queueDurationTargetVisible ? 1 : 0',
    'progress: Config.mopidyShowVolumePercent ? 1 : 0',
    'fromGeometry: Qt.rect(0, 0, parent.width, 0)',
    'toGeometry: Qt.rect(0, 0, parent.width, 24)',
    'return id === "volume" ? volumeControl.geometryWidth : 22',
):
    assert token in panel, f"top panel contract changed: {token}"
assert 'progress: root.addNoticeVisible ? 1 : 0' in main
assert 'visible: root.addNoticeVisible || normalizedProgress > 0.001' in main
assert 'opacity: addNoticeMorph.normalizedProgress' in main
assert 'scale: 0.96 + 0.04 * addNoticeMorph.normalizedProgress' in main

print("Expressive Mopidy top-panel and notice morphs: OK")
PY
