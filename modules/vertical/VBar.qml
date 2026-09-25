import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../launcher/theme"

PanelWindow {
    Theme { id: theme }
    anchors {
        left: true
        top: true
        bottom: true
    }

    implicitWidth: 5
    color: theme.verticalBarBackground

    exclusionMode: ExclusionMode.Normal

    RowLayout {
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
        Loader {
            active: true
            sourceComponent: Workspaces {}
        }
    }
}
