import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "components"
import "components/settings"
import "services"
import "components/primitives" as Primitives

ShellRoot {
    id: shell
    Clock { id: clock; active: Settings.loaded && (Settings.time || (shell.calendarVisible && Settings.calendar)) }
    SystemMonitor { id: monitor }
    Loader {
        id: weatherLoader
        active: Settings.loaded && (Settings.weatherNow || Settings.weatherHourly || Settings.weatherDaily)
        sourceComponent: Component { Weather {} }
    }
    property bool calendarVisible: false
    property bool mopidyVisible: false
    property bool settingsVisible: false
    property bool layoutEditMode: false
    property bool settingsMoveMode: false
    property bool mopidyTopReveal: false

    Connections {
        target: mopidyWidget
        function onTopPanelHideRequested() {
            shell.mopidyTopReveal = false
        }
    }

    onLayoutEditModeChanged: {
        if (layoutEditMode) {
            settingsMoveMode = false
            settingsVisible = false
        }
    }

    onSettingsMoveModeChanged: {
        if (settingsMoveMode) {
            layoutEditMode = false
            settingsVisible = false
        }
    }

    Connections {
        target: Settings
        function onMopidyChanged() {
            if (!Settings.mopidy) {
                shell.mopidyVisible = false
                shell.mopidyTopReveal = false
            }
        }
    }

    Connections {
        target: Config
        function onMopidyToggleWithPlayerRightClickChanged() {
            if (Config.mopidyToggleWithPlayerRightClick) {
                shell.mopidyVisible = false
                shell.mopidyTopReveal = false
            }
        }
    }

    Shortcut {
        sequence: "Esc"
        enabled: shell.settingsMoveMode
        onActivated: {
            shell.settingsMoveMode = false
            shell.settingsVisible = true
        }
    }
    property bool timerOptionsVisible: false
    property bool timerCommentVisible: false
    property bool timerFinishedVisible: false
    property string timerCommentFile: ""
    property string timerCommentText: ""
    property string timerFinishedComment: ""
    property string timerFinishedTitle: ""
    property string timerFinishedColor: Config.text
    readonly property string timerFinishedImageSource: {
        var p = String(Config.timerFinishedImagePath || "").trim()
        if (p === "") return ""
        if (p.indexOf("~/") === 0) p = Quickshell.env("HOME") + p.slice(1)
        if (/^[A-Za-z][A-Za-z0-9+.-]*:/.test(p)) return p
        return "file://" + p
    }
    property string focusedOutputName: ""
    property var focusedOutputScreen: Quickshell.screens[0]

    WidgetWindow { visible: Settings.time; moduleName: "time"; layoutEditMode: shell.layoutEditMode; layoutEditor: moduleLayoutEditorWindow; offsetX: Settings.geometryForLayout("time")[0]; offsetY: Settings.geometryForLayout("time")[1]; contentWidth: Settings.geometry.time[2]; contentHeight: Settings.geometry.time[3]
        TimeWidget { anchors.fill: parent; clock: clock; onCalendarRequested: shell.calendarVisible = !shell.calendarVisible; onSettingsRequested: shell.settingsVisible = !shell.settingsVisible }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "cpu"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.cpu
        offsetX: Settings.geometryForLayout("cpu")[0]
        offsetY: Settings.geometryForLayout("cpu")[1]
        contentWidth: Settings.geometry.cpu[2]
        contentHeight: Settings.geometry.cpu[3]
        CpuWidget { anchors.fill: parent }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "cpuGraph"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.cpuGraph
        offsetX: Settings.geometryForLayout("cpuGraph")[0]
        offsetY: Settings.geometryForLayout("cpuGraph")[1]
        contentWidth: Settings.geometry.cpuGraph[2]
        contentHeight: Settings.geometry.cpuGraph[3]
        CpuGraph { anchors.fill: parent }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "topApps"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.topApps
        offsetX: Settings.geometryForLayout("topApps")[0]
        offsetY: Settings.geometryForLayout("topApps")[1]
        contentWidth: Settings.geometry.topApps[2]
        contentHeight: Settings.geometry.topApps[3]
        TopApps { anchors.fill: parent; monitor: monitor }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "networkStat"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.networkStat
        offsetX: Settings.geometryForLayout("networkStat")[0]
        offsetY: Settings.geometryForLayout("networkStat")[1]
        contentWidth: Settings.geometry.networkStat[2]
        contentHeight: Settings.geometry.networkStat[3]
        NetworkStat { anchors.fill: parent; monitor: monitor }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "weatherNow"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.weatherNow
        offsetX: Settings.geometryForLayout("weatherNow")[0]
        offsetY: Settings.geometryForLayout("weatherNow")[1]
        contentWidth: Settings.geometry.weatherNow[2]
        contentHeight: Settings.geometry.weatherNow[3]
        WeatherNow {
            anchors.fill: parent
            weather: weatherLoader.item ? weatherLoader.item.now : ({})
            weatherService: weatherLoader.item
            onSettingsRequested: {
                shell.settingsVisible = true
                settingsWidget.openWeatherSettings()
            }
        }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "weatherHourly"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.weatherHourly
        offsetX: Settings.geometryForLayout("weatherHourly")[0]
        offsetY: Settings.geometryForLayout("weatherHourly")[1]
        contentWidth: Settings.geometry.weatherHourly[2]
        contentHeight: Settings.geometry.weatherHourly[3]
        WeatherList {
            anchors.fill: parent
            entries: weatherLoader.item ? weatherLoader.item.day : []
            hourly: true
            weatherService: weatherLoader.item
        }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "weatherDaily"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.weatherDaily
        offsetX: Settings.geometryForLayout("weatherDaily")[0]
        offsetY: Settings.geometryForLayout("weatherDaily")[1]
        contentWidth: Settings.geometry.weatherDaily[2]
        contentHeight: Settings.geometry.weatherDaily[3]
        WeatherList {
            anchors.fill: parent
            entries: weatherLoader.item ? weatherLoader.item.week : []
            hourly: false
            weatherService: weatherLoader.item
        }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        id: timerWindow
        moduleName: "timer"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.timer
        offsetX: Settings.geometryForLayout("timer")[0]
        offsetY: Settings.geometryForLayout("timer")[1]
        contentWidth: Settings.geometry.timer[2]
        contentHeight: timerWidget.adaptiveHeight
        TimerWidget { id: timerWidget; anchors.fill: parent }

        // Use a Wayland xdg-popup instead of a second layer-shell surface.
        // Niri's window-open/window-close animations apply to windows, while
        // PopupWindow is an xdg-popup attached to the existing timer surface.
        // This prevents the compositor from animating the mini-window itself.
        PopupWindow {
            id: timerOptionsOverlay
            // Keep the popup surface alive for the lifetime of the timer widget.
            // This prevents the compositor from treating every open/close as a
            // newly created surface and applying its own appearance animation.
            visible: false
            color: "transparent"
            surfaceFormat.opaque: false
            anchor.window: timerWindow
            anchor.rect.x: Settings.geometry.timerOptions[0] - Settings.geometryForLayout("timer")[0]
            anchor.rect.y: Settings.geometry.timerOptions[1] - Settings.geometryForLayout("timer")[1]
            implicitWidth: Settings.geometry.timerOptions[2]
            implicitHeight: Settings.geometry.timerOptions[3]
            // grabFocus lets the popup detect a click outside itself and close.
            grabFocus: true
            mask: Region { item: popupInputRegion }

            Item {
                id: popupInputRegion
                width: shell.timerOptionsVisible ? parent.width : 0
                height: shell.timerOptionsVisible ? parent.height : 0
            }

            TimerOptions {
                id: timerOptionsPopup
                anchors.fill: parent
                timers: timerWidget.timers
                selectedFile: timerWidget.selectedFile
                onCloseRequested: timerOptionsPopup.startClose()
                onCommentRequested: file => {
                    timerOptionsPopup.commentFile = file
                    timerOptionsPopup.commentText = timerWidget.commentForFile(file)
                    timerOptionsPopup.commentMode = true
                }
                onCloseFinished: {
                    timerWidget.selectedFile = ""
                    shell.timerOptionsVisible = false
                    timerOptionsPopup.closing = false
                    timerOptionsOverlay.visible = false
                }
            }

            onVisibleChanged: {
                if (!visible && shell.timerOptionsVisible) {
                    timerWidget.selectedFile = ""
                    shell.timerOptionsVisible = false
                    timerOptionsPopup.closing = false
                }
            }

            // The popup surface remains alive. Closing is driven by the timer
            // selection state instead of destroying the popup surface.
        }


        PanelWindow {
            id: timerFinishedPopup
            visible: shell.timerFinishedVisible
            screen: shell.focusedOutputScreen || Quickshell.screens[0]
            color: Config.transparent
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            anchors.left: true
            anchors.right: true
            anchors.top: true
            anchors.bottom: true
            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                id: timerFinishedCard
                anchors.centerIn: parent
                readonly property bool imageMode: Config.timerFinishedImageEnabled && shell.timerFinishedImageSource !== ""
                                width: imageMode ? Math.max(305, Config.timerFinishedImageWidth + Config.timerFinishedImageMargin * 2) : 305
                height: imageMode
                    ? timerFinishedImageTitle.y + timerFinishedImageTitle.height + Config.timerFinishedImageMargin + timerFinishedImage.height + Config.timerFinishedImageMargin
                    : 102
                color: Config.timerFinishedBackgroundUsesTimerColor ? shell.timerFinishedColor : Config.timerFinishedBackgroundColor
                focus: true

                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Space) {
                        shell.timerFinishedVisible = false
                        event.accepted = true
                    }
                }
                radius: Config.frameRadius
                border.color: Config.timerFinishedBorderUsesTimerColor ? shell.timerFinishedColor : Config.baseColor
                border.width: Config.frameBorderWidth
                antialiasing: true

                Image {
                    id: timerFinishedImage
                    visible: timerFinishedCard.imageMode
                    source: visible ? shell.timerFinishedImageSource : ""
                    x: (parent.width - width) / 2
                    y: timerFinishedImageTitle.y + timerFinishedImageTitle.height + Config.timerFinishedImageMargin
                    width: Math.min(Config.timerFinishedImageWidth, parent.width - Config.timerFinishedImageMargin * 2)
                    height: implicitWidth > 0 && implicitHeight > 0 ? width * (implicitHeight / implicitWidth) : 0
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Text {
                    id: timerFinishedImageTitle
                    visible: timerFinishedCard.imageMode
                    x: Config.timerFinishedImageMargin
                    y: Config.timerFinishedImageMargin
                    width: parent.width - Config.timerFinishedImageMargin * 2
                    height: Math.max(24, Config.timerFinishedTitleFontSize + 4)
                    text: shell.timerFinishedTitle || "Время вышло"
                    color: Config.timerFinishedTitleUsesTimerColor ? shell.timerFinishedColor : Config.timerFinishedTitleColor
                    font.family: Config.timerFinishedTitleFont
                    font.pixelSize: Config.timerFinishedTitleFontSize
                    horizontalAlignment: Config.timerFinishedTitleAlignment === 0
                        ? Text.AlignLeft
                        : (Config.timerFinishedTitleAlignment === 2 ? Text.AlignRight : Text.AlignHCenter)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                Text {
                    visible: !timerFinishedCard.imageMode
                    x: 12
                    y: 10
                    width: parent.width - 24
                    height: 24
                    text: "󰀠  Таймер завершён"
                    color: shell.timerFinishedColor
                    font.family: Config.ledFont
                    font.pixelSize: 18
                }

                Text {
                    visible: !timerFinishedCard.imageMode
                    x: 12
                    y: 39
                    width: parent.width - 24
                    height: 20
                    text: shell.timerFinishedComment || "Время вышло"
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Text {
                    visible: !timerFinishedCard.imageMode
                    x: 12
                    y: 68
                    width: parent.width - 24
                    height: 18
                    text: "динь-динь"
                    color: Config.textDim
                    font.family: Config.settingsFont
                    font.pixelSize: 10
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: shell.timerFinishedVisible = false
                }
            }
        }
    }

    Process {
        id: focusedOutputProcess
        command: ["niri", "msg", "-j", "focused-output"]
        stdout: StdioCollector {
            id: focusedOutputCollector
        }
        onExited: {
            try {
                const data = JSON.parse(focusedOutputCollector.text)
                shell.focusedOutputName = data.name || ""
                shell.focusedOutputScreen = Quickshell.screens.find(s =>
                    s.name === shell.focusedOutputName ||
                    s.model === shell.focusedOutputName ||
                    s.toString() === shell.focusedOutputName
                ) || Quickshell.screens[0]
            } catch (e) {
                shell.focusedOutputName = ""
                shell.focusedOutputScreen = Quickshell.screens[0]
            }
        }
    }

    Connections {
        target: timerWidget
        function onTimerFinished(file, comment, color, timerText) {
            shell.timerFinishedComment = comment
            shell.timerFinishedTitle = String(comment || timerText || "Время вышло")
            shell.timerFinishedColor = color || Config.text
            shell.timerFinishedVisible = true
            focusedOutputProcess.running = true
        }
        function onSelectedFileChanged() {
            if (timerWidget.selectedFile !== "") {
                shell.timerOptionsVisible = true
                timerOptionsOverlay.visible = true
                timerOptionsPopup.closing = false
            } else if (shell.timerOptionsVisible && !timerOptionsPopup.closing) {
                // Close the popup through the same window-level path used by
                // an outside click. This keeps both close interactions visually
                // identical instead of mixing popup-surface and content animations.
                timerOptionsOverlay.visible = false
            }
        }
    }

    Connections {
        target: Settings
        function onTimerChanged() {
            if (!Settings.timer && timerOptionsOverlay.visible) {
                timerOptionsOverlay.visible = false
                timerWidget.selectedFile = ""
                shell.timerOptionsVisible = false
                timerOptionsPopup.closing = false
            }
        }
    }
    WidgetWindow {
        id: calendarWindow
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "calendar"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.calendar
        offsetX: Settings.geometryForLayout("calendar")[0]
        offsetY: Settings.geometryForLayout("calendar")[1]
        contentWidth: Settings.geometry.calendar[2]
        contentHeight: Settings.geometry.calendar[3]
        bottomLayer: false
        // The calendar becomes keyboard-focusable while editing a date note.
        // Layer-shell windows default to non-focusable, so TextArea.forceActiveFocus()
        // alone cannot receive key events until this is enabled.
        keyboardEnabled: calendarNotesWidget.noteOverlayMode === "edit"
        Primitives.AnimatedVisibility {
            id: calendarVisibility
            anchors.fill: parent
            shown: shell.calendarVisible
            animationStyle: Config.animationCalendarVisibilityStyle
            duration: Config.animationDuration(Math.max(Config.animationCalendarSlideDuration, Config.animationCalendarFadeDuration), "appearance")
            CalendarWidget { id: calendarNotesWidget; anchors.fill: parent; date: clock.now; open: true }
        }
    }

    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "volumes"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.volumes
        offsetX: Settings.geometryForLayout("volumes")[0]
        offsetY: Settings.geometryForLayout("volumes")[1]
        contentWidth: Settings.geometry.volumes[2]
        contentHeight: Math.min(Config.volumeMaxHeight, volumesWidget.adaptiveHeight)
        Volumes { id: volumesWidget; anchors.fill: parent; monitor: monitor }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "player"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.player
        offsetX: Settings.geometryForLayout("player")[0]
        offsetY: Settings.geometryForLayout("player")[1]
        contentWidth: Settings.geometry.player[2]
        contentHeight: Settings.geometry.player[3]
        backgroundBlurEnabled: Config.playerBlurEnabled
        backgroundBlurRadius: Config.playerBlurRadius
        Player {
            id: playerWidget
            anchors.fill: parent
            anchors.margins: 0
            onMopidyToggleRequested: {
                if (Settings.mopidy && Config.mopidyToggleWithPlayerRightClick) {
                    if (shell.mopidyVisible)
                        mopidyWidget.resetToInitialScreen()
                    shell.mopidyVisible = !shell.mopidyVisible
                }
            }
        }
}
    WidgetWindow {
        id: mopidyWindow
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "mopidy"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.mopidy
        offsetX: Settings.geometryForLayout("mopidy")[0]
        offsetY: Settings.geometryForLayout("mopidy")[1]
        contentWidth: Settings.geometry.mopidy[2]
        contentHeight: Settings.geometry.mopidy[3]
        keyboardEnabled: true
        bottomLayer: !(Config.mopidyHideTopPanel && shell.mopidyTopReveal)
        Primitives.AnimatedVisibility {
            id: mopidyVisibility
            anchors.fill: parent
            shown: !Config.mopidyToggleWithPlayerRightClick || shell.mopidyVisible
            animationStyle: Config.animationMopidyVisibilityStyle
            duration: Config.animationDuration(280, "appearance")
            Mopidy {
                id: mopidyWidget
                anchors.fill: parent
                externalTopPanelHover: shell.mopidyTopReveal
            }
        }
    }
    PanelWindow {
        id: mopidyTopHoverWindow
        visible: Settings.mopidy && Config.mopidyHideTopPanel && !shell.mopidyTopReveal
        screen: mopidyWindow.screen
        implicitWidth: Settings.geometry.mopidy[2]
        implicitHeight: Config.mopidyTopPanelHoverHeight
        color: Config.transparent
        focusable: false
        exclusionMode: ExclusionMode.Ignore
        anchors.left: true
        anchors.top: true
        margins.left: Settings.geometryForLayout("mopidy")[0]
        margins.top: Settings.geometryForLayout("mopidy")[1]
        WlrLayershell.layer: WlrLayer.Top

        MouseArea {
            id: mopidyTopRevealMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onEntered: shell.mopidyTopReveal = true
        }
    }

    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "cava"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.cava
        offsetX: Settings.geometryForLayout("cava")[0]
        offsetY: Settings.geometryForLayout("cava")[1]
        contentWidth: Settings.geometry.cava[2]
        contentHeight: Settings.geometry.cava[3]
        Cava {
            anchors.fill: parent
            onPlaybackToggleRequested: {
                var backend = String(playerWidget.player.player || "").trim().toLowerCase()
                if (backend !== "")
                    Quickshell.execDetached([Quickshell.shellDir + "/scripts/player_pausing", "pause", backend])
            }
            onMopidyToggleRequested: {
                if (Settings.mopidy && Config.mopidyToggleWithPlayerRightClick) {
                    if (shell.mopidyVisible)
                        mopidyWidget.resetToInitialScreen()
                    shell.mopidyVisible = !shell.mopidyVisible
                }
            }
        }
}
    WidgetWindow {
        layoutEditor: moduleLayoutEditorWindow
        moduleName: "networks"
        layoutEditMode: shell.layoutEditMode
        visible: Settings.networks
        offsetX: Settings.geometryForLayout("networks")[0]
        offsetY: Settings.geometryForLayout("networks")[1]
        contentWidth: Settings.geometry.networks[2]
        contentHeight: Settings.geometry.networks[3]
        Networks { anchors.fill: parent; monitor: monitor }
}

    WidgetWindow {
        id: settingsWindow
        moduleName: "settings"
        settingsDragMode: shell.settingsMoveMode
        layoutEditMode: shell.settingsMoveMode
        layoutEditor: layoutEditorWindow
        normalWlrLayer: WlrLayer.Overlay
        editWlrLayer: WlrLayer.Overlay
        visible: shell.settingsVisible || settingsVisibility.running
        keyboardEnabled: shell.settingsVisible || settingsVisibility.running
        offsetX: Settings.settingsGeometry[0]
        offsetY: Settings.settingsGeometry[1]
        screenName: Settings.settingsMonitorName
        contentWidth: Settings.settingsGeometry[2]
        contentHeight: Settings.settingsGeometry[3]
        bottomLayer: false
        Primitives.AnimatedVisibility {
            id: settingsVisibility
            anchors.fill: parent
            shown: shell.settingsVisible
            animationStyle: Config.animationSettingsVisibilityStyle
            duration: Config.animationDuration(300, "appearance")
            SettingsWidget {
                id: settingsWidget
            settingsMoveMode: shell.settingsMoveMode
            anchors.fill: parent
            onCloseRequested: {
                shell.settingsVisible = false
            }
            onLayoutEditRequested: {
                shell.settingsMoveMode = false
                shell.settingsVisible = false
                shell.layoutEditMode = true
            }
            onSettingsMoveRequested: {
                shell.layoutEditMode = false
                shell.settingsVisible = false
                shell.settingsMoveMode = true
                Qt.callLater(function() {
                    if (!shell.settingsMoveMode)
                        return
                    var moveScreen = settingsWindow.resolveScreen(Settings.settingsMonitorName || Config.monitorName)
                    if (!moveScreen)
                        return
                    var geometry = Settings.settingsGeometry || [0, 0, 560, 850]
                    layoutEditorWindow.beginProxyDrag(
                        "settings",
                        Number(moveScreen.x || 0) + Number(geometry[0] || 0),
                        Number(moveScreen.y || 0) + Number(geometry[1] || 0),
                        Number(geometry[2] || settingsWindow.width || 560),
                        Number(geometry[3] || settingsWindow.height || 850),
                        settingsWindow.screenStorageName(moveScreen)
                    )
                })
                }
            }
        }
    }

    LayoutEditorProxyWindow { editor: layoutEditorWindow; targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null }
    LayoutEditorProxyWindow { editor: layoutEditorWindow; targetScreen: Quickshell.screens.length > 1 ? Quickshell.screens[1] : null }
    LayoutEditorProxyWindow { editor: layoutEditorWindow; targetScreen: Quickshell.screens.length > 2 ? Quickshell.screens[2] : null }
    LayoutEditorProxyWindow { editor: layoutEditorWindow; targetScreen: Quickshell.screens.length > 3 ? Quickshell.screens[3] : null }

    ModuleLayoutEditorWindow {
        id: moduleLayoutEditorWindow
        active: shell.layoutEditMode
        onExitRequested: {
            shell.layoutEditMode = false
            shell.settingsVisible = true
        }
    }

    LayoutEditorWindow {
        id: layoutEditorWindow
        active: shell.settingsMoveMode
        onExitRequested: {
            shell.settingsMoveMode = false
            shell.settingsVisible = true
        }
    }

}
