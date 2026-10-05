import QtQuick
import "../../.."

Item {
    id: root

    property string label: "↺"
    property string tooltip: "Сбросить"
    property bool emphasized: false
    property bool emphasizedHoverOnly: false
    property color emphasizedColor: Config.accent
    signal clicked()

    width: 30
    height: 30

    SettingsButton {
        anchors.fill: parent
        text: root.label
        emphasized: root.emphasized
        fillOnHover: root.emphasized && !root.emphasizedHoverOnly
        borderOnHover: root.emphasized
        accentColor: root.emphasizedColor
        backgroundColor: Config.settingsBackground
        textColor: root.emphasized ? root.emphasizedColor : Config.text
        fontSize: 12
        radius: 4
        fontBold: root.emphasized
        tooltip: root.tooltip
        onClicked: root.clicked()
    }
}
