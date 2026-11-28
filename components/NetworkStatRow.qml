import QtQuick
import ".."

// Shared upload/download row. The presentation contract changes information
// density without altering the settings-backed regular layout.
Item {
    id: root

    property string glyph: ""
    property color accentColor: Config.networkUpload
    property string valueText: ""
    property string speedText: ""
    property string totalText: ""
    property string presentationMode: "regular"

    readonly property bool compactPresentation: root.presentationMode === "compact"
    readonly property bool regularPresentation: root.presentationMode === "regular"
    readonly property bool widePresentation: root.presentationMode === "wide"
    readonly property real presentationSizeFactor: root.compactPresentation ? 0.9
        : root.widePresentation ? 1.05 : 1
    readonly property int iconPixelSize: Math.round(Config.uiFontSize(Config.networkIconSize) * root.presentationSizeFactor)
    readonly property int valuePixelSize: Math.round(Config.uiFontSize(Config.networkValueFontSize) * root.presentationSizeFactor)
    readonly property int effectiveIconLeftPadding: root.compactPresentation
        ? Math.round(Config.networkIconLeftPadding * 0.75) : Config.networkIconLeftPadding
    readonly property int effectiveRightPadding: root.compactPresentation
        ? Math.round(Config.networkRightPadding * 0.75) : Config.networkRightPadding
    readonly property int effectiveNetworkSpacing: root.compactPresentation
        ? Math.max(1, Math.round(Config.networkSpacing * 0.75))
        : root.widePresentation ? Math.max(1, Math.round(Config.networkSpacing * 1.25))
        : Config.networkSpacing
    readonly property int iconColumnWidth: effectiveIconLeftPadding + iconPixelSize + 2
    readonly property string valueFontFamily: Config.resolveFontFamily(Config.networkFont)

    width: parent ? parent.width : 313
    height: Math.max(iconPixelSize, valuePixelSize) + root.effectiveNetworkSpacing * 2

    Text {
        id: iconText
        anchors.left: parent.left
        anchors.leftMargin: root.effectiveIconLeftPadding
        anchors.top: parent.top
        width: root.iconPixelSize + 2
        text: root.glyph
        color: root.accentColor
        font.pixelSize: root.iconPixelSize
        verticalAlignment: Text.AlignVCenter
    }

    // Compact mode prioritizes live throughput and suppresses the accumulated
    // byte count. Separate text nodes allow mode changes to cross-fade cleanly.
    Text {
        id: compactSpeedText
        anchors.left: parent.left
        anchors.leftMargin: root.iconColumnWidth
        anchors.right: parent.right
        anchors.rightMargin: root.effectiveRightPadding
        anchors.top: parent.top
        opacity: root.compactPresentation ? 1 : 0
        text: root.speedText
        color: root.accentColor
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        font.family: root.valueFontFamily
        font.pixelSize: root.valuePixelSize
        verticalAlignment: Text.AlignVCenter
        Behavior on opacity {
            NumberAnimation { duration: Config.animationDuration(120, "appearance") }
        }
    }

    Text {
        id: regularValueText
        anchors.left: parent.left
        anchors.leftMargin: root.iconColumnWidth
        anchors.right: parent.right
        anchors.rightMargin: root.effectiveRightPadding
        anchors.top: parent.top
        opacity: root.regularPresentation ? 1 : 0
        text: root.valueText
        color: root.accentColor
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        font.family: root.valueFontFamily
        font.pixelSize: root.valuePixelSize
        verticalAlignment: Text.AlignVCenter
        Behavior on opacity {
            NumberAnimation { duration: Config.animationDuration(120, "appearance") }
        }
    }

    // Wide mode gives the accumulated total its own muted column, making both
    // values easier to scan without introducing extra row height.
    Text {
        id: wideSpeedText
        anchors.left: parent.left
        anchors.leftMargin: root.iconColumnWidth
        anchors.right: wideTotalText.left
        anchors.rightMargin: 8
        anchors.top: parent.top
        opacity: root.widePresentation ? 1 : 0
        text: root.speedText
        color: root.accentColor
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        font.family: root.valueFontFamily
        font.pixelSize: root.valuePixelSize
        verticalAlignment: Text.AlignVCenter
        Behavior on opacity {
            NumberAnimation { duration: Config.animationDuration(120, "appearance") }
        }
    }

    Text {
        id: wideTotalText
        anchors.right: parent.right
        anchors.rightMargin: root.effectiveRightPadding
        anchors.top: parent.top
        width: Math.max(48, Math.min(88, parent.width * 0.22))
        opacity: root.widePresentation ? 1 : 0
        text: root.totalText
        color: Config.textDisabled
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        font.family: root.valueFontFamily
        font.pixelSize: Math.max(8, root.valuePixelSize - 1)
        verticalAlignment: Text.AlignVCenter
        Behavior on opacity {
            NumberAnimation { duration: Config.animationDuration(120, "appearance") }
        }
    }

}
