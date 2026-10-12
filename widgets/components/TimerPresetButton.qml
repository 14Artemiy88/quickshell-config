import QtQuick
import "primitives" as Primitives
import ".."

// Compact timer preset control. Visual surface and pointer event routing are
// shared with other modules; timer-specific actions remain in TimerWidget.qml.
Item {
    id: root

    property string label: ""
    property color labelColor: Config.textDim

    signal buttonClicked(int button)
    signal wheelAdjusted(int direction, bool accelerated)

    implicitWidth: 33
    implicitHeight: 33

    Primitives.HoverButtonSurface {
        anchors.fill: parent
        backgroundColor: Config.background
        borderColor: Config.baseColor
        borderWidth: 1
        cornerRadius: 7
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.ArrowCursor
        wheelEnabled: true
        onButtonClicked: button => root.buttonClicked(button)
        onWheelRequested: wheelEvent => {
            root.wheelAdjusted(
                wheelEvent.angleDelta.y > 0 ? 1 : -1,
                (wheelEvent.modifiers & Qt.ShiftModifier) !== 0
            )
            wheelEvent.accepted = true
        }

        Text {
            anchors.centerIn: parent
            text: root.label
            color: root.labelColor
        }
    }
}
