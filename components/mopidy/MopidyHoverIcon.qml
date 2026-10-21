import QtQuick
import "../primitives" as Primitives
import "../.."

Item {
    id: root

    property string iconText: ""
    property int iconSize: 16
    property int iconX: 0
    property int iconY: 0
    property color baseColor: Config.mopidyControlIconColor
    property bool enabledState: true
    property bool activeState: false
    property string toolTipText: ""
    signal clicked()
    readonly property bool hovered: hoverButton.hovered

    Primitives.HoverIconButton {
        id: hoverButton
        anchors.fill: parent
        iconText: root.iconText
        iconSize: root.iconSize
        iconX: root.iconX
        iconY: root.iconY
        baseColor: root.baseColor
        hoverMode: Config.mopidyHoverMode
        hoverColor: Config.mopidyHoverColor
        toolTipText: root.toolTipText
        iconFontFamily: Config.font
        interactionEnabled: root.enabledState
        onClicked: root.clicked()
    }
}
