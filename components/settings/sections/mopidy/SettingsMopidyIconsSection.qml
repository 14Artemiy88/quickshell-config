import QtQuick
import QtQuick.Controls
import "../../primitives"
import "../../../primitives" as Primitives
import "../../../.."

Column {
    id: root
    property var host
    property var settings: Settings
    property int settingsSearchSubTabIndex: 2
    spacing: 10
    width: parent ? parent.width : 0
    visible: host && host.currentPageId === "mopidy" && host.currentPageSubTabIndex === 2

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

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyHideTopPanel", "mopidyTopPanelHoverHeight", "mopidyTopPanelOffsetY"] })
        padding: 8
        contentSpacing: 6

            SettingsRow {
                label: "Скрывать верхнюю панель иконок"
                controlSpacing: 8
                width: parent.width
                height: 30
                spacing: 8

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

            SettingsRow {
                label: "Высота области наведения"
                controlSpacing: 8
                width: parent.width
                height: 30
                spacing: 8

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

            SettingsRow {
                label: "Отступ сверху (Y)"
                controlSpacing: 8
                width: parent.width
                height: 30
                spacing: 8

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
    }

    SettingsGroup {
        id: mopidyTopIconOrderSettingsGroup
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyTopIconOrder"] })
        padding: 8
        contentSpacing: 6

            Text {
                text: "Порядок верхней панели"
                color: Config.settingsSubheading
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
                topPadding: 4
            }

            SettingsDescription {
                text: "Порядок применяется слева направо. Перетаскивай маркер, чтобы изменить положение иконок; их настройки и действия не меняются."
                color: Config.textMuted
                font.family: Config.settingsFontFamily
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
                    moveItemTo(index, index + Number(delta))
                }

                function moveItemTo(fromIndex, toIndex) {
                    var next = orderIds.slice(0)
                    if (fromIndex < 0 || fromIndex >= next.length || toIndex < 0 || toIndex >= next.length || fromIndex === toIndex) return
                    var item = next.splice(fromIndex, 1)[0]
                    next.splice(toIndex, 0, item)
                    saveOrder(next)
                }

                Repeater {
                    id: mopidyTopIconOrderRepeater
                    model: orderColumn.orderIds
                    delegate: Row {
                        id: mopidyTopIconOrderRow
                        Behavior on y { NumberAnimation { duration: Config.animationDuration(190, "appearance"); easing.type: Easing.OutCubic } }
                        property Item reorderTargetItem: mopidyTopIconOrderRow
                        width: parent.width
                        height: 28
                        spacing: 5

                        Text {
                            width: 150
                            height: 28
                            text: root.topIconLabel(modelData)
                            color: Config.text
                            font.family: Config.settingsFontFamily
                            font.pixelSize: Config.settingsUiSize(11)
                            verticalAlignment: Text.AlignVCenter
                        }

                        Primitives.DragReorderHandle {
                            width: 26
                            height: 26
                            listRepeater: mopidyTopIconOrderRepeater
                            dropIndicatorHost: mopidyTopIconOrderSettingsGroup
                            itemIndex: index
                            accessibleLabel: root.topIconLabel(modelData)
                            onReorderRequested: function(fromIndex, toIndex) {
                                orderColumn.moveItemTo(fromIndex, toIndex)
                            }
                        }
                    }
                }

                SettingsButton {
                    width: 125
                    height: 28
                    text: "По умолчанию"
                    fontSize: 10
                    fillOnHover: false
                    backgroundColor: "transparent"
                    hoverBackgroundColor: Config.baseColor
                    textColor: Config.text
                    hoverTextColor: Config.text
                    onClicked: orderColumn.saveOrder(["stop", "shuffle", "repeat", "volume", "refresh", "openAdd", "clear"])
                }
            }
    }

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyAddIcon", "mopidyAddIconSize", "mopidyAddIconX", "mopidyAddIconY", "mopidyClearIcon", "mopidyClearIconSize", "mopidyClearIconX", "mopidyClearIconY", "mopidyControlIconColor", "mopidyMutedIcon", "mopidyMutedIconSize", "mopidyMutedIconX", "mopidyMutedIconY", "mopidyOpenAddIcon", "mopidyOpenAddIconSize", "mopidyOpenAddIconX", "mopidyOpenAddIconY", "mopidyPlaylistDeleteIcon", "mopidyPlaylistDeleteIconSize", "mopidyPlaylistDeleteIconX", "mopidyPlaylistDeleteIconY", "mopidyRefreshIcon", "mopidyRefreshIconSize", "mopidyRefreshIconX", "mopidyRefreshIconY", "mopidyRepeatIcon", "mopidyRepeatIconSize", "mopidyRepeatIconX", "mopidyRepeatIconY", "mopidyShowAddIcon", "mopidyShowClearIcon", "mopidyShowOpenAddIcon", "mopidyShowPlaylistDeleteIcon", "mopidyShowRefreshIcon", "mopidyShowRepeatIcon", "mopidyShowShuffleIcon", "mopidyShowStopIcon", "mopidyShowSwitchPlaylistIcon", "mopidyShowVolumeIcon", "mopidyShuffleIcon", "mopidyShuffleIconSize", "mopidyShuffleIconX", "mopidyShuffleIconY", "mopidyStopIcon", "mopidyStopIconSize", "mopidyStopIconX", "mopidyStopIconY", "mopidySwitchPlaylistIcon", "mopidySwitchPlaylistIconSize", "mopidySwitchPlaylistIconX", "mopidySwitchPlaylistIconY", "mopidyVolumeIcon", "mopidyVolumeIconSize", "mopidyVolumeIconX", "mopidyVolumeIconY"] })
        padding: 8
        contentSpacing: 6

            Text {
                text: "Иконки"
                color: Config.settingsSubheading
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
                topPadding: 4
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
                Text { width: 82; text: ""; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
                Text { width: 58; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
                Text { width: 58; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
                Text { width: 58; text: "X"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
                Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
                Text { width: 58; text: "Показывать"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
            }

            Row {
                width: parent.width; height: 30; spacing: 6
                Text { width: 82; height: 30; text: "Стоп"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: stopIconField; width: 58; height: 30; text: Config.mopidyStopIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Стоп"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (stopIconField.activeFocus || stopIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || stopIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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
                Text { width: 82; height: 30; text: "Обновить"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: refreshIconField; width: 58; height: 30; text: Config.mopidyRefreshIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Обновить"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (refreshIconField.activeFocus || refreshIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || refreshIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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
                Text { width: 82; height: 30; text: "Открыть добавление"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: openAddIconField; width: 58; height: 30; text: Config.mopidyOpenAddIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Открыть добавление"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (openAddIconField.activeFocus || openAddIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || openAddIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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
                Text { width: 82; height: 30; text: "Добавить элемент"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: addIconField; width: 58; height: 30; text: Config.mopidyAddIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Добавить элемент"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (addIconField.activeFocus || addIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || addIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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
                Text { width: 82; height: 30; text: "Shuffle"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: shuffleIconField; width: 58; height: 30; text: Config.mopidyShuffleIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Перемешать"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (shuffleIconField.activeFocus || shuffleIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || shuffleIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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
                Text { width: 82; height: 30; text: "Repeat"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: repeatIconField; width: 58; height: 30; text: Config.mopidyRepeatIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Повтор"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (repeatIconField.activeFocus || repeatIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || repeatIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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
                Text { width: 82; height: 30; text: "Переключить плейлист"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap }
                SettingsTextField {
                    id: switchPlaylistIconField; width: 58; height: 30; text: Config.mopidySwitchPlaylistIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Переключить плейлист"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (switchPlaylistIconField.activeFocus || switchPlaylistIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || switchPlaylistIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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
                Text { width: 82; height: 30; text: "Удаление плейлистов/треков"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap }
                SettingsTextField {
                    id: playlistDeleteIconField; width: 58; height: 30; text: Config.mopidyPlaylistDeleteIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Удалить плейлист или трек"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (playlistDeleteIconField.activeFocus || playlistDeleteIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || playlistDeleteIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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

            SettingsDescription {
                width: parent.width
                text: "Порядок треков очереди и записей плейлистов меняется перетаскиванием за маркер ⠿."
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(9)
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width; height: 30; spacing: 6
                Text { width: 82; height: 30; text: "Громкость"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: volumeIconField; width: 58; height: 30; text: Config.mopidyVolumeIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Громкость"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (volumeIconField.activeFocus || volumeIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || volumeIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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
                Text { width: 82; height: 30; text: "Mute"; color: Config.textMuted; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: mutedIconField; width: 58; height: 30; text: Config.mopidyMutedIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Без звука"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (mutedIconField.activeFocus || mutedIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || mutedIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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
                Text { width: 82; height: 30; text: "Очистить"; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: clearIconField; width: 58; height: 30; text: Config.mopidyClearIcon; color: Config.text; font.family: Config.settingsFontFamily; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
                    settingsSearchLabel: "Иконка: Очистить"
                    settingsSearchKeywords: "иконка иконки значок symbol glyph mopidy"
                    background: Rectangle { color: "transparent"; border.color: (clearIconField.activeFocus || clearIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: (Config.inputBordersEnabled || clearIconField.activeFocus) ? 1 : 0; radius: Config.scaledCornerRadius(Config.settingsUiSize(4)) }
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

}
