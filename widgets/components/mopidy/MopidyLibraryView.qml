import QtQuick
import QtQuick.Controls
import "." as MopidyWidgets
import "../primitives" as Primitives
import "../.."

Column {
    id: libraryRoot
    property var controller

    function focusBrowsePanel() { if (fileBrowser) fileBrowser.focusPanel() }
    function focusFileFilter() { if (fileBrowser) fileBrowser.focusFilter() }
    function clearFileFilterField() { if (fileBrowser) fileBrowser.clearFilterField() }
    function focusSearchField() { if (searchField) searchField.forceActiveFocus() }

    anchors.fill: parent
    spacing: 5
    visible: controller.searchOpen

    Row {
        width: parent.width
        height: 30
        spacing: 5

        Primitives.StyledTextButton {
            width: 72
            height: 30
            text: "Папки"
            textColor: Config.text
            textFontFamily: Config.settingsFont
            textFontPixelSize: Config.settingsUiSize(10)
            normalBackground: controller.libraryMode === "browse" ? Config.activeNetworkBackground : Config.settingsBackground
            pressedBackground: hovered && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : normalBackground
            outlineColor: controller.libraryMode === "browse" ? Config.accent : Config.baseColor
            hoverMode: Config.mopidyHoverMode
            hoverColor: Config.mopidyHoverColor
            cornerRadius: 4
            enabled: !controller.browseBusy
            onClicked: controller.showBrowse()
        }

        Primitives.StyledTextButton {
            width: 82
            height: 30
            text: "Плейлисты"
            textColor: Config.text
            textFontFamily: Config.settingsFont
            textFontPixelSize: Config.settingsUiSize(10)
            normalBackground: (controller.libraryMode === "playlists" || controller.libraryMode === "playlistItems") ? Config.activeNetworkBackground : Config.settingsBackground
            pressedBackground: hovered && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : normalBackground
            outlineColor: (controller.libraryMode === "playlists" || controller.libraryMode === "playlistItems") ? Config.accent : Config.baseColor
            hoverMode: Config.mopidyHoverMode
            hoverColor: Config.mopidyHoverColor
            cornerRadius: 4
            enabled: !controller.playlistsBusy
            onClicked: controller.showPlaylists()
        }

        Primitives.StyledTextButton {
            width: 72
            height: 30
            text: "Поиск"
            textColor: Config.text
            textFontFamily: Config.settingsFont
            textFontPixelSize: Config.settingsUiSize(10)
            normalBackground: controller.libraryMode === "search" ? Config.activeNetworkBackground : Config.settingsBackground
            pressedBackground: hovered && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : normalBackground
            outlineColor: controller.libraryMode === "search" ? Config.accent : Config.baseColor
            hoverMode: Config.mopidyHoverMode
            hoverColor: Config.mopidyHoverColor
            cornerRadius: 4
            enabled: true
            onClicked: controller.showSearch()
        }

        Item { width: Math.max(0, parent.width - 236); height: 1 }

        MopidyWidgets.MopidyHoverIcon {
            width: 32
            height: 30
            visible: (controller.libraryMode === "browse" && controller.browseStack.length > 0) || (controller.libraryMode === "playlistItems")
            iconText: "‹"
            iconSize: 22
            baseColor: (controller.browseBusy || controller.playlistsBusy) ? Config.textDisabled : Config.mopidyControlIconColor
            enabledState: !controller.browseBusy && !controller.playlistsBusy
            onClicked: controller.libraryMode === "playlistItems" ? controller.backToPlaylists() : controller.browseBack()
        }
    }

    MopidyWidgets.MopidyFileBrowser {
        id: fileBrowser
        width: parent.width
        height: Math.max(0, parent.height - 35)
        visible: libraryRoot.controller.libraryMode === "browse"
        controller: libraryRoot.controller
    }

    Text {
        width: parent.width
        height: parent.height
        visible: controller.libraryMode === "browse" && !controller.browseBusy && controller.browseEntries.length === 0 && !controller.fileFilterQuery.trim()
        text: "Папка пуста"
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        width: parent.width
        height: parent.height
        visible: controller.libraryMode === "browse" && !controller.browseBusy && controller.fileFilterQuery.trim().length > 0 && controller.filteredBrowseDisplayEntries.length === 0
        text: "Совпадений нет"
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Column {
        width: parent.width
        height: Math.max(0, parent.height - 35)
        spacing: 5
        visible: controller.libraryMode === "playlists"

        Row {
            width: parent.width
            height: 22
            spacing: 4

            Text {
                width: Math.max(0, parent.width - 28)
                height: parent.height
                text: controller.playlistsBusy ? "Загрузка…" : "Плейлисты"
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
                iconText: "+"
                iconSize: Config.mopidyAddIconSize
                baseColor: Config.mopidyControlIconColor
                enabledState: !controller.playlistsBusy
                onClicked: controller.openCreatePlaylistDialog()
            }
        }

        ListView {
            width: parent.width
            height: Math.max(0, parent.height - 26)
            clip: true
            spacing: 2
            model: controller.playlists
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                width: parent ? parent.width : 0
                height: Config.mopidyTrackRowHeight
                radius: 4
                property bool addButtonVisible: Config.mopidyShowAddIcon
                property bool switchButtonVisible: Config.mopidyShowSwitchPlaylistIcon
                property int leftButtonCount: (addButtonVisible ? 1 : 0) + (switchButtonVisible ? 1 : 0)
                property int leftButtonsWidth: leftButtonCount * 33
                color: Config.transparent

                Rectangle {
                    id: playlistHoverFrame
                    x: leftButtonsWidth
                    y: 0
                    width: Math.max(0, parent.width - x)
                    height: parent.height
                    radius: 4
                    color: controller.hoverBackgroundColor(playlistMouse.containsMouse)
                    border.width: controller.hoverBorderWidth(playlistMouse.containsMouse)
                    border.color: controller.hoverBorderColor(playlistMouse.containsMouse)
                    z: 0
                }

                Text {
                    x: leftButtonCount > 0 ? leftButtonsWidth + 5 : 5
                    z: 1
                    width: Math.max(0, parent.width - x - (Config.mopidyShowPlaylistDeleteIcon ? 38 : 5))
                    height: parent.height
                    text: modelData.name || "Без названия"
                    color: controller.hoverTextColor(playlistMouse.containsMouse, Config.text)
                    font.family: Config.mopidyTrackFont
                    font.pixelSize: Config.mopidyTrackFontSize
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Primitives.HoverButtonSurface {
                    id: playlistListDeleteButton
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
                    onClicked: controller.openDeletePlaylistFromListDialog(modelData.uri, modelData.name)

                    Text {
                        x: (parent.width - width) / 2 + Config.mopidyPlaylistDeleteIconX
                        y: (parent.height - height) / 2 + Config.mopidyPlaylistDeleteIconY
                        width: Math.max(1, implicitWidth)
                        height: Math.max(1, implicitHeight)
                        text: Config.mopidyPlaylistDeleteIcon
                        color: controller.playlistDeleteIconColor(playlistListDeleteButton.hovered)
                        font.family: Config.font
                        font.pixelSize: Config.mopidyPlaylistDeleteIconSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Primitives.HoverButtonSurface {
                    id: playlistSwitchButton
                    z: 2
                    visible: switchButtonVisible
                    x: 1
                    y: 1
                    width: 30
                    height: parent.height - 2
                    cornerRadius: 3
                    hoverBackgroundEnabled: Config.mopidyHoverMode === "background"
                    hoverBackgroundColor: Config.mopidyHoverColor
                    hoverBorderEnabled: Config.mopidyHoverMode === "frame"
                    hoverBorderColor: Config.mopidyHoverColor
                    hoverBorderWidth: 1
                    onClicked: controller.switchPlaylist(modelData.uri, modelData.name)

                    Text {
                        x: (parent.width - width) / 2 + Config.mopidySwitchPlaylistIconX
                        y: (parent.height - height) / 2 + Config.mopidySwitchPlaylistIconY
                        width: Math.max(1, implicitWidth)
                        height: Math.max(1, implicitHeight)
                        text: Config.mopidySwitchPlaylistIcon
                        color: controller.hoverTextColor(playlistSwitchButton.hovered, Config.mopidyControlIconColor)
                        font.family: Config.font
                        font.pixelSize: Config.mopidySwitchPlaylistIconSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Primitives.HoverButtonSurface {
                    id: playlistAddButton
                    z: 2
                    visible: addButtonVisible
                    x: switchButtonVisible ? 34 : 1
                    y: 1
                    width: 30
                    height: parent.height - 2
                    cornerRadius: 3
                    hoverBackgroundEnabled: Config.mopidyHoverMode === "background"
                    hoverBackgroundColor: Config.mopidyHoverColor
                    hoverBorderEnabled: Config.mopidyHoverMode === "frame"
                    hoverBorderColor: Config.mopidyHoverColor
                    hoverBorderWidth: 1
                    onClicked: controller.addPlaylist(modelData.uri, modelData.name)

                    Text {
                        x: (parent.width - width) / 2 + Config.mopidyAddIconX
                        y: (parent.height - height) / 2 + Config.mopidyAddIconY
                        width: Math.max(1, implicitWidth)
                        height: Math.max(1, implicitHeight)
                        text: Config.mopidyAddIcon
                        color: controller.hoverTextColor(playlistAddButton.hovered, Config.mopidyControlIconColor)
                        font.family: Config.font
                        font.pixelSize: Config.mopidyAddIconSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: playlistMouse
                    x: leftButtonsWidth
                    y: 0
                    width: Math.max(0, parent.width - x - (Config.mopidyShowPlaylistDeleteIcon ? 33 : 0))
                    height: parent.height
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.MiddleButton)
                            controller.openDeletePlaylistFromListDialog(modelData.uri, modelData.name)
                        else if (mouse.button === Qt.RightButton)
                            controller.addPlaylist(modelData.uri, modelData.name)
                        else
                            controller.openPlaylist(modelData.uri, modelData.name)
                    }
                }
            }
        }

    }

    Text {
        width: parent.width
        height: parent.height
        visible: controller.libraryMode === "playlists" && !controller.playlistsBusy && controller.playlists.length === 0
        text: "Плейлистов нет"
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MopidyWidgets.MopidyPlaylistContents {
        width: parent.width
        height: Math.max(0, parent.height - 35)
        visible: libraryRoot.controller.libraryMode === "playlistItems"
        controller: libraryRoot.controller
    }
    Rectangle {
        id: emptyPlaylistArea
        width: parent.width
        height: parent.height
        z: 50
        visible: controller.libraryMode === "playlistItems" && !controller.playlistsBusy && controller.playlistItems.length === 0
        objectName: "mopidyEmptyPlaylistArea"
        MouseArea {
            id: emptyPlaylistClickArea
            anchors.fill: parent
            enabled: !controller.playlistsBusy && !!controller.playlistUri
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: controller.openPlaylistAddMode()
        }
        color: controller.hoverBackgroundColor(emptyPlaylistHover.containsMouse)
        border.width: controller.hoverBorderWidth(emptyPlaylistHover.containsMouse)
        border.color: controller.hoverBorderColor(emptyPlaylistHover.containsMouse)
        radius: 4

        Text {
            anchors.fill: parent
            text: "Плейлист пуст"
            color: controller.hoverTextColor(emptyPlaylistHover.containsMouse, Config.textMuted)
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            enabled: false
        }

        HoverHandler {
            id: emptyPlaylistHover
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }
    }

    Column {
        width: parent.width
        height: Math.max(0, parent.height - 35)
        spacing: 5
        visible: controller.libraryMode === "search"

        Row {
            width: parent.width
            height: 30
            spacing: 5

            TextField {
                id: searchField
                width: parent.width - 42
                height: 30
                text: controller.searchQuery
                color: Config.text
                placeholderText: "Поиск в Mopidy…"
                placeholderTextColor: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                selectByMouse: true
                background: Rectangle {
                    color: Config.settingsBackground
                    border.color: searchField.activeFocus ? Config.accent : Config.baseColor
                    border.width: 1
                    radius: 4
                }
                onTextChanged: controller.searchQuery = text
                onAccepted: controller.searchLibrary()
            }

            MopidyWidgets.MopidyHoverIcon {
                width: 37
                height: 30
                iconText: controller.searchBusy ? "…" : Config.mopidyRefreshIcon
                iconSize: Config.mopidyRefreshIconSize
                baseColor: controller.searchBusy ? Config.textMuted : Config.mopidyControlIconColor
                enabledState: !controller.searchBusy
                onClicked: controller.searchLibrary()
            }
        }

        ListView {
            width: parent.width
            height: Math.max(0, parent.height - 35)
            clip: true
            spacing: 2
            model: controller.searchResults
            visible: controller.searchResults.length > 0
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                width: parent ? parent.width : 0
                height: Config.mopidyTrackRowHeight
                radius: 4
                color: controller.hoverBackgroundColor(resultMouse.containsMouse)
                border.width: controller.hoverBorderWidth(resultMouse.containsMouse)
                border.color: controller.hoverBorderColor(resultMouse.containsMouse)

                Column {
                    x: 5
                    width: Math.max(0, parent.width - 55)
                    height: parent.height

                    Text {
                        width: parent.width
                        height: 18
                        text: modelData.name || "Без названия"
                        color: Config.text
                        font.family: Config.mopidyTrackFont
                        font.pixelSize: Config.mopidyTrackFontSize
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        height: 14
                        text: [modelData.artist || "", modelData.album || ""].filter(function(v) { return !!v }).join(" · ")
                        color: Config.textMuted
                        font.family: Config.mopidyArtistFont
                        font.pixelSize: Config.mopidyArtistFontSize
                        elide: Text.ElideRight
                    }
                }

                Text {
                    width: 45
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    anchors.verticalCenter: parent.verticalCenter
                    text: controller.formatDuration(modelData.duration)
                    color: controller.hoverTextColor(resultMouse.containsMouse, Config.textMuted)
                    font.family: Config.mopidyDurationFont
                    font.pixelSize: Config.mopidyDurationFontSize
                    horizontalAlignment: Text.AlignRight
                }

                MouseArea {
                    id: resultMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton)
                            controller.addSearchResult(modelData.uri, modelData.name)
                    }
                }
            }
        }

        Text {
            width: parent.width
            height: Math.max(0, parent.height - 35)
            visible: !controller.searchBusy && controller.searchQuery.trim().length > 0 && controller.searchResults.length === 0
            text: "Ничего не найдено"
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
