import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"

Column {
    id: root
    property var host
    property var settings: Settings
    property var playerBackendDefinitions: [
        { id: "deadbeef", label: "DeaDBeeF" },
        { id: "mopidy", label: "Mopidy" },
        { id: "mpv", label: "mpv" },
        { id: "spotify", label: "Spotify" },
        { id: "plasma-browser-integration", label: "Браузер" },
        { id: "org.telegram.desktop", label: "Telegram" }
    ]
    spacing: 10
    width: parent ? parent.width : 0

    ListModel {
        id: playerPriorityModel
    }

    function backendLabel(backendId) {
        for (var i = 0; i < root.playerBackendDefinitions.length; ++i) {
            if (root.playerBackendDefinitions[i].id === backendId)
                return root.playerBackendDefinitions[i].label
        }
        return backendId
    }

    function syncPlayerPriorityModel() {
        playerPriorityModel.clear()

        var source = Config.playerPriority || []
        var used = ({})

        for (var i = 0; i < source.length; ++i) {
            var item = source[i] || {}
            var backendId = typeof item === "string" ? item : String(item.id || "")
            if (!backendId || used[backendId])
                continue

            used[backendId] = true
            playerPriorityModel.append({
                backendId: backendId,
                label: root.backendLabel(backendId),
                enabled: typeof item === "string" ? true : item.enabled !== false
            })
        }

        for (var j = 0; j < root.playerBackendDefinitions.length; ++j) {
            var def = root.playerBackendDefinitions[j]
            if (used[def.id])
                continue
            playerPriorityModel.append({
                backendId: def.id,
                label: def.label,
                enabled: true
            })
        }
    }

    function savePlayerPriority() {
        var value = []
        for (var i = 0; i < playerPriorityModel.count; ++i) {
            var item = playerPriorityModel.get(i)
            value.push({
                id: String(item.backendId),
                enabled: !!item.enabled
            })
        }
        Config.playerPriority = value
        settings.save()
    }

    function togglePlayerPriority(index, enabled) {
        if (index < 0 || index >= playerPriorityModel.count)
            return
        playerPriorityModel.setProperty(index, "enabled", !!enabled)
        root.savePlayerPriority()
    }

    function movePlayerPriority(index, delta) {
        root.movePlayerPriorityTo(index, index + Number(delta))
    }

    function movePlayerPriorityTo(fromIndex, toIndex) {
        if (fromIndex < 0 || fromIndex >= playerPriorityModel.count
                || toIndex < 0 || toIndex >= playerPriorityModel.count || fromIndex === toIndex)
            return
        playerPriorityModel.move(fromIndex, toIndex, 1)
        root.savePlayerPriority()
    }

    Connections {
        target: Config
        function onPlayerPriorityChanged() { root.syncPlayerPriorityModel() }
    }

    Component.onCompleted: root.syncPlayerPriorityModel()

    SettingsGroup {
                visible: host && host.currentPageId === "player" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["playerFont", "playerSilenceFontSize", "playerSilenceLongFontSize", "playerSilenceText", "playerSilenceWidth", "playerSilenceOutlineColor", "playerSilenceOutlineWidth"] })
        padding: 8
        contentSpacing: 6

            SettingsRow {
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 1
                width: parent.width
                height: 34
                spacing: 8
                label: "Текст при отсутствии воспроизведения"
                labelWidth: 210
                labelElide: Text.ElideRight

                SettingsTextField {
                    id: playerSilenceField
                    width: 140
                    height: 30
                    text: Config.playerSilenceText
                    color: Config.text
                    selectionColor: Config.accent
                    selectedTextColor: Config.black
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.settingsUiSize(11)
                    activeFocusOnTab: true
                    background: Rectangle {
                        color: "transparent"
                        border.color: (playerSilenceField.activeFocus || playerSilenceField.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: (Config.inputBordersEnabled || playerSilenceField.activeFocus) ? 1 : 0
                        radius: Config.scaledCornerRadius(Config.settingsUiSize(4))
                    }
                    onEditingFinished: {
                        Config.playerSilenceText = text
                        settings.save()
                    }
                    Connections {
                        target: Config
                        function onPlayerSilenceTextChanged() {
                            playerSilenceField.text = Config.playerSilenceText
                        }
                    }
                }
            }
            SettingsRow {
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 1
                width: parent.width
                height: 34
                spacing: 8
                label: "Основной шрифт плеера"
                labelWidth: 210

                SettingsFontField {
                    width: 178
                    height: 30
                    compact: true
                    fieldWidth: 140
                    fieldFontSize: 11
                    value: Config.playerFont
                    targetObject: Config
                    targetProperty: "playerFont"
                    settingsObject: settings
                    saveOnEdit: true
                }
            }
            SettingsRow {
                label: "Размер текста"
                labelWidth: 210
                width: parent.width
                height: 30
                spacing: 8
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 1
                SettingsNumberField {
            id: silenceSizeField
            width: 72
            height: 30
            value: Config.playerSilenceFontSize
            minimum: 8
            maximum: 100
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerSilenceFontSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
            SettingsRow {
                label: "Размер длинного текста"
                labelWidth: 210
                width: parent.width
                height: 30
                spacing: 8
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 1
                SettingsNumberField {
            id: silenceLongSizeField
            width: 72
            height: 30
            value: Config.playerSilenceLongFontSize
            minimum: 8
            maximum: 100
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerSilenceLongFontSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
            SettingsRow {
                label: "Ширина области"
                labelWidth: 210
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 1
                width: parent.width
                height: 30
                spacing: 8
                SettingsNumberField {
            id: playerSilenceWidthField
            width: 72
            height: 30
            value: Config.playerSilenceWidth
            minimum: 100
            maximum: 600
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerSilenceWidth"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
            SettingsRow {
                label: "Цвет обводки"
                labelWidth: 210
                width: parent.width
                height: 30
                spacing: 8
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 1
                SettingsColorField {
                    width: 120
                    height: 30
                    value: Config.playerSilenceOutlineColor
                    targetObject: Config
                    targetProperty: "playerSilenceOutlineColor"
                    settingsObject: root.settings
                    saveOnEdit: true
                    allowAlpha: false
                    allowTransparent: false
                    compact: true
                    fieldWidth: 88
                    swatchSize: 24
                }
            }
            SettingsRow {
                label: "Толщина обводки"
                labelWidth: 210
                width: parent.width
                height: 30
                spacing: 8
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 1
                SettingsNumberField {
                    id: playerSilenceOutlineWidthField
                    width: 100
                    height: 30
                    value: Config.playerSilenceOutlineWidth
                    minimum: 0
                    maximum: 4
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 72
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhDigitsOnly
                    targetObject: Config
                    targetProperty: "playerSilenceOutlineWidth"
                    settingsObject: root.settings
                    saveOnEdit: true
                }
            }
    }
    SettingsGroup {
        id: playerPrioritySettingsGroup
                visible: host && host.currentPageId === "player" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["playerPriority"] })
        padding: 8
        contentSpacing: 6

            Text {
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 0
                text: "Приоритет проигрывателей"
                color: Config.settingsSubheading
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(12)
            }
            SettingsDescription {
                descriptionConditionVisible: host.currentPageId === "player" && host.currentPageSubTabIndex === 0
                text: "Первый включённый backend в списке, который сейчас доступен, используется плеером. Отключённые backend пропускаются."
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(9)
                wrapMode: Text.WordWrap
                width: parent.width
            }
            Column {
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 0
                width: parent.width
                spacing: 5

                Repeater {
                    id: playerPriorityRepeater
                    model: playerPriorityModel

                    delegate: Row {
                        id: playerPriorityRow
                        Behavior on y { NumberAnimation { duration: Config.animationDuration(190, "appearance"); easing.type: Easing.OutCubic } }
                        property Item reorderTargetItem: playerPriorityRow
                        width: parent ? parent.width : 0
                        height: 30
                        spacing: 6

                        Text {
                            width: 24
                            height: 30
                            text: "#" + (index + 1)
                            color: Config.textMuted
                            font.family: Config.settingsFontFamily
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        SettingsCheckBox {
                            width: 28
                            height: 30
                            indicatorOnly: true
                            checked: model.enabled
                            onToggled: root.togglePlayerPriority(index, checked)
                        }

                        Text {
                            width: 170
                            height: 30
                            text: model.label
                            color: model.enabled ? Config.text : Config.textDisabled
                            font.family: Config.settingsFontFamily
                            font.pixelSize: Config.settingsUiSize(11)
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        Item { width: Math.max(0, parent.width - 24 - 28 - 170 - 24 - 26); height: 30 }

                        DragReorderHandle {
                            width: 26
                            height: 26
                            listRepeater: playerPriorityRepeater
                            dropIndicatorHost: playerPrioritySettingsGroup
                            itemIndex: index
                            accessibleLabel: model.label
                            onReorderRequested: function(fromIndex, toIndex) {
                                root.movePlayerPriorityTo(fromIndex, toIndex)
                            }
                        }
                    }
                }
            }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "player" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["playerTimeFont", "playerTimeFontSize", "playerTimeRightPadding", "playerTimeY"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
                label: "Размер"
                labelWidth: 210
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 2
                width: parent.width
                height: 30
                spacing: 8
                SettingsNumberField {
            id: playerTimeFontSizeField
            width: 72
            height: 30
            value: Config.playerTimeFontSize
            minimum: 8
            maximum: 48
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerTimeFontSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
            SettingsRow {
                label: "Шрифт"
                labelWidth: 210
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 2
                width: parent.width
                height: 30
                spacing: 8
                SettingsFontField {
                    width: 178
                    height: 30
                    compact: true
                    fieldWidth: 140
                    fieldFontSize: 11
                    value: Config.playerTimeFont
                    targetObject: Config
                    targetProperty: "playerTimeFont"
                    settingsObject: settings
                    saveOnEdit: true
                }
            }
            SettingsRow {
                label: "Смещение по Y"
                labelWidth: 210
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 2
                width: parent.width
                height: 30
                spacing: 8
                SettingsNumberField {
                    id: playerTimeYField
                    width: 72
                    height: 30
                    value: Config.playerTimeY
                    minimum: -100
                    maximum: 100
                    step: 1
                    wheelStep: 1
                    decimals: 0
                    compact: true
                    fieldWidth: 72
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    targetObject: Config
                    targetProperty: "playerTimeY"
                    settingsObject: root.settings
                    saveOnEdit: true
                }
            }
            SettingsRow {
                label: "Отступ справа"
                labelWidth: 210
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 2
                width: parent.width
                height: 30
                spacing: 8
                SettingsNumberField {
            id: playerTimeRightPaddingField
            width: 72
            height: 30
            value: Config.playerTimeRightPadding
            minimum: 0
            maximum: 100
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerTimeRightPadding"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "player" && host.currentPageSubTabIndex === 3
settingsSearchSubTabIndex: 3
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["playerBoldArtist", "playerMetaFont", "playerMetaFontSize", "playerMetaLineSpacing", "playerMetaSecondaryFontSize", "playerMetadataXPadding", "playerMetadataY", "playerTextOutlineColor", "playerTextOutlineEnabled"] })
        padding: 8
        contentSpacing: 6

        Row {
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 3
                width: parent.width
                height: 34
                spacing: 8

                Text {
                    width: 210
                    height: 30
                    text: "Шрифт метаданных плеера"
                    color: Config.text
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                }

                SettingsFontField {
                    width: 178
                    height: 30
                    compact: true
                    fieldWidth: 140
                    fieldFontSize: 11
                    value: Config.playerMetaFont
                    targetObject: Config
                    targetProperty: "playerMetaFont"
                    settingsObject: settings
                    saveOnEdit: true
                }
            }
            SettingsRow {
                label: "Размер основной строки метаданных"
                labelWidth: 210
                width: parent.width; height: 30; spacing: 8
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 3
                SettingsNumberField {
            id: metaSizeField
            width: 72
            height: 30
            value: Config.playerMetaFontSize
            minimum: 8
            maximum: 48
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerMetaFontSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
            SettingsRow {
                label: "Размер остальных строк"
                labelWidth: 210
                width: parent.width; height: 30; spacing: 8
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 3
                SettingsNumberField {
            id: metaSecondarySizeField
            width: 72
            height: 30
            value: Config.playerMetaSecondaryFontSize
            minimum: 8
            maximum: 48
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerMetaSecondaryFontSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
            SettingsRow {
                label: "Расстояние между строками"
                labelWidth: 210
                width: parent.width; height: 30; spacing: 8
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 3
                SettingsNumberField {
            id: metaSpacingField
            width: 72
            height: 30
            value: Config.playerMetaLineSpacing
            minimum: 0
            maximum: 100
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerMetaLineSpacing"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
            SettingsRow {
                label: "Отступ метаданных по X"
                labelWidth: 210
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 3
                width: parent.width
                height: 30
                spacing: 8
                SettingsNumberField {
            id: playerMetaXPadField
            width: 72
            height: 30
            value: Config.playerMetadataXPadding
            minimum: 0
            maximum: 100
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerMetadataXPadding"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
            SettingsRow {
                label: "Положение метаданных по Y"
                labelWidth: 210
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 3
                width: parent.width
                height: 30
                spacing: 8
                SettingsNumberField {
            id: playerMetaYField
            width: 72
            height: 30
            value: Config.playerMetadataY
            minimum: 0
            maximum: 100
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 72
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerMetadataY"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
            Row { width: parent.width; height: 30; spacing: 8
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 3
                SettingsCheckBox { id: boldArtistBox; width: 210; height: 30; text: "Жирный исполнитель"; checked: Config.playerBoldArtist; onToggled: { Config.playerBoldArtist=checked; settings.save() } }
            }
            Row {
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 3
                width: parent.width
                height: 30
                spacing: 8
                SettingsCheckBox {
                    id: playerTextOutlineBox
                    width: 210
                    height: 30
                    text: "Обводка текста"
                    checked: Config.playerTextOutlineEnabled
                    onToggled: { Config.playerTextOutlineEnabled = checked; settings.save() }
                }
            }
            MorphGeometry {
                id: playerTextOutlineColorMorph
                width: parent.width
                enabled: Config.playerTextOutlineEnabled
                clip: true
                visible: Config.playerTextOutlineEnabled || normalizedProgress > 0.001
                fromGeometry: Qt.rect(0, 0, parent.width, 0)
                toGeometry: Qt.rect(0, 0, parent.width, playerTextOutlineColorContent.implicitHeight)
                progress: Config.playerTextOutlineEnabled ? 1 : 0
                animationDuration: Config.animationDuration(180, "appearance")
                animationEasing: Config.animationEasingType("ease-out", Config.playerTextOutlineEnabled ? "enter" : "exit")

                Column {
                    id: playerTextOutlineColorContent
                    width: parent.width
                    spacing: 6

                    SettingsRow {
                        label: "Цвет обводки"
                        labelWidth: 210
                        width: parent.width
                        height: 30
                        spacing: 8
                        SettingsColorField {
                            id: playerTextOutlineColorField
                            width: 120
                            height: 30
                            value: Config.playerTextOutlineColor
                            targetObject: Config
                            targetProperty: "playerTextOutlineColor"
                            settingsObject: settings
                            saveOnEdit: true
                            allowAlpha: false
                            allowTransparent: false
                            compact: true
                            fieldWidth: 88
                            swatchSize: 24
                        }
                    }
                }
            }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "player" && host.currentPageSubTabIndex === 4
settingsSearchSubTabIndex: 4
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["playerNextIcon", "playerNextIconSize", "playerNextIconY", "playerPausedIcon", "playerPausedIconSize", "playerPausedIconY", "playerPlayingIcon", "playerPlayingIconSize", "playerPlayingIconY"] })
        padding: 8
        contentSpacing: 6

            Text { visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 4; text: "Иконки и управление"; color: Config.settingsSubheading; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10) }
            Column {
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 4
                width: parent.width
                spacing: 4
                Row {
                    width: parent.width
                    height: 18
                    spacing: 8
                    Text { width: 58; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
                    Text { width: 58; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
                    Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
                }
                Row {
                    width: parent.width
                    height: 30
                    spacing: 8
                    SettingsTextField { id: playerPlayingIconField; width: 58; height: 30; text: Config.playerPlayingIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: "transparent"; border.color: (playerPlayingIconField.activeFocus || playerPlayingIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || playerPlayingIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) } onEditingFinished: { Config.playerPlayingIcon=text; settings.save() } Connections { target: Config; function onPlayerPlayingIconChanged(){playerPlayingIconField.text=Config.playerPlayingIcon} } }
                    SettingsNumberField {
            id: playerPlayingIconSizeField
            width: 58
            height: 30
            value: Config.playerPlayingIconSize
            minimum: 8
            maximum: 64
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerPlayingIconSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
                    SettingsNumberField {
            id: playerPlayingIconYField
            width: 58
            height: 30
            value: Config.playerPlayingIconY
            minimum: -100
            maximum: 100
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "playerPlayingIconY"
            settingsObject: root.settings
            saveOnEdit: true
        }
                }
                Row {
                    width: parent.width
                    height: 30
                    spacing: 8
                    SettingsTextField { id: playerPausedIconField; width: 58; height: 30; text: Config.playerPausedIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: "transparent"; border.color: (playerPausedIconField.activeFocus || playerPausedIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || playerPausedIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) } onEditingFinished: { Config.playerPausedIcon=text; settings.save() } Connections { target: Config; function onPlayerPausedIconChanged(){playerPausedIconField.text=Config.playerPausedIcon} } }
                    SettingsNumberField {
            id: playerPausedIconSizeField
            width: 58
            height: 30
            value: Config.playerPausedIconSize
            minimum: 8
            maximum: 64
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerPausedIconSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
                    SettingsNumberField {
            id: playerPausedIconYField
            width: 58
            height: 30
            value: Config.playerPausedIconY
            minimum: -100
            maximum: 100
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "playerPausedIconY"
            settingsObject: root.settings
            saveOnEdit: true
        }
                }
                Row {
                    width: parent.width
                    height: 30
                    spacing: 8
                    SettingsTextField { id: playerNextIconField; width: 58; height: 30; text: Config.playerNextIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: "transparent"; border.color: (playerNextIconField.activeFocus || playerNextIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || playerNextIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) } onEditingFinished: { Config.playerNextIcon=text; settings.save() } Connections { target: Config; function onPlayerNextIconChanged(){playerNextIconField.text=Config.playerNextIcon} } }
                    SettingsNumberField {
            id: playerNextIconSizeField
            width: 58
            height: 30
            value: Config.playerNextIconSize
            minimum: 8
            maximum: 64
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "playerNextIconSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
                    SettingsNumberField {
            id: playerNextIconYField
            width: 58
            height: 30
            value: Config.playerNextIconY
            minimum: -100
            maximum: 100
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 58
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "playerNextIconY"
            settingsObject: root.settings
            saveOnEdit: true
        }
                }
            }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "player" && host.currentPageSubTabIndex === 5
settingsSearchSubTabIndex: 5
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["playerShowProgress", "playerProgressTrackHeight", "playerProgressTrackOffsetY", "playerProgressY"], nested: { colors: ["playerProgressFill", "playerProgressTrack"] } })
        padding: 8
        contentSpacing: 6

        Row { width: parent.width; height: 30; spacing: 8
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 5
                SettingsCheckBox { id: showProgressBox; width: 210; height: 30; text: "Показывать прогресс"; checked: Config.playerShowProgress; onToggled: { Config.playerShowProgress=checked; settings.save() } }
            }
        MorphGeometry {
            id: playerProgressOptionsMorph
            width: parent.width
            enabled: Config.playerShowProgress
            clip: true
            visible: Config.playerShowProgress || normalizedProgress > 0.001
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, playerProgressOptionsContent.implicitHeight)
            progress: Config.playerShowProgress ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("ease-out", Config.playerShowProgress ? "enter" : "exit")

            Column {
                id: playerProgressOptionsContent
                width: parent.width
                spacing: 6

                Row {
                    visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 5
                    width: parent.width
                    height: 24
                    spacing: 8
                    Item { width: 210; height: 24 }
                    Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Text { width: 58; text: "Высота"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Text { width: 58; text: "Смещение"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Row {
                    visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 5
                    width: parent.width
                    height: 30
                    spacing: 8
                    Item { width: 210; height: 30 }
                    SettingsNumberField {
                        compact: true
                        value: Config.playerProgressY
                        minimum: 0
                        maximum: 100
                        step: 1
                        fieldWidth: 72
                        onValueEdited: function(value) {
                            Config.playerProgressY = value
                            settings.save()
                        }
                    }
                    SettingsNumberField {
                        compact: true
                        value: Config.playerProgressTrackHeight
                        minimum: 1
                        maximum: 20
                        step: 1
                        fieldWidth: 72
                        onValueEdited: function(value) {
                            Config.playerProgressTrackHeight = value
                            settings.save()
                        }
                    }
                    SettingsNumberField {
                        compact: true
                        value: Config.playerProgressTrackOffsetY
                        minimum: -10
                        maximum: 20
                        step: 1
                        fieldWidth: 72
                        onValueEdited: function(value) {
                            Config.playerProgressTrackOffsetY = value
                            settings.save()
                        }
                    }
                }
                SettingsColorField {
                    width: parent.width
                    label: "Цвет дорожки"
                    value: String(Config.playerProgressTrack)
                    targetObject: Config
                    targetProperty: "playerProgressTrack"
                    settingsObject: root.settings
                    saveOnEdit: true
                    allowAlpha: true
                    allowTransparent: true
                    labelWidth: 210
                    fieldWidth: 120
                }
                SettingsColorField {
                    width: parent.width
                    label: "Цвет заполнения"
                    value: String(Config.playerProgressFill)
                    targetObject: Config
                    targetProperty: "playerProgressFill"
                    settingsObject: root.settings
                    saveOnEdit: true
                    allowAlpha: true
                    allowTransparent: true
                    labelWidth: 210
                    fieldWidth: 120
                }
            }
        }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "player" && host.currentPageSubTabIndex === 6
settingsSearchSubTabIndex: 6
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["playerCoverOpacity"], nested: { colors: ["playerOverlay"] } })
        padding: 8
        contentSpacing: 6

            SettingsRow {
                label: "Прозрачность обложки (0–1)"
                labelWidth: 210
                visible: host.currentPageId === "player" && host.currentPageSubTabIndex === 6
                width: parent.width
                height: 30
                spacing: 8
                SettingsNumberField {
                    id: playerCoverOpacityField
                    width: 72
                    height: 30
                    value: Config.playerCoverOpacity
                    minimum: 0
                    maximum: 1
                    step: 0.05
                    wheelStep: 0.05
                    decimals: 2
                    compact: true
                    fieldWidth: 72
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    targetObject: Config
                    targetProperty: "playerCoverOpacity"
                    settingsObject: root.settings
                    saveOnEdit: true
                }
            }
    }
}
