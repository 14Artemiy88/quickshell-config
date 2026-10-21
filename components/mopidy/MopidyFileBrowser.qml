import QtQuick
import QtQuick.Controls
import "../.."

Item {
    id: fileBrowser
    property var controller

    function focusPanel() {
        if (visible) forceActiveFocus()
    }

    function focusFilter() {
        if (fileFilterField && controller.fileFilterOpen) {
            fileFilterField.text = ""
            fileFilterField.forceActiveFocus()
        }
    }

    function clearFilterField() {
        if (fileFilterField) fileFilterField.text = ""
    }

    width: parent.width
    height: Math.max(0, parent.height - 35)
    visible: controller.libraryMode === "browse"
    focus: visible && !controller.fileFilterOpen

    Keys.onPressed: function(event) {
        if (controller.searchOpen && controller.libraryMode === "browse" && !controller.fileFilterOpen && event.text === "/" && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            controller.openFileFilter()
            event.accepted = true
        }
    }

    onVisibleChanged: {
        if (visible && controller.searchOpen && controller.libraryMode === "browse")
            Qt.callLater(function() { if (fileBrowser.visible && !controller.fileFilterOpen) fileBrowser.forceActiveFocus() })
    }

    Column {
        anchors.fill: parent
        spacing: 4

        Text {
            width: parent.width
            height: 22
            text: controller.browseBusy ? "Загрузка…" : controller.browseTitle
            color: Config.accent
            font.family: Config.mopidyAlbumFont
            font.pixelSize: Config.mopidyAlbumFontSize
            font.bold: Config.mopidyAlbumBold
            elide: Text.ElideRight
        }

        Row {
            width: parent.width
            height: 27
            spacing: 5
            visible: controller.fileFilterOpen

            Text {
                width: 16
                height: parent.height
                text: "/"
                color: Config.accent
                font.family: Config.font
                font.pixelSize: Config.fontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            TextField {
                id: fileFilterField
                width: Math.max(0, parent.width - 21)
                height: parent.height
                text: controller.fileFilterQuery
                placeholderText: "Фильтр файлов…"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
                selectByMouse: true
                leftPadding: 6
                rightPadding: 6
                topPadding: 2
                bottomPadding: 2
                background: Rectangle {
                    color: Config.settingsBackground
                    radius: 4
                    border.width: 1
                    border.color: fileFilterField.activeFocus ? Config.accent : Config.baseColor
                }
                onTextChanged: controller.fileFilterQuery = text
                Keys.onEscapePressed: {
                    controller.closeFileFilter(true)
                }
                Keys.onReturnPressed: {
                    controller.closeFileFilter(false)
                }
                Keys.onEnterPressed: {
                    controller.closeFileFilter(false)
                }
            }
        }

        ListView {
            id: browseListView
            width: parent.width
            height: Math.max(0, parent.height - (controller.fileFilterOpen ? 57 : 26))
            clip: true
            spacing: 2
            model: controller.filteredBrowseDisplayEntries
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                width: parent ? parent.width : 0
                height: Config.mopidyTrackRowHeight
                radius: 4
                property bool addButtonVisible: Config.mopidyShowAddIcon && (modelData.type === "directory" || modelData.type === "track")
                property bool rowHovered: browseMouse.containsMouse
                color: Config.transparent

                Rectangle {
                    id: browseHoverFrame
                    x: addButtonVisible ? 33 : 0
                    y: 0
                    width: Math.max(0, parent.width - x)
                    height: parent.height
                    radius: 4
                    color: rowHovered && modelData.type !== "parent" ? controller.hoverBackgroundColor(true) : Config.transparent
                    border.width: rowHovered && modelData.type !== "parent" ? controller.hoverBorderWidth(true) : 0
                    border.color: controller.hoverBorderColor(rowHovered && modelData.type !== "parent")
                    z: 0
                }

                Text {
                    id: browseIcon
                    z: 1
                    x: 34
                    width: 28
                    height: parent.height
                    text: modelData.type === "parent" ? "" : (modelData.type === "directory" ? "" : "")
                    color: controller.hoverTextColor(rowHovered && modelData.type !== "parent", modelData.type === "parent" || modelData.type === "directory" ? Config.accent : Config.textMuted)
                    font.family: Config.font
                    font.pixelSize: Config.fontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    x: modelData.type === "parent" ? 66 : (addButtonVisible ? 66 : 38)
                    z: 1
                    width: Math.max(0, parent.width - x - 5)
                    height: parent.height
                    text: modelData.name || "Без названия"
                    color: controller.hoverTextColor(rowHovered && modelData.type !== "parent", Config.text)
                    font.family: modelData.type === "parent" || modelData.type === "directory" ? Config.mopidyAlbumFont : Config.mopidyTrackFont
                    font.pixelSize: modelData.type === "parent" || modelData.type === "directory" ? Config.mopidyAlbumFontSize : Config.mopidyTrackFontSize
                    font.bold: false
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    id: browseAddButton
                    z: 2
                    visible: addButtonVisible
                    x: 1
                    y: 1
                    width: 30
                    height: parent.height - 2
                    radius: 3
                    color: controller.hoverBackgroundColor(browseAddMouse.containsMouse)
                    border.width: controller.hoverBorderWidth(browseAddMouse.containsMouse)
                    border.color: controller.hoverBorderColor(browseAddMouse.containsMouse)

                    Text {
                        x: (parent.width - width) / 2 + Config.mopidyAddIconX
                        y: (parent.height - height) / 2 + Config.mopidyAddIconY
                        width: Math.max(1, implicitWidth)
                        height: Math.max(1, implicitHeight)
                        text: Config.mopidyAddIcon
                        color: controller.hoverTextColor(browseAddMouse.containsMouse, Config.mopidyControlIconColor)
                        font.family: Config.font
                        font.pixelSize: Config.mopidyAddIconSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: browseAddMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.type === "directory")
                                controller.addBrowseFolder(modelData.uri, modelData.name)
                            else if (modelData.type === "track")
                                controller.addSearchResult(modelData.uri, modelData.name)
                        }
                    }
                }

                MouseArea {
                    id: browseMouse
                    x: addButtonVisible ? 33 : 0
                    hoverEnabled: true
                    y: 0
                    width: Math.max(0, parent.width - x)
                    height: parent.height
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onPressed: fileBrowser.forceActiveFocus()
                    onClicked: function(mouse) {
                        if (modelData.type === "parent") {
                            if (mouse.button === Qt.LeftButton)
                                controller.browseBack()
                            return
                        }
                        if (modelData.type === "directory") {
                            if (mouse.button === Qt.LeftButton)
                                controller.browseUriAt(modelData.uri, modelData.name)
                            else if (mouse.button === Qt.RightButton)
                                controller.addBrowseFolder(modelData.uri, modelData.name)
                            return
                        }
                        if (modelData.type === "track" && (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton))
                            controller.addSearchResult(modelData.uri, modelData.name)
                    }
                }
            }
        }
    }

}