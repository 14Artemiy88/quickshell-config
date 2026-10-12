#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# The playlist management dialog is a separate view and receives its owner explicitly.
grep -Fq 'MopidyWidgets.MopidyPlaylistDialog {' "$ROOT/components/mopidy/Mopidy.qml"
grep -Fq 'controller: root' "$ROOT/components/mopidy/Mopidy.qml"
grep -Fq 'property var controller' "$ROOT/components/mopidy/MopidyPlaylistDialog.qml"
grep -Fq 'readonly property bool playlistManageBusy: playlistManageProcess.running' "$ROOT/components/mopidy/Mopidy.qml"

# All actions continue to call the existing controller methods.
grep -Fq 'onClicked: controller.closePlaylistDialog()' "$ROOT/components/mopidy/MopidyPlaylistDialog.qml"
grep -Fq 'onClicked: controller.submitPlaylistDialog()' "$ROOT/components/mopidy/MopidyPlaylistDialog.qml"
grep -Fq 'onAccepted: controller.submitPlaylistDialog()' "$ROOT/components/mopidy/MopidyPlaylistDialog.qml"
grep -Fq 'Keys.onEscapePressed: controller.closePlaylistDialog()' "$ROOT/components/mopidy/MopidyPlaylistDialog.qml"
grep -Fq 'controller.playlistDialogMode === "rename"' "$ROOT/components/mopidy/MopidyPlaylistDialog.qml"
grep -Fq 'enabled: !controller.playlistManageBusy' "$ROOT/components/mopidy/MopidyPlaylistDialog.qml"

# The extracted component must not depend on Mopidy.qml's former root id or process ids.
if grep -Eq '\broot\.|playlistManageProcess|controller\.playlistDialogField' "$ROOT/components/mopidy/MopidyPlaylistDialog.qml"; then
    echo 'Unexpected parent-local reference in MopidyPlaylistDialog.qml' >&2
    exit 1
fi
if grep -q 'playlistDialogField' "$ROOT/components/mopidy/Mopidy.qml"; then
    echo 'Mopidy.qml still reaches into the extracted dialog field' >&2
    exit 1
fi

echo 'Mopidy playlist dialog component: OK'
