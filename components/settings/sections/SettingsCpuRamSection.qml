import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 5
    width: parent ? parent.width : 0
    spacing: 10
    SettingsGroup {
        visible: host && host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                text: "Полосы CPU и RAM"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Интервал обновления CPU (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    id: cpuSettingsIntervalField
                    value: Config.cpuUpdateInterval
                    minimum: 200
                    maximum: 10000
                    step: 100
                    wheelStep: 100
                    labelWidth: 0
                    fieldWidth: 100
                    compact: true
                    targetObject: Config
                    targetProperty: "cpuUpdateInterval"
                    settingsObject: settings
                    saveOnEdit: true
                }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Направление заполнения полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsComboBox {
                    id: cpuBarDirectionCombo
                    width: 170
                    height: 30
                    model: ["Слева направо", "Справа налево", "Сверху вниз", "Снизу вверх"]
                    currentIndex: ["leftToRight", "rightToLeft", "topToBottom", "bottomToTop"].indexOf(Config.cpuBarDirection) >= 0 ? ["leftToRight", "rightToLeft", "topToBottom", "bottomToTop"].indexOf(Config.cpuBarDirection) : 0
                    onItemChosen: index => {
                        Config.cpuBarDirection = ["leftToRight", "rightToLeft", "topToBottom", "bottomToTop"][index]
                        settings.save()
                    }
                }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Толщина полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
            id: cpuBarThicknessField
            width: 100
            height: 30
            value: Config.cpuBarThickness
            minimum: 1
            maximum: 30
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cpuBarThickness"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Ширина полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
            id: cpuBarWidthField
            width: 100
            height: 30
            value: Config.cpuBarWidth
            minimum: 40
            maximum: 1000
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cpuBarWidth"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Высота строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
            id: cpuRowHeightField
            width: 100
            height: 30
            value: Config.cpuRowHeight
            minimum: 10
            maximum: 60
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cpuRowHeight"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
            id: cpuRowSpacingField
            width: 100
            height: 30
            value: Config.cpuRowSpacing
            minimum: 0
            maximum: 30
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cpuRowSpacing"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Отступ подписи слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
            id: cpuLabelPaddingField
            width: 100
            height: 30
            value: Config.cpuLabelLeftPadding
            minimum: 0
            maximum: 40
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cpuLabelLeftPadding"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Смещение полос слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
            id: cpuBarOffsetField
            width: 100
            height: 30
            value: Config.cpuBarLeftOffset
            minimum: 0
            maximum: 200
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cpuBarLeftOffset"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Радиус полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
            id: cpuBarRadiusField
            width: 100
            height: 30
            value: Config.cpuBarRadius
            minimum: 0
            maximum: 40
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cpuBarRadius"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }
    }


    SettingsGroup {
        visible: host && host.currentOtherTab === 5 && host.currentOtherSubTab === 1
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

            Row { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Режим графика CPU"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsComboBox {
                    id: cpuGraphModeCombo
                    width: 130
                    height: 30
                    model: ["Обе половины", "Только верхние", "Только нижние"]
                    currentIndex: ["both", "top", "bottom"].indexOf(Config.cpuGraphMode) >= 0 ? ["both", "top", "bottom"].indexOf(Config.cpuGraphMode) : 0
                    onItemChosen: index => {
                        Config.cpuGraphMode = ["both", "top", "bottom"][index]
                        settings.save()
                    }
                }
            }

            Row { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Ширина сегмента графика"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
            id: cpuGraphSlotField
            width: 100
            height: 30
            value: Config.cpuGraphSegmentSlotWidth
            minimum: 1
            maximum: 20
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cpuGraphSegmentSlotWidth"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }

            Row { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Толщина полос графика"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
            id: cpuGraphBarWidthField
            width: 100
            height: 30
            value: Config.cpuGraphBarWidth
            minimum: 1
            maximum: 10
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cpuGraphBarWidth"
            settingsObject: root.settings
            saveOnEdit: true
        }
            }



            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1
                width: parent.width; height: 30; spacing: 8
                SettingsCheckBox {
                    width: 210; height: 30; text: "Показывать RAM"; checked: Config.cpuShowRam
                    onToggled: { Config.cpuShowRam=checked; settings.save() }
                }
            }
    }

    SettingsGroup {
        visible: host && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
        width: parent.width
        showFrame: false
        padding: 8
        contentSpacing: 6

            Text {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                text: "Top Apps — отображение"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(14)
            }

            Text {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Дополнительные параметры раскрываются сразу под соответствующим переключателем."
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }
    }

    // Заголовки: зависимые параметры сгруппированы сразу под переключателем.
    SettingsGroup {
        visible: host && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                SettingsCheckBox {
                    width: parent.width; height: 30
                    text: "Показывать заголовки CPU и памяти"
                    checked: Config.topAppsShowHeaders
                    onToggled: { Config.topAppsShowHeaders = checked; settings.save() }
                }
            }


            Text {
                visible: Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                text: "Заголовки"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(12)
            }


            Text {
                visible: Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                text: "CPU"
                color: Config.settingsSubheading
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }

            Row {
                visible: Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Основной заголовок"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: topAppsCpuHeaderTitleField
                    width: 180; height: 30
                    text: Config.topAppsCpuHeaderTitle
                    color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                    placeholderText: "CPU"
                    activeFocusOnTab: true
                    onEditingFinished: { Config.topAppsCpuHeaderTitle = text.replace(/[\r\n\t]/g, " ").trim().slice(0, 64); text = Config.topAppsCpuHeaderTitle; settings.save() }
                    Connections { target: Config; function onTopAppsCpuHeaderTitleChanged() { topAppsCpuHeaderTitleField.text = Config.topAppsCpuHeaderTitle } }
                }
            }

            Row {
                visible: Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Подзаголовок"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: topAppsCpuHeaderSubtitleField
                    width: 180; height: 30
                    text: Config.topAppsCpuHeaderSubtitle
                    color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                    placeholderText: "ДОЛЯ ОТ ВСЕГО CPU"
                    activeFocusOnTab: true
                    onEditingFinished: { Config.topAppsCpuHeaderSubtitle = text.replace(/[\r\n\t]/g, " ").trim().slice(0, 64); text = Config.topAppsCpuHeaderSubtitle; settings.save() }
                    Connections { target: Config; function onTopAppsCpuHeaderSubtitleChanged() { topAppsCpuHeaderSubtitleField.text = Config.topAppsCpuHeaderSubtitle } }
                }
            }


            Text {
                visible: Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                text: "Память"
                color: Config.settingsSubheading
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }

            Row {
                visible: Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Основной заголовок"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: topAppsRamHeaderTitleField
                    width: 180; height: 30
                    text: Config.topAppsRamHeaderTitle
                    color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                    placeholderText: "ПАМЯТЬ"
                    activeFocusOnTab: true
                    onEditingFinished: { Config.topAppsRamHeaderTitle = text.replace(/[\r\n\t]/g, " ").trim().slice(0, 64); text = Config.topAppsRamHeaderTitle; settings.save() }
                    Connections { target: Config; function onTopAppsRamHeaderTitleChanged() { topAppsRamHeaderTitleField.text = Config.topAppsRamHeaderTitle } }
                }
            }

            Row {
                visible: Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Подзаголовок"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsTextField {
                    id: topAppsRamHeaderSubtitleField
                    width: 180; height: 30
                    text: Config.topAppsRamHeaderSubtitle
                    color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                    placeholderText: "ТОП ПРОЦЕССОВ"
                    activeFocusOnTab: true
                    onEditingFinished: { Config.topAppsRamHeaderSubtitle = text.replace(/[\r\n\t]/g, " ").trim().slice(0, 64); text = Config.topAppsRamHeaderSubtitle; settings.save() }
                    Connections { target: Config; function onTopAppsRamHeaderSubtitleChanged() { topAppsRamHeaderSubtitleField.text = Config.topAppsRamHeaderSubtitle } }
                }
            }

            Row {
                visible: Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Размер основного заголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    value: Config.topAppsHeaderTitleFontSize
                    minimum: 6; maximum: 32; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsHeaderTitleFontSize"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }

            Row {
                visible: Config.topAppsShowHeaders && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Размер подзаголовка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    value: Config.topAppsHeaderSubtitleFontSize
                    minimum: 6; maximum: 32; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsHeaderSubtitleFontSize"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }

    }

    // Полосы: цвета расположены непосредственно под переключателем показа.
    SettingsGroup {
        visible: host && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                SettingsCheckBox {
                    width: parent.width; height: 30
                    text: "Показывать полосы нагрузки"
                    checked: Config.topAppsShowBars
                    onToggled: { Config.topAppsShowBars = checked; settings.save() }
                }
            }


            Text {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                text: "Положение и размер полос"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(12)
            }

            Row {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "X — положение по горизонтали"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    value: Config.topAppsBarX
                    minimum: 45; maximum: 240; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsBarX"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }

            Row {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Y — смещение по вертикали"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    value: Config.topAppsBarY
                    minimum: -10; maximum: 10; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsBarY"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }

            Row {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Высота полосы"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    value: Config.topAppsBarHeight
                    minimum: 1; maximum: 30; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsBarHeight"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }

            Row {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Длина полосы"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    value: Config.topAppsBarWidth
                    minimum: 1; maximum: 300; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsBarWidth"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }


            Text {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                text: "Цвета полос нагрузки"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(12)
            }

            Text {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Отдельные цвета для заполнения полос CPU и RAM."
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(9)
            }

            SettingsColorField {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width
                label: "CPU: цвет полосы"
                value: String(Config.topAppsCpuBarColor)
                targetObject: Config
                targetProperty: "topAppsCpuBarColor"
                settingsObject: root.settings
                saveOnEdit: true
                allowAlpha: true
                allowTransparent: true
                fieldWidth: 120
                compact: false
            }

            SettingsColorField {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width
                label: "RAM: цвет полосы"
                value: String(Config.topAppsRamBarColor)
                targetObject: Config
                targetProperty: "topAppsRamBarColor"
                settingsObject: root.settings
                saveOnEdit: true
                allowAlpha: true
                allowTransparent: true
                fieldWidth: 120
                compact: false
            }

            SettingsColorField {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width
                label: "CPU: неактивная часть полосы"
                value: String(Config.topAppsCpuBarTrackColor)
                targetObject: Config
                targetProperty: "topAppsCpuBarTrackColor"
                settingsObject: root.settings
                saveOnEdit: true
                allowAlpha: true
                allowTransparent: true
                fieldWidth: 120
                compact: false
            }

            SettingsColorField {
                visible: Config.topAppsShowBars && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width
                label: "RAM: неактивная часть полосы"
                value: String(Config.topAppsRamBarTrackColor)
                targetObject: Config
                targetProperty: "topAppsRamBarTrackColor"
                settingsObject: root.settings
                saveOnEdit: true
                allowAlpha: true
                allowTransparent: true
                fieldWidth: 120
                compact: false
            }

    }

    // Строка «Система/прочее»: поле названия рядом с соответствующим переключателем.
    SettingsGroup {
        visible: host && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                SettingsCheckBox {
                    width: parent.width; height: 30
                    text: "Показывать строку «Система/прочее»"
                    checked: Config.topAppsShowSystemRemainder
                    onToggled: { Config.topAppsShowSystemRemainder = checked; settings.save() }
                }
            }


            Text {
                visible: Config.topAppsShowSystemRemainder && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                text: "Строка «Система/прочее»"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(12)
            }

            Row {
                visible: Config.topAppsShowSystemRemainder && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text {
                    width: 210; height: 30; text: "Название строки остатка"
                    color: Config.text; font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                SettingsTextField {
                    id: topAppsSystemRemainderLabelField
                    width: 180; height: 30
                    text: Config.topAppsSystemRemainderLabel
                    color: Config.text; font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    placeholderText: "Система/прочее"
                    activeFocusOnTab: true
                    onEditingFinished: {
                        Config.topAppsSystemRemainderLabel = text.replace(/[\r\n\t]/g, " ").trim().slice(0, 64) || "Система/прочее"
                        text = Config.topAppsSystemRemainderLabel
                        settings.save()
                    }
                    Connections {
                        target: Config
                        function onTopAppsSystemRemainderLabelChanged() { topAppsSystemRemainderLabelField.text = Config.topAppsSystemRemainderLabel }
                    }
                }
            }

    }

    SettingsGroup {
        visible: host && host.currentOtherTab === 5 && host.currentOtherSubTab === 2
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

            Text {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                text: "Список приложений"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(12)
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text {
                    width: 210; height: 30; text: "Шрифт списка (пусто — системный)"
                    color: Config.text; font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                SettingsTextField {
                    id: topAppsFontField
                    width: 180; height: 30
                    text: Config.topAppsFont
                    color: Config.text; font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    placeholderText: "Системный шрифт"
                    activeFocusOnTab: true
                    onEditingFinished: {
                        Config.topAppsFont = text.trim().slice(0, 128)
                        text = Config.topAppsFont
                        settings.save()
                    }
                    Connections {
                        target: Config
                        function onTopAppsFontChanged() { topAppsFontField.text = Config.topAppsFont }
                    }
                }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Размер шрифта списка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    value: Config.topAppsFontSize
                    minimum: 1; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsFontSize"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Межстрочный интервал"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    value: Config.topAppsRowSpacing
                    minimum: 0; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsRowSpacing"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }

            Row {
                visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 2
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Отступ от верхнего края"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsNumberField {
                    value: Config.topAppsTopOffset
                    minimum: 0; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsTopOffset"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }
    }

}
