import QtQuick
import "../../.."

Item {
    id: root
    // Keep unavailable actions out of the layout, and hide an action immediately after it succeeds.
    property bool actionAvailable: true
    visible: enabled && actionAvailable

    property string label: "↺"
    property string iconText: ""
    property string iconFontFamily: "Symbols Nerd Font Mono"
    property string tooltip: "Сбросить"
    property bool emphasized: false
    property bool emphasizedHoverOnly: false
    property color emphasizedColor: "#ff9999"
    property color emphasizedHoverColor: "#ff6666"
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
        enabled: root.enabled
        text: root.label
        iconText: root.iconText
        iconFontFamily: root.iconFontFamily
        emphasized: root.emphasized && (!root.emphasizedHoverOnly || root.hovered)
        fillOnHover: root.fillOnHover
        borderOnHover: root.borderOnHover
        accentColor: root.emphasized
            ? (root.hovered ? root.emphasizedHoverColor : root.emphasizedColor)
            : Config.accent
        outlineColor: root.emphasized
            ? (root.hovered ? root.emphasizedHoverColor : root.emphasizedColor)
            : Config.baseColor
        disabledBorderColor: root.emphasized ? "#ff593d3d" : Config.baseColor
        disabledTextColor: root.emphasized ? "#ff9999" : Config.textMuted
        backgroundColor: root.backgroundColor
        textColor: root.emphasized
            ? (root.hovered ? root.emphasizedHoverColor : root.emphasizedColor)
            : Config.text
        hoverTextColor: Config.black
        fontSize: root.fontSize
        radius: root.radius
        borderWidth: root.borderWidth
        fontBold: root.fontBold
        tooltip: root.tooltip
        onClicked: root.clicked()
    }
}
