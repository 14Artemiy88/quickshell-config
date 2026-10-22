import QtQuick
import "../../.."

Item {
    id: root

    property string label: "↺"
    property string tooltip: "Сбросить"
    property bool emphasized: false
    property bool emphasizedHoverOnly: false
    property color emphasizedColor: Config.accent
    property bool fillOnHover: false
    property bool borderOnHover: true
    property color backgroundColor: Config.settingsBackground
    property real radius: 4
    property real borderWidth: Math.max(1, Config.frameBorderWidth)
    property real fontSize: 12
    property bool fontBold: true
    readonly property bool hovered: button.hovered

    signal clicked()

    width: 30
    height: 30

    SettingsButton {
        id: button
        anchors.fill: parent
        text: root.label
        emphasized: root.emphasized && !root.emphasizedHoverOnly
        fillOnHover: root.fillOnHover
        borderOnHover: root.borderOnHover
        accentColor: root.emphasizedColor
        backgroundColor: root.backgroundColor
        textColor: root.emphasized ? root.emphasizedColor : Config.text
        hoverTextColor: Config.black
        fontSize: root.fontSize
        radius: root.radius
        borderWidth: root.borderWidth
        fontBold: root.fontBold
        tooltip: root.tooltip
        onClicked: root.clicked()
    }
}
