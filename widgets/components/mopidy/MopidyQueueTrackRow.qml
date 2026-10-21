import QtQuick
import "../.."
import "../primitives" as Primitives

// One playback queue track row. All queue mutations remain in Mopidy.qml.
Rectangle {
    id: trackRow
    property var controller
    property var itemData: null
    width: parent ? parent.width : 0
    height: Config.mopidyTrackRowHeight
    radius: 4
    color: rowMouse.containsMouse ? controller.hoverBackgroundColor(true) : Config.transparent
    border.width: controller.hoverBorderWidth(rowMouse.containsMouse)
    border.color: controller.hoverBorderColor(rowMouse.containsMouse)

    readonly property int actionWidth: (Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? 42 : 0
    readonly property int numberWidth: Config.mopidyShowTrackNumbers ? 18 : 0
    readonly property int durationWidth: 38

    Row {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 5

        Text {
            width: trackRow.numberWidth
            height: parent.height
            visible: Config.mopidyShowTrackNumbers
            text: Number(itemData.track.tlid) === controller.currentTlid ? "▶" : String(itemData.queueIndex + 1)
            color: Number(itemData.track.tlid) === controller.currentTlid ? Config.accent : controller.hoverTextColor(rowMouse.containsMouse, Config.textMuted)
            font.family: Config.font
            font.pixelSize: Config.fontSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Item {
            width: parent.width - trackRow.numberWidth - trackRow.durationWidth - trackRow.actionWidth - 15
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: (Config.mopidyTrackArtistDisplayMode === "two-lines" && itemData.track.artist) ? 2 : 0

            Text {
                id: trackTitleText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: (Config.mopidyTrackArtistDisplayMode === "one-line" || !itemData.track.artist) ? parent.height : Math.round(parent.height * 0.57)
                text: {
                    var trackName = itemData.track.name || "Без названия"
                    var artistName = itemData.track.artist || ""
                    return Config.mopidyTrackArtistDisplayMode === "one-line"
                        ? controller.formatOneLineTrack(artistName, trackName)
                        : trackName
                }
                textFormat: Config.mopidyTrackArtistDisplayMode === "one-line" ? Text.StyledText : Text.PlainText
                color: Number(itemData.track.tlid) === controller.currentTlid ? Config.accent : controller.hoverTextColor(rowMouse.containsMouse, Config.text)
                font.family: Config.mopidyTrackFont
                font.pixelSize: Config.mopidyTrackFontSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: trackArtistText
                visible: Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.max(8, parent.height - trackTitleText.height)
                text: itemData.track.artist || ""
                color: Number(itemData.track.tlid) === controller.currentTlid ? Config.accent : controller.hoverTextColor(rowMouse.containsMouse, Config.textMuted)
                font.family: Config.mopidyArtistFont
                font.pixelSize: Config.mopidyArtistFontSize
                font.bold: Config.mopidyArtistBold
                font.italic: Config.mopidyArtistItalic
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            width: trackRow.durationWidth
            height: parent.height
        }
    }

    Text {
        id: trackDurationText
        z: 3
        width: trackRow.durationWidth
        height: Math.min(28, Math.max(20, trackRow.height - 6))
        x: trackRow.width - width - 5
        y: Math.round((trackRow.height - height) / 2)
        text: controller.formatDuration(controller.trackDisplayDuration(itemData.track), controller.trackShowsRemainingTime(itemData.track))
        color: Number(itemData.track.tlid) === controller.currentTlid ? Config.accent : controller.hoverTextColor(rowMouse.containsMouse, Config.textMuted)
        font.family: Config.mopidyDurationFont
        font.pixelSize: Config.mopidyDurationFontSize
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }

    Primitives.MoveArrowButton {
        id: queueMoveUpIconButton
        z: 4
        width: 22
        height: 22
        x: trackRow.width - trackRow.durationWidth - 27 + Config.mopidyMoveUpIconX
        y: Math.round((trackRow.height - height) / 2) + Config.mopidyMoveUpIconY
        iconText: itemData.queueIndex > 0 ? Config.mopidyMoveUpIcon : ""
        iconSize: Config.mopidyMoveUpIconSize
        requestedVisible: itemData.queueIndex > 0 && Config.mopidyShowMoveUpIcon
        hideWhenDisabled: false
        baseColor: Config.textMuted
        hoverMode: Config.mopidyHoverMode
        hoverColor: Config.mopidyHoverColor
        interactionEnabled: requestedVisible && !controller.queueBusy
        onClicked: controller.moveTrack(Number(itemData.track.tlid), itemData.queueIndex - 1)
    }

    Primitives.MoveArrowButton {
        id: queueMoveDownIconButton
        z: 4
        width: 22
        height: 22
        x: trackRow.width - trackRow.durationWidth - 5 + Config.mopidyMoveDownIconX
        y: Math.round((trackRow.height - height) / 2) + Config.mopidyMoveDownIconY
        iconText: itemData.queueIndex < controller.tracks.length - 1 ? Config.mopidyMoveDownIcon : ""
        iconSize: Config.mopidyMoveDownIconSize
        requestedVisible: itemData.queueIndex < controller.tracks.length - 1 && Config.mopidyShowMoveDownIcon
        hideWhenDisabled: false
        baseColor: Config.textMuted
        hoverMode: Config.mopidyHoverMode
        hoverColor: Config.mopidyHoverColor
        interactionEnabled: requestedVisible && !controller.queueBusy
        onClicked: controller.moveTrack(Number(itemData.track.tlid), itemData.queueIndex + 1)
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        anchors.rightMargin: trackRow.actionWidth
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton)
                controller.removeTrack(Number(itemData.track.tlid))
            else if (mouse.button === Qt.LeftButton)
                controller.playTrack(Number(itemData.track.tlid))
        }
    }
}
