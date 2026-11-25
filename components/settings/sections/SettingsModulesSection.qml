import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.."
import "../primitives"
import "../../../js/NotificationsGeometry.js" as NotificationsGeometry

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

    function notificationsTargetScreen() {
        var wanted = String((settings.moduleMonitors || {}).notifications || Config.monitorName || "").trim().toLowerCase()
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

    function notificationsCoordinate(index) {
        var geometry = settings.geometry || {}
        var a = geometry.notifications || [-999999, 16, Config.notificationsCardWidth, 0]
        var screen = notificationsTargetScreen()
        return NotificationsGeometry.resolvedCoordinate(a, index, screen ? screen.width : 1920, Config.notificationsCardWidth, 16)
    }

    function notificationsGeometryValue(index) {
        var geometry = settings.geometry || {}
        var a = geometry.notifications || [-999999, 16, Config.notificationsCardWidth, 0]
        if (index === 2)
            return Math.max(280, Math.min(600, Number(Config.notificationsCardWidth) || Number(a[2]) || 380))
        if (index === 3) {
            var height = Number(a[3])
            return isFinite(height) && height > 0 ? Math.min(10000, Math.round(height)) : 0
        }
        return notificationsCoordinate(index)
    }

    function writeNotificationsGeometry(index, value) {
        var next = Number(value)
        if (!isFinite(next)) return
        var geometry = Object.assign({}, settings.geometry || {})
        var a = NotificationsGeometry.normalizeGeometry(
            geometry.notifications || [-999999, 16, Config.notificationsCardWidth, 0],
            Config.notificationsCardWidth
        )

        if (index < 2) {
            next = Math.round(next)
            if (next === notificationsCoordinate(index)) return
            a[0] = notificationsCoordinate(0)
            a[1] = notificationsCoordinate(1)
            a[index] = next
        } else if (index === 2) {
            next = Math.max(280, Math.min(600, Math.round(next / 10) * 10))
            if (next === Number(Config.notificationsCardWidth)) return
            a[2] = next
            Config.notificationsCardWidth = next
        } else {
            next = Math.max(0, Math.min(10000, Math.round(next)))
            if (next === notificationsGeometryValue(3)) return
            a[3] = next
        }

        geometry.notifications = a
        settings.geometry = geometry
        settings.save()
    }

    function writeNotificationsCoordinate(index, value) {
        writeNotificationsGeometry(index, value)
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
    visible: host && host.currentPageId === "modules"
    width: parent ? parent.width : 0
    height: visible ? parent.height - y : 0

    Flickable {
        id: modulesFlick
        visible: host.currentPageId === "modules"
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
        visible: host && host.currentPageId === "modules"
        width: parent.width
        showFrame: false
        padding: 8
        contentSpacing: 6

                    Row {
                        width: parent.width
                        height: 32
                        Text {
                            width: parent.width
                                - (host && host.profileController.canSaveScope("all") ? 38 : 0)
                                - (host && host.profileController.canSaveScope("modules") ? 38 : 0)
                                - (host && host.profileController.canSaveScope("modules") ? 38 : 0)
                            text: "Модули и их расположение"
                            color: Config.accent
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(15)
                            verticalAlignment: Text.AlignVCenter
                        }
                        SettingsSaveButton {
                            actionAvailable: host && host.profileController.canSaveScope("all")
                            iconText: "󰆔"
                            tooltip: "Сохранить всё в активный профиль"
                            onClicked: host.profileController.saveAll()
                        }
                        SettingsSaveButton {
                            actionAvailable: host && host.profileController.canSaveScope("modules")
                            tooltip: "Сохранить расположение и параметры модулей"
                            onClicked: host.profileController.saveScope("modules")
                        }
                        SettingsResetButton {
                            enabled: host && host.profileController.hasActiveProfile
                            actionAvailable: host.profileController.canResetScope("modules")
                            tooltip: "Сбросить модули"
                            onClicked: settings.resetModules()
                        }
                    }

                    Row {
                        width: parent.width
                        height: 18
                        spacing: 6

                        Item { width: 96; height: 18 }

                        Repeater {
                            model: ["X", "Y", "Width", "Height"]
                            delegate: Text {
                                width: 48
                                height: 18
                                text: modelData
                                color: Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Text { width: 30; height: 18; text: "Рамка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        Text { width: 30; height: 18; text: "Фон"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        Text { width: 30; height: 18; text: "Блюр"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        Text { width: 30; height: 18; text: "Сохр."; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        Text { width: 30; height: 18; text: "Сброс"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }

                    Repeater {
                        model: settings.moduleNames.filter(function(name) { return name !== "dashboard" })

                        delegate: Row {
                            id: moduleRow
                            width: parent.width
                            height: 30
                            spacing: 6
                            property string moduleName: modelData

                            SettingsCheckBox {
                                id: enabledBox
                                width: 96
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
                                    width: 48
                                    height: 30
                                    value: moduleRow.moduleName === "notifications"
                                        ? modulesSection.notificationsGeometryValue(index)
                                        : Number(settings.geometry[moduleRow.moduleName][index])
                                    minimum: moduleRow.moduleName === "notifications"
                                        ? (index === 2 ? 280 : (index === 3 ? 0 : -10000))
                                        : (index >= 2 ? 1 : -Infinity)
                                    maximum: moduleRow.moduleName === "notifications"
                                        ? (index === 2 ? 600 : (index === 3 ? 10000 : 10000))
                                        : Infinity
                                    step: 1
                                    wheelStep: 1
                                    compact: true
                                    fieldWidth: 48
                                    fieldFontSize: 10
                                    settingsSearchId: "module." + moduleRow.moduleName + ".geometry." + ["x", "y", "width", "height"][index]
                                    settingsSearchLabel: (settings.moduleLabels[moduleRow.moduleName] || moduleRow.moduleName) + " · " + ["X", "Y", "Ширина", "Высота"][index]
                                    settingsSearchKeywords: "координаты положение расположение геометрия экран"
                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                    valueWriter: function(n) {
                                        if (moduleRow.moduleName === "notifications") {
                                            modulesSection.writeNotificationsGeometry(index, n)
                                            return
                                        }
                                        var g = Object.assign({}, settings.geometry)
                                        var a = (g[moduleRow.moduleName] || [0, 0, 100, 100]).slice()
                                        a[index] = n
                                        g[moduleRow.moduleName] = a
                                        settings.geometry = g
                                        settings.save()
                                    }
                                    ToolTip.visible: geometryField.pointerHovered
                                    ToolTip.text: moduleRow.moduleName === "notifications" && index === 1
                                        ? "Y — отступ от " + (Config.notificationsVerticalAnchor === "bottom" ? "нижнего" : "верхнего") + " края"
                                        : (moduleRow.moduleName === "notifications" && index === 2
                                            ? "Ширина окна уведомлений (280–600)"
                                            : (moduleRow.moduleName === "notifications" && index === 3
                                                ? "Максимальная высота окна; 0 — автоматически по содержимому"
                                                : ["X", "Y", "Width", "Height"][index]))
                                    ToolTip.delay: 500
                                }
                            }

                            SettingsCheckBox {
                                id: frameBox
                                width: 30
                                height: 30
                                text: ""
                                indicatorOnly: true
                                settingsSearchId: "module." + moduleRow.moduleName + ".frame"
                                settingsSearchLabel: "Рамка " + (settings.moduleLabels[moduleRow.moduleName] || moduleRow.moduleName)
                                settingsSearchKeywords: "обводка граница оформление"
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
                                width: 30
                                height: 30
                                text: ""
                                indicatorOnly: true
                                settingsSearchId: "module." + moduleRow.moduleName + ".background"
                                settingsSearchLabel: "Фон " + (settings.moduleLabels[moduleRow.moduleName] || moduleRow.moduleName)
                                settingsSearchKeywords: "подложка задний цвет"
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
                                width: 30
                                height: 30
                                text: ""
                                indicatorOnly: true
                                settingsSearchId: "module." + moduleRow.moduleName + ".blur"
                                settingsSearchLabel: "Блюр " + (settings.moduleLabels[moduleRow.moduleName] || moduleRow.moduleName)
                                settingsSearchKeywords: "размытие прозрачность"
                                checked: settings.moduleBlurEnabled[moduleRow.moduleName] === true
                                ToolTip.visible: moduleBlurBox.pointerHovered
                                ToolTip.text: "Блюр: " + settings.moduleLabels[moduleRow.moduleName]
                                ToolTip.delay: 500
                                onToggled: settings.setModuleBlurEnabled(moduleRow.moduleName, checked)
                            }

                            SettingsSaveButton {
                                actionAvailable: host && host.profileController.canSaveScope("module", moduleRow.moduleName)
                                tooltip: "Сохранить настройки модуля: " + (settings.moduleLabels[moduleRow.moduleName] || moduleRow.moduleName)
                                onClicked: host.profileController.saveScope("module", moduleRow.moduleName)
                            }
                            SettingsResetButton {
                                width: 30
                                height: 30
                                enabled: host && host.profileController.hasActiveProfile
                                actionAvailable: host.profileController.canResetScope("module", moduleRow.moduleName)
                                tooltip: "Сбросить настройки модуля"
                                onClicked: settings.resetModule(moduleRow.moduleName)
                            }
                        }
                    }

                    // Dashboard is a full-screen overlay rather than a movable module
                    // window. It gets a dedicated enable row without fake geometry or
                    // the frame/background/blur controls used by regular modules.
                    Row {
                        id: dashboardModuleRow
                        width: parent.width
                        height: 30
                        spacing: 6

                        SettingsCheckBox {
                            id: dashboardEnabledBox
                            width: 96
                            height: 30
                            text: "Dashboard"
                            checked: settings.dashboard
                            settingsSearchId: "module.dashboard.enabled"
                            settingsSearchLabel: "Dashboard · Включён"
                            settingsSearchKeywords: "обзор обзорная панель включение выключение"
                            onToggled: {
                                settings.dashboard = checked
                                settings.save()
                            }
                            Connections {
                                target: settings
                                function onDashboardChanged() {
                                    dashboardEnabledBox.checked = settings.dashboard
                                }
                            }
                        }

                        Text {
                            width: Math.max(0, dashboardModuleRow.width - 96 - 60 - 18)
                            height: 30
                            text: "Полноэкранная обзорная панель"
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        SettingsSaveButton {
                            actionAvailable: host && host.profileController.canSaveScope("dashboardModule")
                            tooltip: "Сохранить настройки модуля: Dashboard"
                            onClicked: host.profileController.saveScope("dashboardModule")
                        }
                        SettingsResetButton {
                            width: 30
                            height: 30
                            enabled: host && host.profileController.hasActiveProfile
                            actionAvailable: host.profileController.canResetScope("dashboardModule")
                            tooltip: "Сбросить настройки Dashboard"
                            onClicked: settings.resetDashboardModule()
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
                            width: 96
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
                                width: 48
                                height: 30
                                compact: true
                                fieldWidth: 48
                                fieldFontSize: 10
                                value: modulesSection.launcherCoordinate(index)
                                minimum: -10000
                                maximum: 10000
                                step: 1
                                wheelStep: 1
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                settingsSearchId: "module.launcher.geometry." + ["x", "y"][index]
                                settingsSearchLabel: "Лаунчер · " + ["X", "Y"][index]
                                settingsSearchKeywords: "координаты положение расположение геометрия экран"
                                valueWriter: function(n) { modulesSection.writeLauncherCoordinate(index, n) }
                                ToolTip.visible: launcherCoordinateField.pointerHovered
                                ToolTip.text: ["X", "Y"][index]
                                ToolTip.delay: 500
                            }
                        }

                        SettingsNumberField {
                            id: launcherWidthField
                            width: 48
                            settingsSearchId: "module.launcher.geometry.width"
                            settingsSearchLabel: "Ширина лаунчера"
                            settingsSearchKeywords: "ширина размер окна"
                            height: 30
                            compact: true
                            fieldWidth: 48
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
                            width: 48
                            settingsSearchId: "module.launcher.geometry.height"
                            settingsSearchLabel: "Высота лаунчера"
                            settingsSearchKeywords: "высота размер окна"
                            height: 30
                            compact: true
                            fieldWidth: 48
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
                            width: 30
                            settingsSearchId: "module.launcher.frame"
                            settingsSearchLabel: "Рамка лаунчера"
                            settingsSearchKeywords: "обводка граница оформление"
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
                            width: 30
                            settingsSearchId: "module.launcher.background"
                            settingsSearchLabel: "Фон лаунчера"
                            settingsSearchKeywords: "подложка задний цвет"
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
                            width: 30
                            settingsSearchId: "module.launcher.blur"
                            settingsSearchLabel: "Блюр лаунчера"
                            settingsSearchKeywords: "размытие прозрачность"
                            height: 30
                            text: ""
                            indicatorOnly: true
                            checked: settings.moduleBlurEnabled.launcher === true
                            ToolTip.visible: launcherBlurBox.pointerHovered
                            ToolTip.text: "Блюр лаунчера"
                            ToolTip.delay: 500
                            onToggled: settings.setModuleBlurEnabled("launcher", checked)
                        }

                        SettingsSaveButton {
                            actionAvailable: host && host.profileController.canSaveScope("launcher")
                            tooltip: "Сохранить настройки лаунчера"
                            onClicked: host.profileController.saveScope("launcher")
                        }
                        SettingsResetButton {
                            width: 30
                            height: 30
                            enabled: host && host.profileController.hasActiveProfile
                            actionAvailable: host.profileController.canResetScope("launcher")
                            tooltip: "Сбросить настройки лаунчера"
                            onClicked: settings.resetLauncherSettings()
                        }
                    }

                    Item { width: 1; height: 4 }
    }

    SettingsGroup {
        visible: host && host.currentPageId === "modules"
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
                            // AnimatedVisibility disables its content while the
                            // settings window exits. Keep this action rendered so
                            // the adjacent description does not reflow mid-slide.
                            visible: true
                            disabledTextColor: Config.accent
                            disabledBorderColor: Config.baseColor
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
