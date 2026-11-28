#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/mopidy/MopidyQueueTrackRow.qml"

grep -Fq 'import "../primitives" as Primitives' "$FILE"
grep -Fq 'id: artistLineMorph' "$FILE"
grep -Fq 'visible: (Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist)' "$FILE" || grep -Fq 'Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist' "$FILE"
grep -Fq 'fromGeometry: Qt.rect(0, parent.height, parent.width, 0)' "$FILE"
grep -Fq 'progress: Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist ? 1 : 0' "$FILE"
grep -Fq 'height: Math.max(1, artistLineMorph.geometryY' "$FILE"
grep -Fq 'artistLineMorph.normalizedProgress <= 0.001' "$FILE"
grep -Fq 'height: controller.effectiveTrackRowHeight' "$FILE"
if grep -Fq 'visible: Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist' "$FILE"; then
    echo 'Old immediate artist-line visibility is still present' >&2
    exit 1
fi
printf 'Mopidy queue artist line morph: OK\n'

# Entry/exit motion uses the shared Expressive profile without changing geometry timing.
grep -Fq 'animationProfile: Config.animationMopidyMorphProfile' "$FILE"
grep -Fq 'animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")' "$FILE"
grep -Fq 'animationPhase: Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist ? "enter" : "exit"' "$FILE"
grep -Fq 'readonly property real artistGap:' "$FILE"
grep -Fq 'artistLineMorph.artistGap * artistLineMorph.normalizedProgress' "$FILE"
