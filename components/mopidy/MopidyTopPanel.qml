import QtQuick
import QtQuick.Controls
import "." as Widgets
import "../.."
import "../primitives" as Primitives
import "../../js/mopidy/QueueDurationGeometry.js" as QueueDurationGeometry

Item {
    id: topPanelWrapper
    property var controller
    width: parent.width
    // Keep the layout height at the hidden hotspot height so the
    // expanding icon row overlays the content instead of pushing it.
    height: Config.mopidyHideTopPanel ? Config.mopidyTopPanelOffsetY : (24 + Config.mopidyTopPanelOffsetY)
    z: 100
    clip: false

    readonly property bool topPanelHoverOpen: controller.externalTopPanelHover
    readonly property bool topPanelRevealed: !Config.mopidyHideTopPanel || controller.externalTopPanelHover

    Primitives.MorphGeometry {
        id: topPanelRevealMorph
        x: 0
        y: 0
        width: parent.width
        clip: true
        visible: topPanelWrapper.topPanelRevealed || normalizedProgress > 0.001
        fromGeometry: Qt.rect(0, 0, parent.width, 0)
        toGeometry: Qt.rect(0, 0, parent.width, 24)
        progress: topPanelWrapper.topPanelRevealed ? 1 : 0
        animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled && Config.mopidyHideTopPanel, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")
        animationProfile: Config.animationMopidyMorphProfile
        animationPhase: topPanelWrapper.topPanelRevealed ? "enter" : "exit"

        Rectangle {
            id: topPanelBackground
            x: 0
            y: 0
            width: parent.width
            height: 24
            visible: Config.mopidyHideTopPanel && (topPanelWrapper.topPanelRevealed || topPanelRevealMorph.normalizedProgress > 0.001)
            color: Config.mopidyTopPanelBackground
            z: 0
        }

        Item {
            id: topPanelRow
            width: parent.width
            height: 24

            readonly property var normalizedTopIconOrder: controller.normalizedTopIconOrder()

            function iconIsVisible(id) {
                if (id === "stop") return Config.mopidyShowStopIcon && controller.queueAvailable && controller.tracks.length > 0
                if (id === "shuffle") return Config.mopidyShowShuffleIcon && controller.queueAvailable && controller.tracks.length > 0
                if (id === "repeat") return Config.mopidyShowRepeatIcon && controller.queueAvailable && controller.tracks.length > 0
                if (id === "volume") return Config.mopidyShowVolumeIcon && controller.queueAvailable && controller.tracks.length > 0
                if (id === "refresh") return Config.mopidyShowRefreshIcon && controller.queueAvailable && controller.tracks.length > 0
                if (id === "openAdd") return Config.mopidyShowOpenAddIcon && controller.queueAvailable
                if (id === "clear") return Config.mopidyShowClearIcon && controller.queueAvailable && controller.tracks.length > 0
                return false
            }

            function iconWidthFor(id) {
                // The volume slot reports its interpolated width so the right-aligned
                // control row redistributes space continuously while the percentage
                // label expands or collapses.
                return id === "volume" ? volumeControl.geometryWidth : 22
            }

            // Compute the volume slot's two endpoint positions from fixed widths.
            // Do not use volumeControl.geometryWidth here: MorphGeometry derives that
            // width from fromGeometry/toGeometry, so feeding it back into either
            // endpoint would create a QML binding loop.
            function volumeXForWidth(volumeWidth) {
                var totalWidth = 0
                var count = 0
                for (var i = 0; i < normalizedTopIconOrder.length; ++i) {
                    var id = normalizedTopIconOrder[i]
                    if (!iconIsVisible(id)) continue
                    totalWidth += id === "volume" ? volumeWidth : 22
                    count += 1
                }

                var x = parent.width - totalWidth - Math.max(0, count - 1) * 6
                var gapCount = 0
                for (var j = 0; j < normalizedTopIconOrder.length; ++j) {
                    var current = normalizedTopIconOrder[j]
                    if (!iconIsVisible(current)) continue
                    if (current === "volume") return x + gapCount * 6
                    x += current === "volume" ? volumeWidth : 22
                    gapCount += 1
                }
                return parent.width
            }

            readonly property real volumeCollapsedX: volumeXForWidth(22)
            readonly property real volumeExpandedX: volumeXForWidth(58)

            readonly property bool queueDurationTargetVisible: Config.mopidyShowQueueTotalDuration
                && controller.queueAvailable && controller.tracks.length > 0
            // The queue-duration slot stays 6px to the left of the icon row. Its
            // right edge follows the row while the volume percentage changes width.
            readonly property real queueDurationRightEdge: topIconStartX - (totalIconWidth() > 0 ? 6 : 0)

            function totalIconWidth() {
                var width = 0
                var count = 0
                for (var i = 0; i < normalizedTopIconOrder.length; ++i) {
                    var id = normalizedTopIconOrder[i]
                    if (!iconIsVisible(id)) continue
                    width += iconWidthFor(id)
                    count += 1
                }
                return width + Math.max(0, count - 1) * 6
            }

            function iconXFor(id) {
                var x = parent.width - totalIconWidth()
                var gapCount = 0
                for (var i = 0; i < normalizedTopIconOrder.length; ++i) {
                    var current = normalizedTopIconOrder[i]
                    if (!iconIsVisible(current)) continue
                    if (current === id) return x + gapCount * 6
                    x += iconWidthFor(current)
                    gapCount += 1
                }
                return x
            }

            readonly property real topIconStartX: parent.width - totalIconWidth()

            // Keep one fixed-width slot, but anchor it to the selected edge:
            // left alignment starts at the panel's true left edge; right alignment
            // remains immediately before the icon cluster. X is an inset from that
            // anchor, so no large negative coordinate is needed for left alignment.
            Item {
                id: queueDurationSlot
                x: QueueDurationGeometry.slotX(Config.mopidyQueueDurationAlignment,
                                               Config.mopidyQueueDurationX,
                                               topPanelRow.queueDurationRightEdge, width)
                width: 60
                height: parent.height
                visible: topPanelRow.queueDurationTargetVisible || queueDurationMorph.normalizedProgress > 0.001

                Primitives.MorphGeometry {
                    id: queueDurationMorph
                    fromGeometry: Config.mopidyQueueDurationAlignment === "left"
                        ? Qt.rect(-4, 0, 56, parent.height)
                        : Qt.rect(4, 0, 56, parent.height)
                    toGeometry: Qt.rect(0, 0, 60, parent.height)
                    progress: topPanelRow.queueDurationTargetVisible ? 1 : 0
                    visible: topPanelRow.queueDurationTargetVisible || normalizedProgress > 0.001
                    clip: false
                    animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")
                    animationProfile: Config.animationMopidyMorphProfile
                    animationPhase: topPanelRow.queueDurationTargetVisible ? "enter" : "exit"

                    Text {
                        id: queueDurationText
                        width: 60
                        height: parent.height
                        x: 0
                        y: Config.mopidyQueueDurationY
                        scale: 0.96 + 0.04 * queueDurationMorph.normalizedProgress
                        transformOrigin: Config.mopidyQueueDurationAlignment === "left" ? Item.Left : Item.Right
                        text: Config.mopidyQueueDurationMode === "remaining" ? controller.formatDuration(controller.queueRemainingDuration, true) : controller.formatDuration(controller.queueTotalDuration, false)
                        color: Config.mopidyQueueDurationColor
                        font.family: Config.mopidyQueueDurationFont
                        font.pixelSize: Config.mopidyQueueDurationFontSize
                        horizontalAlignment: Config.mopidyQueueDurationAlignment === "left" ? Text.AlignLeft : Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideNone
                    }
                }
            }

            Widgets.MopidyHoverIcon {
                x: topPanelRow.iconXFor("stop")
                width: 22; height: parent.height
                iconText: Config.mopidyStopIcon; iconSize: Config.mopidyStopIconSize; iconX: Config.mopidyStopIconX; iconY: Config.mopidyStopIconY
                visible: Config.mopidyShowStopIcon && controller.queueAvailable && controller.tracks.length > 0
                baseColor: controller.queueAvailable && !controller.queueBusy ? Config.mopidyControlIconColor : Config.textDisabled
                enabledState: controller.queueAvailable && !controller.queueBusy
                onClicked: controller.stopPlayback()
            }

            Widgets.MopidyHoverIcon {
                x: topPanelRow.iconXFor("shuffle")
                width: 22; height: parent.height
                iconText: Config.mopidyShuffleIcon; iconSize: Config.mopidyShuffleIconSize; iconX: Config.mopidyShuffleIconX; iconY: Config.mopidyShuffleIconY
                visible: Config.mopidyShowShuffleIcon && controller.queueAvailable && controller.tracks.length > 0
                baseColor: controller.mopidyRandom && controller.playbackPrefsAvailable ? Config.accent : (controller.playbackPrefsAvailable ? Config.mopidyControlIconColor : Config.textDisabled)
                enabledState: controller.playbackPrefsAvailable
                onClicked: controller.toggleRandom()
            }

            Widgets.MopidyHoverIcon {
                id: repeatIconButton
                x: topPanelRow.iconXFor("repeat")
                width: 22; height: parent.height
                iconText: Config.mopidyRepeatIcon; iconSize: Config.mopidyRepeatIconSize; iconX: Config.mopidyRepeatIconX; iconY: Config.mopidyRepeatIconY
                visible: Config.mopidyShowRepeatIcon && controller.queueAvailable && controller.tracks.length > 0
                baseColor: controller.mopidyRepeat && controller.playbackPrefsAvailable ? Config.accent : (controller.playbackPrefsAvailable ? Config.mopidyControlIconColor : Config.textDisabled)
                enabledState: controller.playbackPrefsAvailable
                toolTipText: controller.mopidySingle ? "Повтор одного" : (controller.mopidyRepeat ? "Повтор всех" : "Повтор выключен")
                onClicked: controller.cycleRepeat()
            }

            Primitives.MorphGeometry {
                id: volumeControl
                fromGeometry: Qt.rect(topPanelRow.volumeCollapsedX, 0, 22, parent.height)
                toGeometry: Qt.rect(topPanelRow.volumeExpandedX, 0, 58, parent.height)
                progress: Config.mopidyShowVolumePercent ? 1 : 0
                visible: Config.mopidyShowVolumeIcon && controller.queueAvailable && controller.tracks.length > 0
                clip: true
                animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")
                animationProfile: Config.animationMopidyMorphProfile
                animationPhase: Config.mopidyShowVolumePercent ? "enter" : "exit"

                Rectangle {
                    anchors.fill: parent
                    z: 0
                    radius: 4
                    color: volumeControlMouse.containsMouse && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : Config.transparent
                    border.width: volumeControlMouse.containsMouse && Config.mopidyHoverMode === "frame" ? 1 : 0
                    border.color: Config.mopidyHoverColor
                }

                Text {
                    id: volumeIconText
                    z: 1
                    width: 22
                    height: parent.height
                    text: controller.mopidyMuted ? Config.mopidyMutedIcon : Config.mopidyVolumeIcon
                    color: controller.hoverTextColor(volumeControlMouse.containsMouse, controller.mixerAvailable ? Config.mopidyControlIconColor : Config.textDisabled)
                    font.family: Config.font
                    font.pixelSize: controller.mopidyMuted ? Config.mopidyMutedIconSize : Config.mopidyVolumeIconSize
                    y: controller.mopidyMuted ? Config.mopidyMutedIconY : Config.mopidyVolumeIconY
                    transform: Translate { x: controller.mopidyMuted ? Config.mopidyMutedIconX : Config.mopidyVolumeIconX }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    visible: Config.mopidyShowVolumePercent || volumeControl.normalizedProgress > 0.001
                    anchors.left: volumeIconText.right
                    anchors.leftMargin: 2
                    width: 32
                    height: parent.height
                    text: controller.mopidyMuted && controller.mopidyRestoreVolume > 0
                        ? String(controller.mopidyRestoreVolume) + "%"
                        : (controller.mopidyVolume >= 0 ? String(controller.mopidyVolume) + "%" : "--")
                    color: controller.hoverTextColor(volumeControlMouse.containsMouse, controller.mixerAvailable ? Config.mopidyControlIconColor : Config.textDisabled)
                    font.family: Config.mopidyDurationFont
                    font.pixelSize: Config.mopidyDurationFontSize
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: volumeControlMouse
                    anchors.fill: parent
                    enabled: controller.mixerAvailable && !controller.queueBusy && !controller.mixerSoftMuteMigrationPending
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    hoverEnabled: true
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton)
                            controller.toggleMixerMute()
                    }
                    onWheel: function(wheel) {
                        var step = Math.max(1, Number(Config.mopidyVolumeStep))
                        controller.adjustMixerVolume(wheel.angleDelta.y > 0 ? step : -step)
                    }
                }
            }

            Widgets.MopidyHoverIcon {
                x: topPanelRow.iconXFor("refresh")
                width: 22; height: parent.height
                iconText: Config.mopidyRefreshIcon; iconSize: Config.mopidyRefreshIconSize; iconX: Config.mopidyRefreshIconX; iconY: Config.mopidyRefreshIconY
                visible: Config.mopidyShowRefreshIcon && controller.queueAvailable && controller.tracks.length > 0
                baseColor: Config.mopidyControlIconColor
                enabledState: controller.queueAvailable && !controller.queueBusy
                onClicked: controller.refreshQueue()
            }

            Widgets.MopidyHoverIcon {
                x: topPanelRow.iconXFor("openAdd")
                width: 22; height: parent.height
                iconText: Config.mopidyOpenAddIcon; iconSize: Config.mopidyOpenAddIconSize; iconX: Config.mopidyOpenAddIconX; iconY: Config.mopidyOpenAddIconY
                visible: Config.mopidyShowOpenAddIcon && controller.queueAvailable
                baseColor: controller.searchOpen ? Config.accent : Config.mopidyControlIconColor
                enabledState: controller.queueAvailable && !controller.queueBusy
                onClicked: controller.toggleSearch()
            }

            Widgets.MopidyHoverIcon {
                x: topPanelRow.iconXFor("clear")
                width: 22; height: parent.height
                iconText: Config.mopidyClearIcon; iconSize: Config.mopidyClearIconSize; iconX: Config.mopidyClearIconX; iconY: Config.mopidyClearIconY
                visible: Config.mopidyShowClearIcon && controller.queueAvailable && controller.tracks.length > 0
                baseColor: controller.tracks.length && !controller.queueBusy ? Config.mopidyControlIconColor : Config.textDisabled
                enabledState: controller.tracks.length > 0 && !controller.queueBusy
                onClicked: controller.clearQueue()
            }
        }
    }
}
