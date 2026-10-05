import QtQuick
import QtQuick.Controls
import "../../.."

ComboBox {
    id: root

    property bool pointerHovered: comboHoverArea.containsMouse
    signal itemChosen(int index)

    MouseArea {
        id: comboHoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    background: Rectangle {
        color: Config.settingsBackground
        border.color: (root.activeFocus || root.pointerHovered) ? Config.accent : Config.baseColor
        border.width: 1
        radius: Config.frameRadius
    }

    popup: Popup {
        id: comboPopup
        y: parent.height
        width: parent.width
        padding: 2
        implicitHeight: popupList.contentHeight + padding * 2

        background: Rectangle {
            color: Config.settingsBackground
            border.color: Config.baseColor
            border.width: 1
            radius: Config.frameRadius
        }

        contentItem: ListView {
            id: popupList
            property var comboBoxControl: root
            width: comboPopup.width - comboPopup.leftPadding - comboPopup.rightPadding
            implicitHeight: contentHeight
            clip: true
            model: comboPopup.visible ? comboBoxControl.model : null

            delegate: ItemDelegate {
                id: comboDelegate
                width: popupList.width
                height: 30
                text: ListView.view.comboBoxControl.textAt(index)
                highlighted: ListView.view.comboBoxControl.currentIndex === index

                contentItem: Text {
                    text: comboDelegate.text
                    color: comboDelegate.hovered || comboDelegate.highlighted ? Config.black : Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    color: comboDelegate.hovered || comboDelegate.highlighted ? Config.accent : Config.settingsBackground
                    radius: 2
                }

                onClicked: {
                    ListView.view.comboBoxControl.currentIndex = index
                    ListView.view.comboBoxControl.itemChosen(index)
                    ListView.view.comboBoxControl.popup.close()
                }
            }
        }
    }
}
