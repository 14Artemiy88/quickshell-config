#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# The top panel is a standalone component and receives the Mopidy controller explicitly.
grep -Fq 'MopidyWidgets.MopidyTopPanel {' "$ROOT/components/mopidy/Mopidy.qml"
grep -Fq 'controller: root' "$ROOT/components/mopidy/Mopidy.qml"
grep -Fq 'property var controller' "$ROOT/components/mopidy/MopidyTopPanel.qml"
# UI actions must continue to route to the original Mopidy logic.
grep -Fq 'onClicked: controller.stopPlayback()' "$ROOT/components/mopidy/MopidyTopPanel.qml"
grep -Fq 'onClicked: controller.refreshQueue()' "$ROOT/components/mopidy/MopidyTopPanel.qml"
grep -Fq 'onClicked: controller.clearQueue()' "$ROOT/components/mopidy/MopidyTopPanel.qml"
# The extracted component must not depend on the former parent-local `root` id.
if grep -Eq '\broot\.' "$ROOT/components/mopidy/MopidyTopPanel.qml"; then
    echo 'Unexpected reference to former Mopidy root id in MopidyTopPanel.qml' >&2
    exit 1
fi
# Remaining queue content is sized relative to the extracted top panel component.
grep -Fq 'parent.height - mopidyTopPanel.height - 6' "$ROOT/components/mopidy/Mopidy.qml"
echo 'Mopidy top panel component: OK'
