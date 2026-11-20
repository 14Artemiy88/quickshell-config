#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
checks = {
    "components/mopidy/MopidyQueueTrackRow.qml": {
        'animationProfile: Config.animationMopidyMorphProfile': 2,
        'animationPhase: Config.mopidyShowTrackNumbers ? "enter" : "exit"': 1,
        'animationPhase: Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist ? "enter" : "exit"': 1,
        'animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")': 2,
    },
    "components/mopidy/MopidyFileBrowser.qml": {
        'animationProfile: Config.animationMopidyMorphProfile': 1,
        'animationPhase: controller.fileFilterOpen ? "enter" : "exit"': 1,
        'animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")': 1,
    },
    "components/mopidy/MopidyLibraryView.qml": {
        'animationProfile: Config.animationMopidyMorphProfile': 1,
        'animationPhase: searchResultTextArea.metadataText.length > 0 ? "enter" : "exit"': 1,
        'animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")': 1,
    },
}
for name, expected in checks.items():
    source = (root / name).read_text(encoding="utf-8")
    for token, count in expected.items():
        actual = source.count(token)
        assert actual == count, f"{name}: {token!r}: expected {count}, got {actual}"
    assert 'animationEasing: Config.animationEasingType("standard"' not in source, f"{name}: old standard override remains"

# Content-only migration: preserve row geometry, user-selected display modes,
# ListView models and the existing local durations.
queue = (root / "components/mopidy/MopidyQueueTrackRow.qml").read_text(encoding="utf-8")
assert 'progress: Config.mopidyShowTrackNumbers ? 1 : 0' in queue
assert 'progress: Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist ? 1 : 0' in queue
browser = (root / "components/mopidy/MopidyFileBrowser.qml").read_text(encoding="utf-8")
assert 'height: Math.max(0, parent.height - 26 - fileFilterMorph.geometryHeight)' in browser
library = (root / "components/mopidy/MopidyLibraryView.qml").read_text(encoding="utf-8")
assert 'model: controller.searchResults' in library
print("Expressive Mopidy content morph expansion: OK")
PY
