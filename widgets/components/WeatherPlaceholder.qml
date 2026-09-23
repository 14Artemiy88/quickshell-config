import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: root
    anchors.fill: parent
    property string message: "Погода недоступна"
    property var weatherService: null
    property bool retryLocked: !!(weatherService && weatherService.manualRefreshCoolingDown)

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

        Button {
            id: refreshButton
            anchors.horizontalCenter: parent.horizontalCenter
            enabled: root.weatherService !== null && !root.retryLocked
            text: root.retryLocked ? ("↻  Подожди " + weatherService.manualCooldownRemaining + "с") : "↻  Обновить"
            font.family: Config.font
            font.pixelSize: Config.uiFontSize(11)
            contentItem: Text {
                text: refreshButton.text
                color: refreshButton.enabled ? Config.text : Config.textDisabled
                font.family: Config.font
                font.pixelSize: Config.uiFontSize(11)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: refreshButton.enabled ? Config.background : Config.playerOverlay
                border.color: Config.baseColor
                border.width: 1
                radius: Config.radius
            }
            onClicked: {
                if (root.weatherService)
                    root.weatherService.manualRefresh()
            }
        }
    }
}
