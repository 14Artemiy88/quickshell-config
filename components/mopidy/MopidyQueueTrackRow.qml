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

    readonly property int actionWidth: 32
    readonly property real numberWidth: trackNumberSlot.width
    readonly property int durationWidth: 38

    Row {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 5

        Item {
            id: trackNumberSlot
            width: trackNumberMorph.geometryWidth
            height: parent.height

            Primitives.MorphGeometry {
                id: trackNumberMorph
                fromGeometry: Qt.rect(0, 0, 0, parent.height)
                toGeometry: Qt.rect(0, 0, 18, parent.height)
                progress: Config.mopidyShowTrackNumbers ? 1 : 0
                visible: Config.mopidyShowTrackNumbers || normalizedProgress > 0.001
                animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")
                animationProfile: Config.animationMopidyMorphProfile
                animationPhase: Config.mopidyShowTrackNumbers ? "enter" : "exit"

                Text {
                    width: 18
                    height: parent.height
                    opacity: trackNumberMorph.normalizedProgress
                    transform: Scale {
                        xScale: trackNumberMorph.normalizedProgress
                        yScale: 1
                        origin.x: 0
                        origin.y: trackNumberMorph.geometryHeight / 2
                    }
                    text: Number(itemData.track.tlid) === controller.currentTlid ? "▶" : String(itemData.queueIndex + 1)
                    color: Number(itemData.track.tlid) === controller.currentTlid ? Config.accent : controller.hoverTextColor(rowMouse.containsMouse, Config.textMuted)
                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Item {
            id: trackTextArea
            width: parent.width - trackRow.numberWidth - trackRow.durationWidth - trackRow.actionWidth - 15
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: artistLineMorph.normalizedProgress * 2
            readonly property bool oneLineModeSettled: Config.mopidyTrackArtistDisplayMode === "one-line"
                && artistLineMorph.normalizedProgress <= 0.001

            Text {
                id: trackTitleText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.max(1, artistLineMorph.geometryY
                    - artistLineMorph.artistGap * artistLineMorph.normalizedProgress)
                text: {
                    var trackName = itemData.track.name || "Без названия"
                    var artistName = itemData.track.artist || ""
                    return trackTextArea.oneLineModeSettled
                        ? controller.formatOneLineTrack(artistName, trackName)
                        : trackName
                }
                textFormat: trackTextArea.oneLineModeSettled ? Text.StyledText : Text.PlainText
                color: Number(itemData.track.tlid) === controller.currentTlid ? Config.accent : controller.hoverTextColor(rowMouse.containsMouse, Config.text)
                font.family: Config.mopidyTrackFont
                font.pixelSize: Config.mopidyTrackFontSize
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Primitives.MorphGeometry {
                id: artistLineMorph
                width: parent.width
                clip: true
                visible: (Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist)
                    || normalizedProgress > 0.001
                fromGeometry: Qt.rect(0, parent.height, parent.width, 0)
                readonly property real artistGap: Math.max(0, Math.min(8, Number(Config.mopidyTrackArtistGap) || 0))
                readonly property real baseSplitY: Math.round(parent.height * 0.57)
                readonly property real gapHalf: artistGap / 2
                toGeometry: Qt.rect(0, baseSplitY + Math.ceil(gapHalf), parent.width,
                    Math.max(0, parent.height - baseSplitY - Math.ceil(gapHalf)))
                progress: Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist ? 1 : 0
                animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")
                animationProfile: Config.animationMopidyMorphProfile
                animationPhase: Config.mopidyTrackArtistDisplayMode === "two-lines" && !!itemData.track.artist ? "enter" : "exit"

                Text {
                    id: trackArtistText
                    anchors.fill: parent
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

    Primitives.DragReorderHandle {
        id: queueReorderHandle
        visible: controller.tracks.length > 1
        z: 4
        width: 26
        height: 26
        x: trackRow.width - trackRow.durationWidth - 31
        y: Math.round((trackRow.height - height) / 2)
        reorderAdapter: controller.queueReorderAdapter
        itemIndex: Number(itemData.queueIndex)
        dropIndicatorHost: controller.queueReorderHost
        interactionEnabled: controller.queueReorderEnabled
            && (!controller.queueReorderDragging || controller.queueActiveDragHandle === queueReorderHandle)
        accessibleLabel: itemData.track.name || "трек в очереди"
        onDraggingChanged: controller.setQueueReorderDragging(dragging, queueReorderHandle)
        onDragPositionChanged: function(sceneX, sceneY) { controller.updateQueueDragPosition(sceneX, sceneY) }
        onReorderRequested: function(fromIndex, toIndex) {
            controller.moveTrack(Number(itemData.track.tlid), toIndex)
        }
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
