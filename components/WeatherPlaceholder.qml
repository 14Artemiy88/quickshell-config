import QtQuick
import "primitives" as Primitives
import ".."

Item {
    id: root
    anchors.fill: parent
    property string message: "Погода недоступна"
    property var weatherService: null
    property bool active: true
    property bool retryLocked: !!(weatherService && weatherService.manualRefreshCoolingDown)
    property bool tokenMissing: !String(Settings.weatherToken || "").trim()
    signal settingsRequested()

    // Keep the placeholder alive through its exit transition. Its parent remains
    // fixed-size, so only the centered content scales; no forecast geometry moves.
    visible: active || placeholderMorph.normalizedProgress > 0.001

    Primitives.MorphGeometry {
        id: placeholderMorph
        fromGeometry: Qt.rect(0, 0, root.width, root.height)
        toGeometry: Qt.rect(0, 0, root.width, root.height)
        progress: root.active ? 1 : 0
        animationDuration: Config.animationDurationForProfile(Config.animationWeatherMorphEnabled, Config.animationWeatherMorphProfile, Config.animationWeatherMorphDuration, "appearance")
        animationProfile: Config.animationWeatherMorphProfile
        animationPhase: root.active ? "enter" : "exit"

        Item {
            anchors.fill: parent
            opacity: placeholderMorph.normalizedProgress
            scale: 0.97 + 0.03 * placeholderMorph.normalizedProgress
            transformOrigin: Item.Center

            Column {
                anchors.centerIn: parent
                width: Math.min(parent.width - 20, 280)
                spacing: 8

                Text {
                    width: parent.width
                    text: root.message
                    color: Config.textMuted
                    font.family: Config.font
                    font.pixelSize: Config.uiFontSize(12)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Primitives.StyledTextButton {
                    id: refreshButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    enabled: root.tokenMissing || (root.weatherService !== null && !root.retryLocked)
                    text: root.tokenMissing ? "⚙  Настроить погоду" : (root.retryLocked ? ("↻  Подожди " + (root.weatherService ? root.weatherService.manualCooldownRemaining : 0) + "с") : "↻  Обновить")
                    textFontFamily: Config.font
                    textFontPixelSize: Config.uiFontSize(11)
                    textColor: enabled ? Config.text : Config.textDisabled
                    normalBackground: enabled ? Config.background : Config.playerOverlay
                    pressedBackground: Config.baseColor
                    outlineColor: Config.baseColor
                    cornerRadius: Config.radius
                    onClicked: {
                        if (root.tokenMissing) {
                            root.settingsRequested()
                        } else if (root.weatherService) {
                            root.weatherService.manualRefresh()
                        }
                    }
                }
            }
        }
    }
}
