import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    anchors {
        left: true
        top: true
        bottom: true
    }

    implicitWidth: 5
    color: "#00f81818"

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
