#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QML="$ROOT/components/settings/sections/SettingsVolumeSection.qml"
fail() { echo "Volume stream settings MorphGeometry: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "../../primitives"' "$QML" || fail "shared MorphGeometry import missing"
for id in volumeStreamTrackOffsetMorph volumeStreamLabelFontMorph; do
    grep -Fq "id: $id" "$QML" || fail "$id missing"
done
for id in volumeStreamTrackOffsetContent volumeStreamLabelFontContent; do
    grep -Fq "id: $id" "$QML" || fail "$id content target missing"
done
[ "$(grep -Fc 'progress: Config.volumeShowStreams ? 1 : 0' "$QML")" -ge 2 ] || fail "both stream-specific rows must follow the stream visibility toggle"
[ "$(grep -Fc 'Config.volumeShowStreams || normalizedProgress > 0.001' "$QML")" -ge 2 ] || fail "both rows must remain visible during their exit morph"
[ "$(grep -Fc 'animationDuration: Config.animationDuration(180, "appearance")' "$QML")" -ge 2 ] || fail "shared animation duration missing"
[ "$(grep -Fc 'animationEasing: Config.animationEasingType("standard", Config.volumeShowStreams ? "enter" : "exit")' "$QML")" -ge 2 ] || fail "shared enter/exit easing missing"
for key in volumeStreamTrackOffsetY volumeStreamLabelFont volumeStreamLabelFontSize; do
    grep -Fq "targetProperty: \"$key\"" "$QML" || fail "$key editor missing"
done
grep -Fq 'Config.volumeShowStreams=checked; settings.save()' "$QML" || fail "stream visibility toggle save path changed"
grep -Fq 'targetProperty: "volumeMainIconWidth"' "$QML" || fail "independent main icon width setting was removed"
grep -Fq 'targetProperty: "volumeTrackRadius"' "$QML" || fail "independent track radius setting was removed"
grep -Fq 'settingsSearchId: "volume-stream-font"' "$QML" || fail "stream font chooser missing from settings search"
echo "Volume stream settings MorphGeometry integration: OK"
