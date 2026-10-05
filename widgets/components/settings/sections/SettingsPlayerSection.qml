import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

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
        var target = index + delta
        if (index < 0 || index >= playerPriorityModel.count || target < 0 || target >= playerPriorityModel.count)
            return
        playerPriorityModel.move(index, target, 1)
        root.savePlayerPriority()
    }

    Connections {
        target: Config
        function onPlayerPriorityChanged() { root.syncPlayerPriorityModel() }
    }

    Component.onCompleted: root.syncPlayerPriorityModel()

    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        text: "Плеер"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        width: parent.width
        height: 34
        spacing: 8

        Text {
            width: 210
            text: "Текст при отсутствии воспроизведения"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        SettingsTextField {
            id: playerSilenceField
            width: 140
            height: 30
            text: Config.playerSilenceText
            color: Config.text
            selectionColor: Config.accent
            selectedTextColor: Config.black
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            activeFocusOnTab: true
            background: Rectangle {
                color: Config.settingsBackground
                border.color: (playerSilenceField.activeFocus || playerSilenceField.pointerHovered) ? Config.accent : Config.baseColor
                border.width: 1
                radius: 4
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
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        width: parent.width
        height: 34
        spacing: 8

        Text {
            width: 210
            text: "Основной шрифт плеера"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }

        SettingsTextField {
            id: playerFontField
            width: 140
            height: 30
            text: Config.playerFont
            color: Config.text
            selectionColor: Config.accent
            selectedTextColor: Config.black
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            activeFocusOnTab: true
            background: Rectangle {
                color: Config.settingsBackground
                border.color: (playerFontField.activeFocus || playerFontField.pointerHovered) ? Config.accent : Config.baseColor
                border.width: 1
                radius: 4
            }
            onEditingFinished: {
                Config.playerFont = text
                settings.save()
            }
            Connections {
                target: Config
                function onPlayerFontChanged() {
                    playerFontField.text = Config.playerFont
                }
            }
        }
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        Text { width: 210; text: "Размер текста Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        Text { width: 210; text: "Размер длинного Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Ширина области Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        text: "Оставшееся время"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Размер оставшегося времени"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Шрифт оставшегося времени"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: playerTimeFontField; width: 140; height: 30; text: Config.playerTimeFont; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerTimeFontField.activeFocus || playerTimeFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { var v=text.trim(); if (v.length > 0) Config.playerTimeFont=v; text=Config.playerTimeFont; settings.save() }
            Connections { target: Config; function onPlayerTimeFontChanged() { playerTimeFontField.text=Config.playerTimeFont } }
        }
    }
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Отступ оставшегося времени справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 2
        text: "Метаданные"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        width: parent.width
        height: 34
        spacing: 8

        Text {
            width: 210
            text: "Шрифт метаданных плеера"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }

        SettingsTextField {
            id: playerMetaFontField
            width: 140
            height: 30
            text: Config.playerMetaFont
            color: Config.text
            selectionColor: Config.accent
            selectedTextColor: Config.black
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            activeFocusOnTab: true
            background: Rectangle {
                color: Config.settingsBackground
                border.color: (playerMetaFontField.activeFocus || playerMetaFontField.pointerHovered) ? Config.accent : Config.baseColor
                border.width: 1
                radius: 4
            }
            onEditingFinished: {
                Config.playerMetaFont = text
                settings.save()
            }
            Connections {
                target: Config
                function onPlayerMetaFontChanged() {
                    playerMetaFontField.text = Config.playerMetaFont
                }
            }
        }
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        Text { width: 210; text: "Размер основной строки метаданных"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
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
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        Text { width: 210; text: "Размер остальных строк"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Отступ метаданных по X"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Положение метаданных по Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        SettingsCheckBox { id: boldArtistBox; width: 210; height: 30; text: "Жирный исполнитель"; checked: Config.playerBoldArtist; onToggled: { Config.playerBoldArtist=checked; settings.save() } }
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
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
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3 && Config.playerTextOutlineEnabled
        width: parent.width
        height: 30
        spacing: 8
        Text {
            width: 210
            text: "Цвет обводки"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }
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
    Text { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 4; text: "Иконки и управление"; color: Config.settingsSubheading; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
    Column {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 4
        width: parent.width
        spacing: 4
        Row {
            width: parent.width
            height: 18
            spacing: 8
            Text { width: 58; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
        }
        Row {
            width: parent.width
            height: 30
            spacing: 8
            SettingsTextField { id: playerPlayingIconField; width: 58; height: 30; text: Config.playerPlayingIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerPlayingIconField.activeFocus || playerPlayingIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.playerPlayingIcon=text; settings.save() } Connections { target: Config; function onPlayerPlayingIconChanged(){playerPlayingIconField.text=Config.playerPlayingIcon} } }
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
            SettingsTextField { id: playerPausedIconField; width: 58; height: 30; text: Config.playerPausedIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerPausedIconField.activeFocus || playerPausedIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.playerPausedIcon=text; settings.save() } Connections { target: Config; function onPlayerPausedIconChanged(){playerPausedIconField.text=Config.playerPausedIcon} } }
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
            SettingsTextField { id: playerNextIconField; width: 58; height: 30; text: Config.playerNextIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerNextIconField.activeFocus || playerNextIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.playerNextIcon=text; settings.save() } Connections { target: Config; function onPlayerNextIconChanged(){playerNextIconField.text=Config.playerNextIcon} } }
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
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 4
        text: "Полоска прогресса"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5
        SettingsCheckBox { id: showProgressBox; width: 210; height: 30; text: "Показывать прогресс"; checked: Config.playerShowProgress; onToggled: { Config.playerShowProgress=checked; settings.save() } }
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5
        width: parent.width
        height: 24
        spacing: 8
        Item { width: 210; height: 24 }
        Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Text { width: 58; text: "Высота"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Text { width: 58; text: "Смещение"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5
        width: parent.width
        height: 30
        spacing: 8
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
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Прозрачность обложки (0–1)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5
        text: "Обложка и фон"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 6
        width: parent.width
        height: 30
        spacing: 8
        SettingsCheckBox {
            id: playerBlurEnabledBox
            width: 210
            height: 30
            text: "Блюр фона плеера"
            checked: Config.playerBlurEnabled
            onToggled: { Config.playerBlurEnabled = checked; settings.save() }
           
        }
    }
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 6
        text: "Размывает содержимое позади плеера; сила блюра задаётся композитором Niri."
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(9)
        wrapMode: Text.WordWrap
        width: parent.width
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 6
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Радиус области блюра (0–40)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
    id: playerBlurRadiusField
    width: 72
    height: 30
    value: Config.playerBlurRadius
    minimum: 0
    maximum: 40
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 72
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "playerBlurRadius"
    settingsObject: root.settings
    saveOnEdit: true
}
    }

    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 7
        text: "Приоритет проигрывателей"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(12)
    }
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 7
        text: "Первый включённый backend в списке, который сейчас доступен, используется плеером. Отключённые backend пропускаются."
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(9)
        wrapMode: Text.WordWrap
        width: parent.width
    }
    Column {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 7
        width: parent.width
        spacing: 5

        Repeater {
            model: playerPriorityModel

            delegate: Row {
                width: parent ? parent.width : 0
                height: 30
                spacing: 6

                Text {
                    width: 24
                    height: 30
                    text: "#" + (index + 1)
                    color: Config.textMuted
                    font.family: Config.settingsFont
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
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                Item { width: Math.max(0, parent.width - 24 - 28 - 170 - 18 - 56); height: 30 }

                SettingsButton {
                    width: 26
                    height: 26
                    text: "↑"
                    enabled: index > 0
                    tooltip: "Поднять выше"
                    onClicked: root.movePlayerPriority(index, -1)
                }

                SettingsButton {
                    width: 26
                    height: 26
                    text: "↓"
                    enabled: index < playerPriorityModel.count - 1
                    tooltip: "Опустить ниже"
                    onClicked: root.movePlayerPriority(index, 1)
                }
            }
        }
    }
}
