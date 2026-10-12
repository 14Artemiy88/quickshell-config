import QtQuick
import QtQuick.Controls
import ".."
import "../.."

Item {
    id: root

    property color backgroundColor: Config.transparent
    property color hoverBackgroundColor: Config.transparent
    property bool hoverBackgroundEnabled: false
    property color borderColor: Config.transparent
    property color hoverBorderColor: Config.accent
    property real borderWidth: 0
    property real hoverBorderWidth: 1
    property bool hoverBorderEnabled: false
    property real cornerRadius: 4
    property bool interactionEnabled: true
    property int acceptedButtons: Qt.LeftButton
    property int cursorShape: Qt.PointingHandCursor
    property bool wheelEnabled: false
    property string toolTipText: ""

    default property alias contentData: contentHost.data
    readonly property bool hovered: mouseArea.containsMouse

    signal clicked()
    signal buttonClicked(int button)
    signal wheelRequested(var wheelEvent)

    implicitWidth: 22
    implicitHeight: 22

    // Keep internal layers explicitly in Item.data so caller-provided default
    // children are routed only to contentHost.data.
    data: [
        Rectangle {
            anchors.fill: parent
            z: 0
            radius: root.cornerRadius
            color: root.hovered && root.hoverBackgroundEnabled
                ? root.hoverBackgroundColor : root.backgroundColor
            border.width: root.hovered && root.hoverBorderEnabled
                ? root.hoverBorderWidth : root.borderWidth
            border.color: root.hovered && root.hoverBorderEnabled
                ? root.hoverBorderColor : root.borderColor
        },
        Item {
            id: contentHost
            anchors.fill: parent
            z: 1
        },
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            z: 2
            enabled: root.interactionEnabled
            acceptedButtons: root.acceptedButtons
            hoverEnabled: true
            cursorShape: root.interactionEnabled ? root.cursorShape : Qt.ArrowCursor
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton)
                    root.clicked()
                root.buttonClicked(mouse.button)
            }
            onWheel: wheel => {
                if (!root.wheelEnabled) {
                    wheel.accepted = false
                    return
                }
                root.wheelRequested(wheel)
            }
        }
    ]

    ToolTip.visible: root.toolTipText.length > 0 && root.hovered
    ToolTip.text: root.toolTipText
}
