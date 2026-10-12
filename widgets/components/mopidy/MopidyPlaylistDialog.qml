import QtQuick
import QtQuick.Controls
import "../.."
import "../primitives" as Primitives

Rectangle {
    id: playlistDialogOverlay
    property var controller
    z: 200
    anchors.fill: parent
    visible: controller.playlistDialogVisible
    color: "#88000000"

    onVisibleChanged: {
        if (!visible || controller.playlistDialogMode === "delete") return
        Qt.callLater(function() {
            if (!playlistDialogOverlay.visible) return
            playlistDialogField.forceActiveFocus()
            if (controller.playlistDialogMode === "rename")
                playlistDialogField.selectAll()
        })
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    Rectangle {
        width: Math.min(parent.width - 20, 280)
        height: controller.playlistDialogMode === "delete" ? 88 : 104
        anchors.centerIn: parent
        radius: 5
        color: Config.settingsBackground
        border.width: 1
        border.color: Config.baseColor

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 7

            Text {
                width: parent.width
                height: 18
                text: controller.playlistDialogMode === "create" ? "Новый плейлист" : (controller.playlistDialogMode === "rename" ? "Переименовать плейлист" : "Удалить плейлист")
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                font.bold: true
                elide: Text.ElideRight
            }

            TextField {
                id: playlistDialogField
                width: parent.width
                height: 30
                visible: controller.playlistDialogMode !== "delete"
                text: controller.playlistDialogInput
                color: Config.text
                placeholderText: "Название"
                placeholderTextColor: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                selectByMouse: true
                onTextChanged: controller.playlistDialogInput = text
                onAccepted: controller.submitPlaylistDialog()
                background: Rectangle {
                    color: Config.settingsBackground
                    border.color: playlistDialogField.activeFocus ? Config.accent : Config.baseColor
                    border.width: 1
                    radius: 4
                }
                Keys.onEscapePressed: controller.closePlaylistDialog()
            }

            Text {
                width: parent.width
                height: 26
                visible: controller.playlistDialogMode === "delete"
                text: "Удалить «" + controller.playlistManageTitle + "»?"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                width: parent.width
                height: 16
                visible: !!controller.playlistDialogError
                text: controller.playlistDialogError
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
                elide: Text.ElideRight
            }

            Row {
                width: parent.width
                height: 28
                spacing: 6

                Item { width: Math.max(0, parent.width - 118); height: 1 }

                Primitives.StyledTextButton {
                    width: 56
                    height: 28
                    text: "Отмена"
                    textColor: Config.text
                    textFontFamily: Config.settingsFont
                    textFontPixelSize: Config.settingsUiSize(9)
                    normalBackground: Config.settingsBackground
                    pressedBackground: hovered && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : Config.settingsBackground
                    outlineColor: Config.baseColor
                    hoverMode: Config.mopidyHoverMode
                    hoverColor: Config.mopidyHoverColor
                    cornerRadius: 4
                    onClicked: controller.closePlaylistDialog()
                }

                Primitives.StyledTextButton {
                    width: 56
                    height: 28
                    text: controller.playlistDialogMode === "create" ? "Создать" : (controller.playlistDialogMode === "rename" ? "Сохранить" : "Удалить")
                    textColor: Config.text
                    textFontFamily: Config.settingsFont
                    textFontPixelSize: Config.settingsUiSize(9)
                    normalBackground: Config.settingsBackground
                    pressedBackground: hovered && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : Config.settingsBackground
                    outlineColor: Config.accent
                    hoverMode: Config.mopidyHoverMode
                    hoverColor: Config.mopidyHoverColor
                    cornerRadius: 4
                    enabled: !controller.playlistManageBusy
                    onClicked: controller.submitPlaylistDialog()
                }
            }
        }
    }
}
