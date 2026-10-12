import QtQuick
import "../.."

// Album grouping header shared by normal queue rows and the sticky overlay.
// State and actions are delegated to the owning Mopidy controller.
Rectangle {
    property var controller
    property var itemData: null
    property bool stickyHeader: false
    width: parent ? parent.width : 0
    height: Math.max(26, Config.mopidyAlbumFontSize + 9)
    property bool albumHovered: albumMouse.containsMouse
    color: stickyHeader ? Config.mopidyBackground : controller.hoverBackgroundColor(albumHovered)
    border.width: Config.mopidyAlbumSeparator === "frame" ? 1 : controller.hoverBorderWidth(albumHovered)
    border.color: albumHovered && Config.mopidyHoverMode === "frame" ? Config.mopidyHoverColor : Config.accent
    radius: Config.mopidyAlbumSeparator === "frame" || controller.hoverBorderWidth(albumHovered) > 0 ? 3 : 0

    Text {
        id: albumTitleText
        x: 5
        width: Math.min(implicitWidth, Math.max(0, parent.width - albumDurationText.implicitWidth - (Config.mopidyAlbumSeparator === "none" ? 5 : 20)))
        anchors.verticalCenter: parent.verticalCenter
        text: itemData ? ((itemData.albumYear ? itemData.albumYear + " - " : "") + (itemData.album || "")) : ""
        color: controller.hoverTextColor(albumHovered, Config.accent)
        font.family: Config.mopidyAlbumFont
        font.pixelSize: Config.mopidyAlbumFontSize
        font.bold: Config.mopidyAlbumBold
        elide: Text.ElideRight
    }

    Rectangle {
        id: albumSeparator
        property bool isBetween: Config.mopidyAlbumSeparator === "between-line"
        property bool isUnder: Config.mopidyAlbumSeparator === "under-line"
        visible: isBetween || isUnder
        x: isBetween
            ? albumTitleText.x + albumTitleText.width + 4
            : albumTitleText.x
        y: isBetween
            ? Math.round((parent.height - 1) / 2)
            : parent.height - 2
        width: isBetween
            ? Math.max(0, albumDurationText.x - (albumTitleText.x + albumTitleText.width + 8))
            : Math.max(0, albumDurationText.x + albumDurationText.width - albumTitleText.x)
        height: 1
        color: controller.hoverTextColor(albumHovered, Config.accent)
        opacity: 0.65
    }

    Text {
        id: albumDurationText
        width: 60
        anchors.right: parent.right
        anchors.rightMargin: 1
        anchors.verticalCenter: parent.verticalCenter
        text: controller.formatDuration(controller.albumDisplayDuration(itemData))
        color: controller.hoverTextColor(albumHovered, Config.accent)
        font.family: Config.mopidyDurationFont
        font.pixelSize: Config.mopidyDurationFontSize
        font.bold: Config.mopidyAlbumBold
        horizontalAlignment: Text.AlignRight
    }

    MouseArea {
        id: albumMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton)
                controller.removeAlbum(itemData.tlids)
        }
    }
}
