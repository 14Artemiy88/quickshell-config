#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsVolumeSection.qml"
PRIMITIVE="$ROOT/components/settings/primitives/SettingsAnimationGroup.qml"
fail() { echo "Volume shared animation group: FAIL: $*" >&2; exit 1; }

grep -Fq 'SettingsAnimationGroup {' "$QML" || fail "shared animation primitive missing"
grep -Fq 'duration: Config.volumeStreamsAnimationDuration' "$QML" || fail "duration binding missing"
grep -Fq 'profile: Config.animationVolumeMorphProfile' "$QML" || fail "profile binding missing"
grep -Fq 'onDurationEdited: function(value)' "$QML" || fail "duration persistence handler missing"
grep -Fq 'onProfileEdited: function(value)' "$QML" || fail "profile persistence handler missing"
grep -Fq 'id: detailsMorph' "$PRIMITIVE" || fail "shared duration reveal morph missing"
grep -Fq 'progress: root.profile !== "none" ? 1 : 0' "$PRIMITIVE" || fail "none-profile collapse missing"
grep -Fq 'root.durationLabel' "$PRIMITIVE" || fail "shared duration field missing"
echo "Volume shared animation group and animated duration details: OK"
