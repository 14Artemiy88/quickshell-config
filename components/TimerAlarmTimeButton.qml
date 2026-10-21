import QtQuick
import "primitives" as Primitives
import ".."

// Alarm hour/minute control. The common border, background and pointer event
// surface is shared with timer presets, Networks and the media controls.
Item {
    id: root

    property string displayText: "00"
    property int acceptedButtons: Qt.LeftButton
    property bool wheelEnabled: true

    signal buttonClicked(int button)
    signal wheelRequested(var wheelEvent)

    implicitWidth: 33
    implicitHeight: 33

    Primitives.HoverButtonSurface {
        anchors.fill: parent
        backgroundColor: Config.background
        borderColor: Config.baseColor
        borderWidth: 1
        cornerRadius: 7
        acceptedButtons: root.acceptedButtons
        cursorShape: Qt.ArrowCursor
        wheelEnabled: root.wheelEnabled
        onButtonClicked: button => root.buttonClicked(button)
        onWheelRequested: wheelEvent => root.wheelRequested(wheelEvent)

        Text {
            anchors.centerIn: parent
            text: root.displayText
            color: Config.textDim
            font.family: Config.settingsFont
            font.pixelSize: 11
        }
    }
}
