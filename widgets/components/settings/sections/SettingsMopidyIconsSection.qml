import QtQuick
import QtQuick.Controls
import "../primitives"
import "../../.."

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0
    visible: host && host.currentOtherTab === 10 && host.currentOtherSubTab === 2

    function normalizedTopIconOrder() {
        var allowed = ["stop", "shuffle", "repeat", "volume", "refresh", "openAdd", "clear"]
        var raw = String(Config.mopidyTopIconOrder || "").split(",")
        var out = []
        for (var i = 0; i < raw.length; ++i) {
            var id = String(raw[i] || "")
            if (allowed.indexOf(id) >= 0 && out.indexOf(id) < 0) out.push(id)
        }
        for (var j = 0; j < allowed.length; ++j)
            if (out.indexOf(allowed[j]) < 0) out.push(allowed[j])
        return out
    }

    function topIconLabel(id) {
        switch (id) {
        case "stop": return "Стоп"
        case "shuffle": return "Перемешать"
        case "repeat": return "Повтор"
        case "volume": return "Громкость"
        case "refresh": return "Обновить"
        case "openAdd": return "Открыть добавление"
        case "clear": return "Очистить"
        }
        return id
    }

    Row {
        width: parent.width
        height: 30
        spacing: 8
        Text {
            width: 220
            text: "Скрывать верхнюю панель иконок"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }
        SettingsCheckBox {
            id: hideTopPanelCheckBox
            width: 58
            height: 30
            indicatorOnly: true
            checked: Config.mopidyHideTopPanel
            onClicked: { Config.mopidyHideTopPanel = checked; settings.save() }
            Connections { target: Config; function onMopidyHideTopPanelChanged() { hideTopPanelCheckBox.checked = Config.mopidyHideTopPanel } }
        }
    }

    Row {
        width: parent.width
        height: 30
        spacing: 8
        Text {
            width: 220
            text: "Высота области наведения"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }
        SettingsNumberField {
            width: 88; height: 30
            value: Config.mopidyTopPanelHoverHeight
            minimum: 4; maximum: 24; step: 1; wheelStep: 1; decimals: 0
            compact: true; fieldWidth: 88; fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config; targetProperty: "mopidyTopPanelHoverHeight"
            settingsObject: root.settings; saveOnEdit: true
        }
    }

    Row {
        width: parent.width
        height: 30
        spacing: 8
        Text {
            width: 220
            text: "Отступ сверху (Y)"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }
        SettingsNumberField {
            width: 88; height: 30
            value: Config.mopidyTopPanelOffsetY
            minimum: -24; maximum: 24; step: 1; wheelStep: 1; decimals: 0
            compact: true; fieldWidth: 88; fieldFontSize: 11
            inputMethodHints: Qt.ImhNone
            targetObject: Config; targetProperty: "mopidyTopPanelOffsetY"
            settingsObject: root.settings; saveOnEdit: true
        }
    }

    Text {
        text: "Порядок верхней панели"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
        topPadding: 4
    }

    Text {
        text: "Порядок применяется слева направо. Стрелки меняют только положение иконок, их настройки и действия не меняются."
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(9)
        wrapMode: Text.WordWrap
        width: parent.width
    }

    Column {
        id: orderColumn
        width: parent.width
        spacing: 4
        property var orderIds: root.normalizedTopIconOrder()

        function saveOrder(nextOrder) {
            orderIds = nextOrder.slice(0)
            Config.mopidyTopIconOrder = orderIds.join(",")
            root.settings.save()
        }

        function moveItem(index, delta) {
            var next = orderIds.slice(0)
            var target = index + delta
            if (target < 0 || target >= next.length) return
            var item = next[index]
            next.splice(index, 1)
            next.splice(target, 0, item)
            saveOrder(next)
        }

        Repeater {
            model: parent.orderIds
            delegate: Row {
                width: parent.width
                height: 28
                spacing: 5

                Text {
                    width: 150
                    height: 28
                    text: root.topIconLabel(modelData)
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                }

                SettingsButton {
                    width: 32
                    height: 28
                    text: "↑"
                    fontSize: 11
                    enabled: index > 0
                    fillOnHover: true
                    backgroundColor: Config.settingsBackground
                    hoverBackgroundColor: Config.baseColor
                    textColor: Config.text
                    hoverTextColor: Config.text
                    onClicked: orderColumn.moveItem(index, -1)
                }

                SettingsButton {
                    width: 32
                    height: 28
                    text: "↓"
                    fontSize: 11
                    enabled: index < orderColumn.orderIds.length - 1
                    fillOnHover: true
                    backgroundColor: Config.settingsBackground
                    hoverBackgroundColor: Config.baseColor
                    textColor: Config.text
                    hoverTextColor: Config.text
                    onClicked: orderColumn.moveItem(index, 1)
                }
            }
        }

        SettingsButton {
            width: 125
            height: 28
            text: "По умолчанию"
            fontSize: 10
            fillOnHover: true
            backgroundColor: Config.settingsBackground
            hoverBackgroundColor: Config.baseColor
            textColor: Config.text
            hoverTextColor: Config.text
            onClicked: orderColumn.saveOrder(["stop", "shuffle", "repeat", "volume", "refresh", "openAdd", "clear"])
        }
    }

    SettingsColorField {
        width: parent.width
        height: 30
        label: "Общий цвет иконок"
        value: Config.mopidyControlIconColor
        targetObject: Config
        targetProperty: "mopidyControlIconColor"
        settingsObject: root.settings
        saveOnEdit: true
        allowAlpha: true
        allowTransparent: true
        fieldWidth: 120
        fieldHeight: 30
    }

    Row {
        width: parent.width
        height: 22
        spacing: 6
        Text { width: 82; text: ""; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
        Text { width: 58; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
        Text { width: 58; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
        Text { width: 58; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
        Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
        Text { width: 58; text: "Показывать"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Стоп"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: stopIconField; width: 58; height: 30; text: Config.mopidyStopIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (stopIconField.activeFocus || stopIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyStopIcon = text; text = Config.mopidyStopIcon; settings.save() }
            Connections { target: Config; function onMopidyStopIconChanged() { stopIconField.text = Config.mopidyStopIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyStopIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyStopIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyStopIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyStopIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyStopIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyStopIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: stopVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowStopIcon
            onClicked: { Config.mopidyShowStopIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowStopIconChanged() { stopVisibilityCheckBox.checked = Config.mopidyShowStopIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Обновить"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: refreshIconField; width: 58; height: 30; text: Config.mopidyRefreshIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (refreshIconField.activeFocus || refreshIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyRefreshIcon = text; text = Config.mopidyRefreshIcon; settings.save() }
            Connections { target: Config; function onMopidyRefreshIconChanged() { refreshIconField.text = Config.mopidyRefreshIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyRefreshIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyRefreshIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyRefreshIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyRefreshIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyRefreshIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyRefreshIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: refreshVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowRefreshIcon
            onClicked: { Config.mopidyShowRefreshIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowRefreshIconChanged() { refreshVisibilityCheckBox.checked = Config.mopidyShowRefreshIcon } }
        }
    }


    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Открыть добавление"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: openAddIconField; width: 58; height: 30; text: Config.mopidyOpenAddIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (openAddIconField.activeFocus || openAddIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyOpenAddIcon = text; text = Config.mopidyOpenAddIcon; settings.save() }
            Connections { target: Config; function onMopidyOpenAddIconChanged() { openAddIconField.text = Config.mopidyOpenAddIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyOpenAddIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyOpenAddIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyOpenAddIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyOpenAddIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyOpenAddIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyOpenAddIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: openAddVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowOpenAddIcon
            onClicked: { Config.mopidyShowOpenAddIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowOpenAddIconChanged() { openAddVisibilityCheckBox.checked = Config.mopidyShowOpenAddIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Добавить элемент"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: addIconField; width: 58; height: 30; text: Config.mopidyAddIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (addIconField.activeFocus || addIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyAddIcon = text; text = Config.mopidyAddIcon; settings.save() }
            Connections { target: Config; function onMopidyAddIconChanged() { addIconField.text = Config.mopidyAddIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyAddIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyAddIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyAddIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyAddIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyAddIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyAddIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: addVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowAddIcon
            onClicked: { Config.mopidyShowAddIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowAddIconChanged() { addVisibilityCheckBox.checked = Config.mopidyShowAddIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Shuffle"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: shuffleIconField; width: 58; height: 30; text: Config.mopidyShuffleIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (shuffleIconField.activeFocus || shuffleIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyShuffleIcon = text; text = Config.mopidyShuffleIcon; settings.save() }
            Connections { target: Config; function onMopidyShuffleIconChanged() { shuffleIconField.text = Config.mopidyShuffleIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyShuffleIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyShuffleIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyShuffleIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyShuffleIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyShuffleIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyShuffleIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: shuffleVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowShuffleIcon
            onClicked: { Config.mopidyShowShuffleIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowShuffleIconChanged() { shuffleVisibilityCheckBox.checked = Config.mopidyShowShuffleIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Repeat"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: repeatIconField; width: 58; height: 30; text: Config.mopidyRepeatIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (repeatIconField.activeFocus || repeatIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyRepeatIcon = text; text = Config.mopidyRepeatIcon; settings.save() }
            Connections { target: Config; function onMopidyRepeatIconChanged() { repeatIconField.text = Config.mopidyRepeatIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyRepeatIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyRepeatIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyRepeatIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyRepeatIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyRepeatIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyRepeatIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: repeatVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowRepeatIcon
            onClicked: { Config.mopidyShowRepeatIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowRepeatIconChanged() { repeatVisibilityCheckBox.checked = Config.mopidyShowRepeatIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Переключить плейлист"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap }
        SettingsTextField {
            id: switchPlaylistIconField; width: 58; height: 30; text: Config.mopidySwitchPlaylistIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (switchPlaylistIconField.activeFocus || switchPlaylistIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidySwitchPlaylistIcon = text; text = Config.mopidySwitchPlaylistIcon; settings.save() }
            Connections { target: Config; function onMopidySwitchPlaylistIconChanged() { switchPlaylistIconField.text = Config.mopidySwitchPlaylistIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidySwitchPlaylistIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidySwitchPlaylistIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidySwitchPlaylistIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidySwitchPlaylistIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidySwitchPlaylistIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidySwitchPlaylistIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: switchPlaylistVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowSwitchPlaylistIcon
            onClicked: { Config.mopidyShowSwitchPlaylistIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowSwitchPlaylistIconChanged() { switchPlaylistVisibilityCheckBox.checked = Config.mopidyShowSwitchPlaylistIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Удаление плейлистов/треков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap }
        SettingsTextField {
            id: playlistDeleteIconField; width: 58; height: 30; text: Config.mopidyPlaylistDeleteIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (playlistDeleteIconField.activeFocus || playlistDeleteIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyPlaylistDeleteIcon = text; text = Config.mopidyPlaylistDeleteIcon; settings.save() }
            Connections { target: Config; function onMopidyPlaylistDeleteIconChanged() { playlistDeleteIconField.text = Config.mopidyPlaylistDeleteIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyPlaylistDeleteIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyPlaylistDeleteIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyPlaylistDeleteIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyPlaylistDeleteIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyPlaylistDeleteIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyPlaylistDeleteIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: playlistDeleteVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowPlaylistDeleteIcon
            onClicked: { Config.mopidyShowPlaylistDeleteIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowPlaylistDeleteIconChanged() { playlistDeleteVisibilityCheckBox.checked = Config.mopidyShowPlaylistDeleteIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Вверх"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: moveUpIconField; width: 58; height: 30; text: Config.mopidyMoveUpIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (moveUpIconField.activeFocus || moveUpIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyMoveUpIcon = text; text = Config.mopidyMoveUpIcon; settings.save() }
            Connections { target: Config; function onMopidyMoveUpIconChanged() { moveUpIconField.text = Config.mopidyMoveUpIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyMoveUpIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyMoveUpIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyMoveUpIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyMoveUpIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyMoveUpIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyMoveUpIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: moveUpVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowMoveUpIcon
            onClicked: { Config.mopidyShowMoveUpIcon = checked; Config.mopidyShowMoveButtons = Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon; settings.save() }
            Connections { target: Config; function onMopidyShowMoveUpIconChanged() { moveUpVisibilityCheckBox.checked = Config.mopidyShowMoveUpIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Вниз"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: moveDownIconField; width: 58; height: 30; text: Config.mopidyMoveDownIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (moveDownIconField.activeFocus || moveDownIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyMoveDownIcon = text; text = Config.mopidyMoveDownIcon; settings.save() }
            Connections { target: Config; function onMopidyMoveDownIconChanged() { moveDownIconField.text = Config.mopidyMoveDownIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyMoveDownIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyMoveDownIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyMoveDownIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyMoveDownIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyMoveDownIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyMoveDownIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: moveDownVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowMoveDownIcon
            onClicked: { Config.mopidyShowMoveDownIcon = checked; Config.mopidyShowMoveButtons = Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon; settings.save() }
            Connections { target: Config; function onMopidyShowMoveDownIconChanged() { moveDownVisibilityCheckBox.checked = Config.mopidyShowMoveDownIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Громкость"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: volumeIconField; width: 58; height: 30; text: Config.mopidyVolumeIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (volumeIconField.activeFocus || volumeIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyVolumeIcon = text; text = Config.mopidyVolumeIcon; settings.save() }
            Connections { target: Config; function onMopidyVolumeIconChanged() { volumeIconField.text = Config.mopidyVolumeIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyVolumeIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyVolumeIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyVolumeIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyVolumeIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyVolumeIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyVolumeIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: volumeVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowVolumeIcon
            onClicked: { Config.mopidyShowVolumeIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowVolumeIconChanged() { volumeVisibilityCheckBox.checked = Config.mopidyShowVolumeIcon } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Mute"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: mutedIconField; width: 58; height: 30; text: Config.mopidyMutedIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (mutedIconField.activeFocus || mutedIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyMutedIcon = text; text = Config.mopidyMutedIcon; settings.save() }
            Connections { target: Config; function onMopidyMutedIconChanged() { mutedIconField.text = Config.mopidyMutedIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyMutedIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyMutedIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyMutedIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyMutedIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyMutedIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyMutedIconY"; settingsObject: root.settings; saveOnEdit: true }
        Item { width: 58; height: 30 }
    }

    Row {
        width: parent.width; height: 30; spacing: 6
        Text { width: 82; text: "Очистить"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: clearIconField; width: 58; height: 30; text: Config.mopidyClearIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (clearIconField.activeFocus || clearIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { Config.mopidyClearIcon = text; text = Config.mopidyClearIcon; settings.save() }
            Connections { target: Config; function onMopidyClearIconChanged() { clearIconField.text = Config.mopidyClearIcon } }
        }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyClearIconSize; minimum: 6; maximum: 64; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyClearIconSize"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyClearIconX; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyClearIconX"; settingsObject: root.settings; saveOnEdit: true }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyClearIconY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyClearIconY"; settingsObject: root.settings; saveOnEdit: true }
        SettingsCheckBox {
            id: clearVisibilityCheckBox; width: 58; height: 30; indicatorOnly: true; checked: Config.mopidyShowClearIcon
            onClicked: { Config.mopidyShowClearIcon = checked; settings.save() }
            Connections { target: Config; function onMopidyShowClearIconChanged() { clearVisibilityCheckBox.checked = Config.mopidyShowClearIcon } }
        }
    }

}
