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

    QtObject {
        id: playlistReorderAdapter
        readonly property int count: controller ? controller.playlistItems.length : 0
        readonly property real spacing: playlistItemsView.spacing
        function geometryAt(index, host) {
            // Prefer the real delegate coordinates whenever ListView has
            // materialized the row. This keeps the reorder overlay aligned
            // with the viewport even if the list gains a header or other
            // leading content later.
            var delegate = playlistItemsView.itemAtIndex(index)
            if (delegate && delegate.mapToItem) {
                var topLeft = delegate.mapToItem(host, 0, 0)
                return {
                    x: topLeft.x,
                    y: topLeft.y,
                    width: delegate.width,
                    height: delegate.height
                }
            }

            // The first-row fallback mirrors the 4px inline header gutter
            // below. Delegate spacing applies between rows, not between the
            // ListView header and its first delegate.
            var rowHeight = Config.mopidyTrackRowHeight
            var stride = rowHeight + playlistItemsView.spacing
            return {
                x: 0,
                y: playlistItemsTopInsertionGutter.height
                    + index * stride - playlistItemsView.contentY,
                width: playlistItemsView.width,
                height: rowHeight
            }
        }
    }

    Row {
        width: parent.width
        height: 22
        spacing: 4

        Text {
            width: Math.max(0, parent.width - 56)
            height: parent.height
            text: controller.playlistsBusy ? "Загрузка…"
                : (controller.playlistContentMoveBusy ? "Сохранение порядка…" : controller.playlistTitle)
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
            enabledState: !controller.playlistsBusy && !controller.playlistContentMoveBusy
                && !controller.playlistContentActionBusy && !controller.addingToPlaylist
                && !controller.playlistContentReorderDragging && !!controller.playlistUri
            onClicked: controller.openPlaylistAddMode()
        }

        MopidyWidgets.MopidyHoverIcon {
            width: 24
            height: parent.height
            iconText: ""
            iconSize: Config.fontSize
            baseColor: Config.mopidyControlIconColor
            enabledState: !controller.playlistsBusy && !controller.playlistContentMoveBusy
                && !controller.playlistContentActionBusy && !controller.playlistContentReorderDragging
                && !!controller.playlistUri
            onClicked: controller.openRenamePlaylistDialog()
        }

        MopidyWidgets.MopidyHoverIcon {
            width: 24
            height: parent.height
            iconText: ""
            iconSize: Config.fontSize
            baseColor: Config.mopidyControlIconColor
            enabledState: !controller.playlistsBusy && !controller.playlistContentMoveBusy
                && !controller.playlistContentActionBusy && !controller.playlistContentReorderDragging
                && !!controller.playlistUri
            onClicked: controller.openDeletePlaylistDialog()
        }
    }

    ListView {
        id: playlistItemsView
        width: parent.width
        height: Math.max(0, parent.height - 26)
        clip: true
        spacing: 2
        // A long edge-scroll drag must not destroy its source delegate when
        // it leaves the viewport. Keep delegates alive only for the duration
        // of the reorder gesture; normal virtualization resumes afterwards.
        cacheBuffer: controller.playlistContentReorderDragging ? contentHeight : height * 2
        interactive: !controller.playlistContentReorderDragging
        model: controller.playlistItems
        // Reserve a small, visible insertion lane before the first track.
        // Without it, the first gap is centered at y=-spacing/2 and the
        // indicator is clipped by this ListView's viewport.
        header: Item {
            id: playlistItemsTopInsertionGutter
            width: playlistItemsView.width
            height: 4
        }
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            width: parent ? parent.width : 0
            height: Config.mopidyTrackRowHeight
            radius: 4
            color: controller.hoverBackgroundColor(playlistItemMouse.containsMouse)
            border.width: controller.hoverBorderWidth(playlistItemMouse.containsMouse)
            border.color: controller.hoverBorderColor(playlistItemMouse.containsMouse)

            readonly property int playlistMoveWidth: controller.playlistItems.length > 1 ? 30 : 0
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
                readonly property int rightControlGap: playlistMoveWidth > 0 || Config.mopidyShowPlaylistDeleteIcon ? 2 : 0
                anchors.right: playlistMoveWidth > 0 ? playlistContentMoveButtons.left : (Config.mopidyShowPlaylistDeleteIcon ? playlistContentDeleteButton.left : parent.right)
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
                visible: playlistMoveWidth > 0
                anchors.right: Config.mopidyShowPlaylistDeleteIcon ? playlistContentDeleteButton.left : parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: playlistMoveWidth
                height: parent.height
            }

            Primitives.DragReorderHandle {
                id: playlistContentReorderHandle
                visible: controller.playlistItems.length > 1
                z: 4
                width: 26
                height: 26
                anchors.right: playlistContentMoveButtons.right
                anchors.verticalCenter: parent.verticalCenter
                reorderAdapter: playlistReorderAdapter
                itemIndex: index
                dropIndicatorHost: playlistItemsView
                accessibleLabel: modelData.name || "элемент плейлиста"
                interactionEnabled: controller.playlistItems.length > 1
                    && !controller.playlistsBusy && !controller.playlistContentMoveBusy
                    && !controller.playlistContentActionBusy
                    && (!controller.playlistContentReorderDragging
                        || controller.playlistContentActiveDragHandle === playlistContentReorderHandle)
                onDraggingChanged: controller.setPlaylistContentReorderDragging(dragging, playlistContentReorderHandle)
                onDragPositionChanged: function(sceneX, sceneY) {
                    controller.updatePlaylistContentDragPosition(
                        playlistItemsView.mapFromItem(null, sceneX, sceneY).y)
                }
                onReorderRequested: function(fromIndex, toIndex) {
                    controller.movePlaylistItem(fromIndex, toIndex, modelData.name, modelData.uri)
                }
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
                interactionEnabled: !controller.playlistContentMoveBusy
                    && !controller.playlistContentReorderDragging && !controller.playlistsBusy
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
                width: Math.max(0, parent.width - playlistDeleteWidth - playlistMoveWidth)
                height: parent.height
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !controller.playlistContentMoveBusy && !controller.playlistContentActionBusy
                    && !controller.playlistContentReorderDragging && !controller.playlistsBusy
                onClicked: function(mouse) {
                    if (mouse.button === Qt.MiddleButton) {
                        if (!controller.playlistContentMoveBusy && !controller.playlistContentActionBusy
                                && !controller.playlistContentReorderDragging)
                            controller.removePlaylistItem(index, modelData.name)
                        return
                    }
                    if (mouse.button === Qt.RightButton || mouse.button === Qt.LeftButton)
                        controller.addPlaylistItem(modelData.uri, modelData.name)
                }
            }
        }
    }

    // Keep long virtualized playlists sortable beyond the initially visible
    // viewport. The drag handle reports its pointer in ListView coordinates.
    Timer {
        interval: 16
        repeat: true
        running: controller && controller.playlistContentReorderDragging
        onTriggered: {
            var pointerY = Number(controller.playlistContentDragY)
            if (!isFinite(pointerY) || pointerY < 0)
                return
            var edge = 36
            var maxY = Math.max(0, playlistItemsView.contentHeight - playlistItemsView.height)
            var previousContentY = playlistItemsView.contentY
            if (pointerY < edge && playlistItemsView.contentY > 0) {
                var strengthUp = Math.max(0.15, (edge - pointerY) / edge)
                playlistItemsView.contentY = Math.max(0, playlistItemsView.contentY - 12 * strengthUp)
            } else if (pointerY > playlistItemsView.height - edge && playlistItemsView.contentY < maxY) {
                var strengthDown = Math.max(0.15, (pointerY - (playlistItemsView.height - edge)) / edge)
                playlistItemsView.contentY = Math.min(maxY, playlistItemsView.contentY + 12 * strengthDown)
            }
            if (playlistItemsView.contentY !== previousContentY
                    && controller.playlistContentActiveDragHandle
                    && typeof controller.playlistContentActiveDragHandle.refreshDropTargetForLayoutChange === "function")
                controller.playlistContentActiveDragHandle.refreshDropTargetForLayoutChange()
        }
    }

}
