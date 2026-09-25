import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.common

import "../../launcher/theme"

PanelWindow {
    Theme { id: theme }
    id: bar

    anchors {
        top: true
        right: true
    }

    margins {
        top: 1
    }
    implicitHeight: 22
    implicitWidth: 230
    color: theme.transparent

    exclusionMode: ExclusionMode.Normal

    Rectangle {
        anchors {
            fill: parent
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 4
            leftMargin: 3
            rightMargin: 3
        }

        color: theme.barBackground
        radius: 12

        // right
        RowLayout {
            anchors {
                right: parent.right
                rightMargin: 25
            }

            spacing: 10

            Loader {
                active: true
                sourceComponent: Lang {}
            }
            // Loader {
            //     id: vpnLoader
            //     active: true
            //     sourceComponent: VPN {}
            // }
            Loader {
                id: nwLoader
                active: true
                sourceComponent: Nw {}
            }
            Loader {
                active: true
                sourceComponent: Power {}
            }
            Loader {
                active: true
                sourceComponent: Time {}
            }
        }
    }
}
