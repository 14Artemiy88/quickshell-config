import QtQuick
import ".."

Item {
    id: root
    width: 315
    height: 198
    property var monitor

    Column {
        x: 0
        width: parent.width
        anchors.top: parent.top
        spacing: 5

        Repeater {
            model: [root.monitor.data.top_apps?.cpu ?? [], root.monitor.data.top_apps?.mem ?? []]
            delegate: Frame {
                width: parent.width
                height: 94

                // Keep the values equally inset from both frame edges.
                // The previous Column padding was not reliably applied, so
                // use explicit geometry instead of left/rightPadding.
                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 5
                    anchors.bottomMargin: 5

                    Column {
                        anchors.fill: parent
                        Repeater {
                            model: modelData
                            delegate: Row {
                                width: parent.width
                                height: 16
                                Text {
                                    width: Math.max(0, parent.width - 60)
                                    text: modelData.name
                                    color: Config.text
                                    font.pixelSize: Config.uiFontSize(12)
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: 60
                                    text: modelData.value
                                    horizontalAlignment: Text.AlignRight
                                    color: Config.text
                                    font.pixelSize: Config.uiFontSize(12)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
