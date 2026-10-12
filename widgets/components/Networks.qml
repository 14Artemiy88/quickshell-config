import QtQuick
import "primitives" as Primitives
import ".."
import QtQuick.Controls

Primitives.ModuleFrame {
    id: root
    moduleName: "networks"
    width: 300
    height: 180
    property var monitor

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            x: 10
            width: Math.max(0, root.width - 20)
            spacing: 5

            Repeater {
                model: root.monitor?.data?.network ?? []

                delegate: NetworkConnectionButton {
                    width: parent.width
                    network: modelData
                }
            }
        }
    }
}
