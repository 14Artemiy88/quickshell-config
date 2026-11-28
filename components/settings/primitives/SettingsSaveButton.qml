import QtQuick
import "../../.."

// Scoped save action paired with SettingsResetButton. Availability is driven by
// the profile controller, while rendering, focus, hover and tooltip behavior
// remain delegated to the common SettingsButton primitive.
Item {
    id: root

    property bool actionAvailable: true
    property string text: ""
    property string iconText: "\uf0c7"
    property string iconFontFamily: "Symbols Nerd Font Mono"
    property string tooltip: "Сохранить"
    property color backgroundColor: "transparent"
    property real radius: 4
    property real borderWidth: Math.max(1, Config.frameBorderWidth)
    property real fontSize: 11

    signal clicked()

    width: 30
    height: 30
    visible: enabled && actionAvailable

    SettingsButton {
        anchors.fill: parent
        enabled: root.enabled && root.actionAvailable
        text: root.text
        iconText: root.iconText
        iconFontFamily: root.iconFontFamily
        fontSize: root.fontSize
        radius: root.radius
        borderWidth: root.borderWidth
        backgroundColor: root.backgroundColor
        tooltip: root.tooltip
        onClicked: root.clicked()
    }
}
