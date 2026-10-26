import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.."
import "../primitives"

Item {
    id: modulesSection

    property var host: null
    property var settings: Settings

    function resetScroll() {
        modulesFlick.contentY = 0
    }

    function launcherTargetScreen() {
        var wanted = String((settings.moduleMonitors || {}).launcher || Config.monitorName || "").trim().toLowerCase()
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var screen = Quickshell.screens[i]
            if (!screen) continue
            if (wanted && (String(screen.name || "").trim().toLowerCase() === wanted
                    || String(screen.model || "").trim().toLowerCase() === wanted
                    || String(screen).trim().toLowerCase() === wanted))
                return screen
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    function launcherDefaultCoordinate(index) {
        var screen = launcherTargetScreen()
        var available = screen ? Number(index === 0 ? screen.width : screen.height) : (index === 0 ? 1920 : 1080)
        var size = Number(index === 0 ? Config.launcherWidth : Config.launcherHeight)
        return Math.max(0, Math.round((available - size) / 2))
    }

    function launcherCoordinate(index) {
        var geometry = settings.geometry || {}
        var g = geometry.launcher || [-999999, -999999, Config.launcherWidth, Config.launcherHeight]
        var value = Number(g[index])
        if (index < 2 && (!isFinite(value) || value < -10000))
            return launcherDefaultCoordinate(index)
        return isFinite(value) ? value : 0
    }

    function writeLauncherCoordinate(index, value) {
        // A focus/blur without an edit should preserve the responsive auto-center default.
        if (Math.round(Number(value) || 0) === Math.round(launcherCoordinate(index)))
            return
        var geometry = Object.assign({}, settings.geometry || {})
        var a = (geometry.launcher || [-999999, -999999, Config.launcherWidth, Config.launcherHeight]).slice()
        if (!isFinite(Number(a[0])) || Number(a[0]) < -10000) a[0] = launcherDefaultCoordinate(0)
        if (!isFinite(Number(a[1])) || Number(a[1]) < -10000) a[1] = launcherDefaultCoordinate(1)
        a[index] = Math.round(Number(value) || 0)
        a[2] = Config.launcherWidth
        a[3] = Config.launcherHeight
        geometry.launcher = a
        settings.geometry = geometry
        settings.save()
    }
    visible: host && host.currentTab === 0
    width: parent ? parent.width : 0
    height: visible ? parent.height - y : 0

    Flickable {
        id: modulesFlick
        visible: host.currentTab === 0
        width: parent.width
        height: parent.height - y
        contentWidth: Math.max(width, modulesColumn.width)
        contentHeight: modulesColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton
            onClicked: host.clearSettingsFocus()
        }
        ScrollBar.vertical: SettingsScrollBar { visible: modulesFlick.contentHeight > modulesFlick.height + 1 }

        Column {
            id: modulesColumn
            width: modulesFlick.width - 12
            spacing: 10

    SettingsGroup {
        visible: host && host.currentTab === 0
        width: parent.width
        showFrame: false
        padding: 8
        contentSpacing: 6

                    Row {
                        width: parent.width
                        height: 32
                        Text {
                            width: parent.width - 38
                            text: "Модули и их расположение"
                            color: Config.accent
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(15)
                            verticalAlignment: Text.AlignVCenter
                        }
                        SettingsResetButton {
                            enabled: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined
                            actionAvailable: settings.hasResetChanges("modules")
                            tooltip: "Сбросить модули"
                            onClicked: settings.resetModules()
                        }
                    }

                    Row {
                        width: parent.width
                        height: 18
                        spacing: 6

                        Item { width: 110; height: 18 }

                        Repeater {
                            model: ["X", "Y", "Width", "Height"]
                            delegate: Text {
                                width: 60
                                height: 18
                                text: modelData
                                color: Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Text { width: 42; height: 18; text: "Рамка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        Text { width: 42; height: 18; text: "Фон"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        Text { width: 42; height: 18; text: "Блюр"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        Text { width: 42; height: 18; text: "Сброс"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }

                    Repeater {
                        model: settings.moduleNames

                        delegate: Row {
                            id: moduleRow
                            width: parent.width
                            height: 30
                            spacing: 6
                            property string moduleName: modelData

                            SettingsCheckBox {
                                id: enabledBox
                                width: 110
                                height: 30
                                text: settings.moduleLabels[moduleRow.moduleName]
                                checked: settings[moduleRow.moduleName]
                                onToggled: {
                                    settings[moduleRow.moduleName] = checked
                                    settings.save()
                                }
                            }

                            Repeater {
                                model: ["X", "Y", "Width", "Height"]

                                delegate: SettingsNumberField {
                                    id: geometryField
                                    width: 60
                                    height: 30
                                    value: Number(settings.geometry[moduleRow.moduleName][index])
                                    minimum: index >= 2 ? 1 : -Infinity
                                    maximum: Infinity
                                    step: 1
                                    wheelStep: 1
                                    compact: true
                                    fieldWidth: 60
                                    fieldFontSize: 10
                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                    valueWriter: function(n) {
                                        var g = Object.assign({}, settings.geometry)
                                        var a = (g[moduleRow.moduleName] || [0, 0, 100, 100]).slice()
                                        a[index] = n
                                        g[moduleRow.moduleName] = a
                                        settings.geometry = g
                                        settings.save()
                                    }
                                    ToolTip.visible: geometryField.pointerHovered
                                    ToolTip.text: ["X", "Y", "Width", "Height"][index]
                                    ToolTip.delay: 500
                                }
                            }

                            SettingsCheckBox {
                                id: frameBox
                                width: 42
                                height: 30
                                text: ""
                                indicatorOnly: true
                                checked: settings.moduleFrames[moduleRow.moduleName] !== false
                                onToggled: {
                                    var values = Object.assign({}, settings.moduleFrames)
                                    values[moduleRow.moduleName] = checked
                                    settings.moduleFrames = values
                                    settings.save()
                                }
                            }

                            SettingsCheckBox {
                                id: backgroundBox
                                width: 42
                                height: 30
                                text: ""
                                indicatorOnly: true
                                checked: settings.moduleBackgrounds[moduleRow.moduleName] !== false
                                onToggled: {
                                    var values = Object.assign({}, settings.moduleBackgrounds)
                                    values[moduleRow.moduleName] = checked
                                    settings.moduleBackgrounds = values
                                    settings.save()
                                }
                            }

                            SettingsCheckBox {
                                id: moduleBlurBox
                                width: 42
                                height: 30
                                text: ""
                                indicatorOnly: true
                                checked: settings.moduleBlurEnabled[moduleRow.moduleName] === true
                                ToolTip.visible: moduleBlurBox.pointerHovered
                                ToolTip.text: "Блюр: " + settings.moduleLabels[moduleRow.moduleName]
                                ToolTip.delay: 500
                                onToggled: settings.setModuleBlurEnabled(moduleRow.moduleName, checked)
                            }

                            SettingsResetButton {
                                width: 42
                                height: 30
                                enabled: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined
                                actionAvailable: settings.hasResetChanges("module", moduleRow.moduleName)
                                tooltip: "Сбросить настройки модуля"
                                onClicked: settings.resetModule(moduleRow.moduleName)
                            }
                        }
                    }

                    // The launcher is still a separate window, but its position now uses
                    // the shared module geometry and Smart Editing workflow. Detailed
                    // appearance/tab/project settings remain on the dedicated Launcher tab.
                    Row {
                        id: launcherModuleRow
                        width: parent.width
                        height: 30
                        spacing: 6

                        SettingsCheckBox {
                            id: launcherEnabledBox
                            width: 110
                            height: 30
                            text: "Лаунчер"
                            checked: Config.launcherEnabled
                            onToggled: {
                                Config.launcherEnabled = checked
                                settings.save()
                            }
                            Connections {
                                target: Config
                                function onLauncherEnabledChanged() {
                                    launcherEnabledBox.checked = Config.launcherEnabled
                                }
                            }
                        }

                        Repeater {
                            model: ["X", "Y"]
                            delegate: SettingsNumberField {
                                id: launcherCoordinateField
                                width: 60
                                height: 30
                                compact: true
                                fieldWidth: 60
                                fieldFontSize: 10
                                value: modulesSection.launcherCoordinate(index)
                                minimum: -10000
                                maximum: 10000
                                step: 1
                                wheelStep: 1
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                valueWriter: function(n) { modulesSection.writeLauncherCoordinate(index, n) }
                                ToolTip.visible: launcherCoordinateField.pointerHovered
                                ToolTip.text: ["X", "Y"][index]
                                ToolTip.delay: 500
                            }
                        }

                        SettingsNumberField {
                            id: launcherWidthField
                            width: 60
                            height: 30
                            compact: true
                            fieldWidth: 60
                            fieldFontSize: 10
                            value: Config.launcherWidth
                            minimum: 500
                            maximum: 1400
                            step: 1
                            wheelStep: 1
                            targetObject: Config
                            targetProperty: "launcherWidth"
                            settingsObject: settings
                            saveOnEdit: true
                        }

                        SettingsNumberField {
                            id: launcherHeightField
                            width: 60
                            height: 30
                            compact: true
                            fieldWidth: 60
                            fieldFontSize: 10
                            value: Config.launcherHeight
                            minimum: 400
                            maximum: 1200
                            step: 1
                            wheelStep: 1
                            targetObject: Config
                            targetProperty: "launcherHeight"
                            settingsObject: settings
                            saveOnEdit: true
                        }

                        SettingsCheckBox {
                            id: launcherFrameBox
                            width: 42
                            height: 30
                            text: ""
                            indicatorOnly: true
                            checked: settings.moduleFrames.launcher !== false
                            ToolTip.visible: launcherFrameBox.pointerHovered
                            ToolTip.text: "Рамка лаунчера"
                            ToolTip.delay: 500
                            onToggled: {
                                var values = Object.assign({}, settings.moduleFrames)
                                values.launcher = checked
                                settings.moduleFrames = values
                                settings.save()
                            }
                        }

                        SettingsCheckBox {
                            id: launcherBackgroundBox
                            width: 42
                            height: 30
                            text: ""
                            indicatorOnly: true
                            checked: settings.moduleBackgrounds.launcher !== false
                            ToolTip.visible: launcherBackgroundBox.pointerHovered
                            ToolTip.text: "Фон лаунчера"
                            ToolTip.delay: 500
                            onToggled: {
                                var values = Object.assign({}, settings.moduleBackgrounds)
                                values.launcher = checked
                                settings.moduleBackgrounds = values
                                settings.save()
                            }
                        }

                        SettingsCheckBox {
                            id: launcherBlurBox
                            width: 42
                            height: 30
                            text: ""
                            indicatorOnly: true
                            checked: settings.moduleBlurEnabled.launcher === true
                            ToolTip.visible: launcherBlurBox.pointerHovered
                            ToolTip.text: "Блюр лаунчера"
                            ToolTip.delay: 500
                            onToggled: settings.setModuleBlurEnabled("launcher", checked)
                        }

                        SettingsResetButton {
                            width: 42
                            height: 30
                            enabled: settings.activeProfile.length > 0 && settings.profiles && settings.profiles[settings.activeProfile] !== undefined
                            actionAvailable: settings.hasResetChanges("launcher")
                            tooltip: "Сбросить настройки лаунчера"
                            onClicked: settings.resetLauncherSettings()
                        }
                    }

                    Item { width: 1; height: 4 }
    }

    SettingsGroup {
        visible: host && host.currentTab === 0
        width: parent.width
        showFrame: false
        padding: 8
        contentSpacing: 6

                    Row {
                        width: parent.width
                        height: 46
                        spacing: 10

                        SettingsButton {
                            id: layoutEditButton
                            width: 270
                            height: 46
                            text: "УМНОЕ РЕДАКТИРОВАНИЕ"
                            fontSize: 11
                            fontBold: true
                            fillOnHover: false
                            borderOnHover: true
                            accentColor: Config.accent
                            backgroundColor: "transparent"
                            textColor: Config.accent
                            onClicked: host.layoutEditRequested()
                        }
                        Text {
                            width: parent.width - 280
                            height: 46
                            text: "Скрывает окно настроек и позволяет перетаскивать видимые блоки мышью.\nEsc — завершить редактирование и вернуться сюда."
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            wrapMode: Text.WordWrap
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
    }
        }
    }
}
