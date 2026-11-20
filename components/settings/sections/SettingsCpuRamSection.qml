import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentPageId === "cpuRam"
    width: parent ? parent.width : 0
    spacing: 10
    SettingsGroup {
                visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["cpuBarDirection", "cpuBarLeftOffset", "cpuBarRadius", "cpuBarThickness", "cpuBarWidth", "cpuLabelLeftPadding", "cpuRowHeight", "cpuRowSpacing", "cpuUpdateInterval"] })
        padding: 8
        contentSpacing: 6

        Text {
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                text: "Полосы CPU и RAM"
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }

            SettingsRow {
                label: "Интервал обновления CPU (мс)"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Направление заполнения полос"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Толщина полос"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Ширина полос"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Высота строки"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Расстояние между строками"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Отступ подписи слева"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Смещение полос слева"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Радиус полос"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 0
                width: parent.width; height: 30; spacing: 8
                
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
                visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["cpuGraphBarWidth", "cpuGraphMode", "cpuGraphSegmentSlotWidth", "cpuShowRam"] })
        padding: 8
        contentSpacing: 6

            SettingsRow {
                label: "Режим графика CPU"
                labelWidth: 210
            visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Ширина сегмента графика"
                labelWidth: 210
            visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
                
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

            SettingsRow {
                label: "Толщина полос графика"
                labelWidth: 210
            visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
                
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
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 1
                width: parent.width; height: 30; spacing: 8
                SettingsCheckBox {
                    width: 210; height: 30; text: "Показывать RAM"; checked: Config.cpuShowRam
                    onToggled: { Config.cpuShowRam=checked; settings.save() }
                }
            }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: false
        padding: 8
        contentSpacing: 6

            Text {
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                text: "Top Apps — отображение"
                color: Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(14)
            }

            Text {
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
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
                visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        heading: "Заголовки"
        changeKeys: ({ keys: ["topAppsCpuHeaderSubtitle", "topAppsCpuHeaderTitle", "topAppsHeaderSubtitleFontSize", "topAppsHeaderTitleFontSize", "topAppsRamHeaderSubtitle", "topAppsRamHeaderTitle", "topAppsShowHeaders"] })
        padding: 8
        contentSpacing: 6

        Row {
            visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
            width: parent.width
            height: 30
            spacing: 8
            SettingsCheckBox {
                width: parent.width
                height: 30
                text: "Показывать заголовки CPU и памяти"
                checked: Config.topAppsShowHeaders
                onToggled: { Config.topAppsShowHeaders = checked; settings.save() }
            }
        }

        MorphGeometry {
            id: topAppsHeadersMorph
            width: parent.width
            clip: true
            visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                && (Config.topAppsShowHeaders || normalizedProgress > 0.001)
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, topAppsHeadersContent.implicitHeight)
            progress: Config.topAppsShowHeaders ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("standard", Config.topAppsShowHeaders ? "enter" : "exit")

            Column {
                id: topAppsHeadersContent
                width: parent.width
                spacing: 6

                Text {
                    text: "CPU"
                    color: Config.settingsSubheading
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                SettingsRow {
                    label: "Основной заголовок"
                    labelWidth: 210
                    width: parent.width; height: 30; spacing: 8
                    
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

                SettingsRow {
                    label: "Подзаголовок"
                    labelWidth: 210
                    width: parent.width; height: 30; spacing: 8
                    
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
                    text: "Память"
                    color: Config.settingsSubheading
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }

                SettingsRow {
                    label: "Основной заголовок"
                    labelWidth: 210
                    width: parent.width; height: 30; spacing: 8
                    
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

                SettingsRow {
                    label: "Подзаголовок"
                    labelWidth: 210
                    width: parent.width; height: 30; spacing: 8
                    
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

                SettingsRow {
                    label: "Размер основного заголовка"
                    labelWidth: 210
                    width: parent.width; height: 30; spacing: 8
                    
                    SettingsNumberField {
                        value: Config.topAppsHeaderTitleFontSize
                        minimum: 6; maximum: 32; step: 1; wheelStep: 1
                        labelWidth: 0; fieldWidth: 100; compact: true
                        targetObject: Config; targetProperty: "topAppsHeaderTitleFontSize"
                        settingsObject: root.settings; saveOnEdit: true
                    }
                }

                SettingsRow {
                    label: "Размер подзаголовка"
                    labelWidth: 210
                    width: parent.width; height: 30; spacing: 8
                    
                    SettingsNumberField {
                        value: Config.topAppsHeaderSubtitleFontSize
                        minimum: 6; maximum: 32; step: 1; wheelStep: 1
                        labelWidth: 0; fieldWidth: 100; compact: true
                        targetObject: Config; targetProperty: "topAppsHeaderSubtitleFontSize"
                        settingsObject: root.settings; saveOnEdit: true
                    }
                }
            }
        }
    }

    // Полосы: цвета расположены непосредственно под переключателем показа.
    SettingsGroup {
                visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        heading: "Положение и размер полос"
        changeKeys: ({ keys: ["topAppsBarHeight", "topAppsBarWidth", "topAppsBarX", "topAppsBarY", "topAppsShowBars"] })
        padding: 8
        contentSpacing: 6


            Row {
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                width: parent.width; height: 30; spacing: 8
                SettingsCheckBox {
                    width: parent.width; height: 30
                    text: "Показывать полосы нагрузки"
                    checked: Config.topAppsShowBars
                    onToggled: { Config.topAppsShowBars = checked; settings.save() }
                }
            }


            MorphGeometry {
                id: topAppsBarGeometryMorph
                width: parent.width
                clip: true
                visible: host && ((Config.topAppsShowBars && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2)
                    || (host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2 && normalizedProgress > 0.001))
                fromGeometry: Qt.rect(0, 0, parent.width, 0)
                toGeometry: Qt.rect(0, 0, parent.width, topAppsBarGeometryContent.implicitHeight)
                progress: Config.topAppsShowBars ? 1 : 0
                animationDuration: Config.animationDuration(180, "appearance")
                animationEasing: Config.animationEasingType("standard", Config.topAppsShowBars ? "enter" : "exit")

                Column {
                    id: topAppsBarGeometryContent
                    width: parent.width
                    spacing: 6

                    SettingsRow {
                        label: "X — положение по горизонтали"
                        labelWidth: 210
                        visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                        width: parent.width
                        height: 30
                        spacing: 8
                        
                        SettingsNumberField {
                            value: Config.topAppsBarX
                            minimum: 45
                            maximum: 240
                            step: 1
                            wheelStep: 1
                            labelWidth: 0
                            fieldWidth: 100
                            compact: true
                            targetObject: Config
                            targetProperty: "topAppsBarX"
                            settingsObject: root.settings
                            saveOnEdit: true
                        }
                    }

                    SettingsRow {
                        label: "Y — смещение по вертикали"
                        labelWidth: 210
                        visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                        width: parent.width
                        height: 30
                        spacing: 8
                        
                        SettingsNumberField {
                            value: Config.topAppsBarY
                            minimum: -10
                            maximum: 10
                            step: 1
                            wheelStep: 1
                            labelWidth: 0
                            fieldWidth: 100
                            compact: true
                            targetObject: Config
                            targetProperty: "topAppsBarY"
                            settingsObject: root.settings
                            saveOnEdit: true
                        }
                    }

                    SettingsRow {
                        label: "Высота полосы"
                        labelWidth: 210
                        visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                        width: parent.width
                        height: 30
                        spacing: 8
                        
                        SettingsNumberField {
                            value: Config.topAppsBarHeight
                            minimum: 1
                            maximum: 30
                            step: 1
                            wheelStep: 1
                            labelWidth: 0
                            fieldWidth: 100
                            compact: true
                            targetObject: Config
                            targetProperty: "topAppsBarHeight"
                            settingsObject: root.settings
                            saveOnEdit: true
                        }
                    }

                    SettingsRow {
                        label: "Длина полосы"
                        labelWidth: 210
                        visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                        width: parent.width
                        height: 30
                        spacing: 8
                        
                        SettingsNumberField {
                            value: Config.topAppsBarWidth
                            minimum: 1
                            maximum: 300
                            step: 1
                            wheelStep: 1
                            labelWidth: 0
                            fieldWidth: 100
                            compact: true
                            targetObject: Config
                            targetProperty: "topAppsBarWidth"
                            settingsObject: root.settings
                            saveOnEdit: true
                        }
                    }
                }
            }


    }

    MorphGeometry {
        id: topAppsBarColorsMorph
        width: parent.width
        clip: true
        visible: host && ((Config.topAppsShowBars && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2)
            || (host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2 && normalizedProgress > 0.001))
        fromGeometry: Qt.rect(0, 0, parent.width, 0)
        toGeometry: Qt.rect(0, 0, parent.width, topAppsBarColorsGroup.implicitHeight)
        progress: Config.topAppsShowBars ? 1 : 0
        animationDuration: Config.animationDuration(180, "appearance")
        animationEasing: Config.animationEasingType("standard", Config.topAppsShowBars ? "enter" : "exit")

        SettingsGroup {
        settingsSearchSubTabIndex: 2
            id: topAppsBarColorsGroup
            visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
            width: parent.width
            showFrame: true
            heading: "Цвета полос нагрузки"
            changeKeys: ({ nested: { colors: ["topAppsCpuBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarColor", "topAppsRamBarTrackColor"] } })
            padding: 8
            contentSpacing: 6


                Text {
                    visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Отдельные цвета для заполнения полос CPU и RAM."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(9)
                }

                SettingsColorField {
                    visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
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
                    visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
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
                    visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
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
                    visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
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
    }

    // Строка «Система/прочее»: зависимое поле раскрывается под переключателем.
    SettingsGroup {
                visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        heading: "Строка «Система/прочее»"
        changeKeys: ({ keys: ["topAppsShowSystemRemainder", "topAppsSystemRemainderLabel"] })
        padding: 8
        contentSpacing: 6

        Row {
            visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
            width: parent.width; height: 30; spacing: 8
            SettingsCheckBox {
                width: parent.width; height: 30
                text: "Показывать строку «Система/прочее»"
                checked: Config.topAppsShowSystemRemainder
                onToggled: { Config.topAppsShowSystemRemainder = checked; settings.save() }
            }
        }

        MorphGeometry {
            id: topAppsSystemRemainderMorph
            width: parent.width
            clip: true
            visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                && (Config.topAppsShowSystemRemainder || normalizedProgress > 0.001)
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, topAppsSystemRemainderContent.implicitHeight)
            progress: Config.topAppsShowSystemRemainder ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("standard", Config.topAppsShowSystemRemainder ? "enter" : "exit")

            Column {
                id: topAppsSystemRemainderContent
                width: parent.width
                spacing: 6

                SettingsRow {
                    label: "Название строки остатка"
                    labelWidth: 210
                    labelElide: Text.ElideRight
                    width: parent.width; height: 30; spacing: 8
                    
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
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        heading: "Список приложений"
        changeKeys: ({ keys: ["topAppsFont", "topAppsFontSize", "topAppsRowSpacing", "topAppsTopOffset"] })
        padding: 8
        contentSpacing: 6


            SettingsRow {
                label: "Шрифт списка"
                labelWidth: 210
                labelElide: Text.ElideRight
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                width: parent.width; height: 30; spacing: 8
                
                SettingsFontField {
                    width: 218
                    height: 30
                    compact: true
                    fieldWidth: 180
                    fieldFontSize: 11
                    value: Config.topAppsFont
                    targetObject: Config
                    targetProperty: "topAppsFont"
                    settingsObject: settings
                    saveOnEdit: true
                }
            }

            SettingsRow {
                label: "Размер шрифта списка"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                width: parent.width; height: 30; spacing: 8
                
                SettingsNumberField {
                    value: Config.topAppsFontSize
                    minimum: 1; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsFontSize"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }

            SettingsRow {
                label: "Межстрочный интервал"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                width: parent.width; height: 30; spacing: 8
                
                SettingsNumberField {
                    value: Config.topAppsRowSpacing
                    minimum: 0; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsRowSpacing"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }

            SettingsRow {
                label: "Отступ от верхнего края"
                labelWidth: 210
                visible: host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 2
                width: parent.width; height: 30; spacing: 8
                
                SettingsNumberField {
                    value: Config.topAppsTopOffset
                    minimum: 0; step: 1; wheelStep: 1
                    labelWidth: 0; fieldWidth: 100; compact: true
                    targetObject: Config; targetProperty: "topAppsTopOffset"
                    settingsObject: root.settings; saveOnEdit: true
                }
            }
    }

    SettingsAnimationGroup {
        visible: host && host.currentPageId === "cpuRam" && host.currentPageSubTabIndex === 3
        width: root.width
        settings: root.settings
        heading: "Внутренние переходы CPU"
        durationLabel: "Максимальная длительность (мс)"
        maximumDuration: 260
        durationStep: 10
        durationWheelStep: 10
        duration: Config.animationCpuMorphDuration
        profile: Config.animationCpuMorphProfile
        changeKeys: ({ keys: ["animationCpuMorphDuration", "animationCpuMorphProfile"] })

        onDurationEdited: function(value) {
            Config.animationCpuMorphDuration = Math.max(0, Math.min(260, Math.round(Number(value) || 0)))
            root.settings.save()
        }
        onProfileEdited: function(value) {
            Config.animationCpuMorphProfile = value
            root.settings.save()
        }

        SettingsGroup {
            width: parent.width
            showFrame: true
            heading: "Что управляется"
            padding: 8
            contentSpacing: 4
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Профиль управляет кривой сглаживания загрузки ядер CPU в горизонтальном и вертикальном режимах. Фактическая длительность автоматически подстраивается под интервал обновления CPU и не превышает заданный предел. Полоса RAM сохраняет мгновенное обновление, а график истории CPU продолжает прокручиваться с собственной частотой. Анимация появления самого модуля остаётся независимой."
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }
        }
    }
}
