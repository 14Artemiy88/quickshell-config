import QtQuick
import QtQuick.Controls
import "../.."
import "../primitives" as Primitives
import "." as MopidyWidgets

// Playlist detail view. All state and mutations remain owned by Mopidy.qml.
Column {
    id: playlistContents
    property var controller
    width: parent.width
    height: Math.max(0, parent.height - 35)
    spacing: 5
    visible: controller.libraryMode === "playlistItems"

    Row {
        width: parent.width
        height: 22
        spacing: 4

        Text {
            width: Math.max(0, parent.width - 56)
            height: parent.height
            text: controller.playlistsBusy ? "Загрузка…" : controller.playlistTitle
            color: Config.accent
            font.family: Config.mopidyAlbumFont
            font.pixelSize: Config.mopidyAlbumFontSize
            font.bold: Config.mopidyAlbumBold
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        MopidyWidgets.MopidyHoverIcon {
            width: 24
            height: parent.height
            iconText: Config.mopidyAddIcon
            iconSize: Config.mopidyAddIconSize
            baseColor: Config.mopidyControlIconColor
            enabledState: !controller.playlistsBusy && !!controller.playlistUri && !controller.addingToPlaylist
            onClicked: controller.openPlaylistAddMode()
        }

        MopidyWidgets.MopidyHoverIcon {
            width: 24
            height: parent.height
            iconText: ""
            iconSize: Config.fontSize
            baseColor: Config.mopidyControlIconColor
            enabledState: !controller.playlistsBusy && !!controller.playlistUri
            onClicked: controller.openRenamePlaylistDialog()
        }

        MopidyWidgets.MopidyHoverIcon {
            width: 24
            height: parent.height
            iconText: ""
            iconSize: Config.fontSize
            baseColor: Config.mopidyControlIconColor
            enabledState: !controller.playlistsBusy && !!controller.playlistUri
            onClicked: controller.openDeletePlaylistDialog()
        }
    }

    ListView {
        width: parent.width
        height: Math.max(0, parent.height - 26)
        clip: true
        spacing: 2
        model: controller.playlistItems
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            width: parent ? parent.width : 0
            height: Config.mopidyTrackRowHeight
            radius: 4
            color: controller.hoverBackgroundColor(playlistItemMouse.containsMouse)
            border.width: controller.hoverBorderWidth(playlistItemMouse.containsMouse)
            border.color: controller.hoverBorderColor(playlistItemMouse.containsMouse)

            readonly property int playlistMoveWidth: (Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? 42 : 0
            readonly property int playlistDeleteWidth: Config.mopidyShowPlaylistDeleteIcon ? 33 : 0

            Text {
                x: 5
                width: Math.max(0, parent.width - 5 - playlistMoveWidth - playlistDeleteWidth - 43)
                height: parent.height
                text: modelData.name || "Без названия"
                color: controller.hoverTextColor(playlistItemMouse.containsMouse, Config.text)
                font.family: Config.mopidyTrackFont
                font.pixelSize: Config.mopidyTrackFontSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                readonly property int rightControlGap: (Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? 2 : (Config.mopidyShowPlaylistDeleteIcon ? 2 : 0)
                anchors.right: (Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? playlistContentMoveButtons.left : (Config.mopidyShowPlaylistDeleteIcon ? playlistContentDeleteButton.left : parent.right)
                anchors.rightMargin: 1 + rightControlGap
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                text: controller.formatDuration(modelData.duration)
                color: controller.hoverTextColor(playlistItemMouse.containsMouse, Config.textMuted)
                font.family: Config.mopidyDurationFont
                font.pixelSize: Config.mopidyDurationFontSize
                horizontalAlignment: Text.AlignRight
            }

            Item {
                id: playlistContentMoveButtons
                visible: Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon
                anchors.right: Config.mopidyShowPlaylistDeleteIcon ? playlistContentDeleteButton.left : parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: parent.height
            }

            Primitives.MoveArrowButton {
                id: playlistContentMoveUpIconButton
                z: 4
                width: 22
                height: 22
                x: playlistContentMoveButtons.x + Config.mopidyMoveUpIconX
                y: Math.round((parent.height - height) / 2) + Config.mopidyMoveUpIconY
                iconText: index > 0 ? Config.mopidyMoveUpIcon : ""
                iconSize: Config.mopidyMoveUpIconSize
                requestedVisible: index > 0 && Config.mopidyShowMoveUpIcon
                hideWhenDisabled: false
                baseColor: Config.textMuted
                hoverMode: Config.mopidyHoverMode
                hoverColor: Config.mopidyHoverColor
                interactionEnabled: requestedVisible && !controller.playlistsBusy && !controller.playlistContentMoveBusy
                onClicked: controller.movePlaylistItem(index, index - 1, modelData.name)
            }

            Primitives.MoveArrowButton {
                id: playlistContentMoveDownIconButton
                z: 4
                width: 22
                height: 22
                x: playlistContentMoveButtons.x + 21 + Config.mopidyMoveDownIconX
                y: Math.round((parent.height - height) / 2) + Config.mopidyMoveDownIconY
                iconText: index < controller.playlistItems.length - 1 ? Config.mopidyMoveDownIcon : ""
                iconSize: Config.mopidyMoveDownIconSize
                requestedVisible: index < controller.playlistItems.length - 1 && Config.mopidyShowMoveDownIcon
                hideWhenDisabled: false
                baseColor: Config.textMuted
                hoverMode: Config.mopidyHoverMode
                hoverColor: Config.mopidyHoverColor
                interactionEnabled: requestedVisible && !controller.playlistsBusy && !controller.playlistContentMoveBusy
                onClicked: controller.movePlaylistItem(index, index + 1, modelData.name)
            }

            Primitives.HoverButtonSurface {
                id: playlistContentDeleteButton
                z: 3
                visible: Config.mopidyShowPlaylistDeleteIcon
                x: parent.width - 31
                y: 1
                width: 30
                height: parent.height - 2
                cornerRadius: 3
                hoverBackgroundEnabled: Config.mopidyHoverMode === "background"
                hoverBackgroundColor: Config.mopidyHoverColor
                hoverBorderEnabled: Config.mopidyHoverMode === "frame"
                hoverBorderColor: Config.mopidyHoverColor
                hoverBorderWidth: 1
                onClicked: controller.removePlaylistItem(index, modelData.name)

                Text {
                    x: (parent.width - width) / 2 + Config.mopidyPlaylistDeleteIconX
                    y: (parent.height - height) / 2 + Config.mopidyPlaylistDeleteIconY
                    width: Math.max(1, implicitWidth)
                    height: Math.max(1, implicitHeight)
                    text: Config.mopidyPlaylistDeleteIcon
                    color: controller.playlistDeleteIconColor(playlistContentDeleteButton.hovered)
                    font.family: Config.font
                    font.pixelSize: Config.mopidyPlaylistDeleteIconSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MouseArea {
                id: playlistItemMouse
                x: 0
                y: 0
                width: Math.max(0, parent.width - (Config.mopidyShowPlaylistDeleteIcon ? 33 : 0) - ((Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? 42 : 0))
                height: parent.height
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    if (mouse.button === Qt.MiddleButton) {
                        controller.removePlaylistItem(index, modelData.name)
                        return
                    }
                    if (mouse.button === Qt.RightButton || mouse.button === Qt.LeftButton)
                        controller.addPlaylistItem(modelData.uri, modelData.name)
                }
            }
        }
    }

}
