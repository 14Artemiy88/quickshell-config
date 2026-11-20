import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentPageId === "volume"
    width: parent ? parent.width : 0
    spacing: 10

// -------------------- Volume --------------------
    SettingsGroup {
                visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["volumeIcon", "volumeMutedIcon"] })
        padding: 8
        contentSpacing: 6

        Text { visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 0; text: "Иконки громкости"; color: Config.settingsSubheading; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
        SettingsRow {
            label: "Громкость"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 0; width: parent.width; height: 30; spacing: 8
            
            SettingsTextField { id: volumeIconField; width: 100; height: 30; text: Config.volumeIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (volumeIconField.activeFocus || volumeIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.volumeIcon=text; settings.save() } Connections { target: Config; function onVolumeIconChanged(){volumeIconField.text=Config.volumeIcon} } }
        }
        SettingsRow {
            label: "Без звука"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 0; width: parent.width; height: 30; spacing: 8
            
            SettingsTextField { id: volumeMutedIconField; width: 100; height: 30; text: Config.volumeMutedIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (volumeMutedIconField.activeFocus || volumeMutedIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.volumeMutedIcon=text; settings.save() } Connections { target: Config; function onVolumeMutedIconChanged(){volumeMutedIconField.text=Config.volumeMutedIcon} } }
        }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["volumeHorizontalPadding", "volumeMainRowHeight", "volumeStreamRowHeight", "volumeStreamSpacing", "volumeUpdateInterval"] })
        padding: 8
        contentSpacing: 6

        Text {
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 1
            text: "Полоса и аудиопотоки"
            color: Config.settingsSubheading
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
        }
        SettingsRow {
            label: "Интервал опроса громкости (мс)"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeUpdateField
                label: ""
                value: Config.volumeUpdateInterval
                minimum: 50
                maximum: 5000
                step: 10
                wheelStep: 10
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeUpdateInterval"
                settingsObject: settings
                saveOnEdit: true
            }
        }
        SettingsRow {
            label: "Высота основной строки"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeMainRowHeightField
                label: ""
                value: Config.volumeMainRowHeight
                minimum: 20
                maximum: 80
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeMainRowHeight"
                settingsObject: settings
                saveOnEdit: true
            }
        }
        SettingsRow {
            label: "Высота строк потоков"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeStreamRowHeightField
                label: ""
                value: Config.volumeStreamRowHeight
                minimum: 12
                maximum: 60
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeStreamRowHeight"
                settingsObject: settings
                saveOnEdit: true
            }
        }
        SettingsRow {
            label: "Расстояние между потоками"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeStreamSpacingField
                label: ""
                value: Config.volumeStreamSpacing
                minimum: 0
                maximum: 20
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeStreamSpacing"
                settingsObject: settings
                saveOnEdit: true
            }
        }
        SettingsRow {
            label: "Отступ блока слева/справа"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeHorizontalPaddingField
                label: ""
                value: Config.volumeHorizontalPadding
                minimum: 0
                maximum: 40
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeHorizontalPadding"
                settingsObject: settings
                saveOnEdit: true
            }
        }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["volumeMainTrackHeight", "volumeMainTrackOffsetY", "volumeMainTrackWidth", "volumeStreamTrackHeight", "volumeVerticalPadding"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            label: "Отступ блока сверху/снизу"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeVerticalPaddingField
                label: ""
                value: Config.volumeVerticalPadding
                minimum: 0
                maximum: 40
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeVerticalPadding"
                settingsObject: settings
                saveOnEdit: true
            }
        }
        SettingsRow {
            label: "Ширина основной полосы"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeMainTrackWidthField
                label: ""
                value: Config.volumeMainTrackWidth
                minimum: 40
                maximum: 1000
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeMainTrackWidth"
                settingsObject: settings
                saveOnEdit: true
            }
        }
        SettingsRow {
            label: "Высота полосы громкости"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeMainTrackHeightField
                label: ""
                value: Config.volumeMainTrackHeight
                minimum: 1
                maximum: 30
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeMainTrackHeight"
                settingsObject: settings
                saveOnEdit: true
            }
        }
        SettingsRow {
            label: "Высота полос потоков"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeStreamTrackHeightField
                label: ""
                value: Config.volumeStreamTrackHeight
                minimum: 1
                maximum: 20
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeStreamTrackHeight"
                settingsObject: settings
                saveOnEdit: true
            }
        }
        SettingsRow {
            label: "Смещение основной полосы Y"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 2; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeMainTrackOffsetField
                label: ""
                value: Config.volumeMainTrackOffsetY
                minimum: -30
                maximum: 30
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeMainTrackOffsetY"
                settingsObject: settings
                saveOnEdit: true
            }
        }
    }
    SettingsGroup {
                visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 3
settingsSearchSubTabIndex: 3
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["volumeMainIconWidth", "volumeShowStreams", "volumeStreamLabelFontSize", "volumeStreamTrackOffsetY", "volumeTrackRadius"] })
        padding: 8
        contentSpacing: 6

        Row { visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 3; width: parent.width; height: 30; spacing: 8
            SettingsCheckBox { width: 210; height: 30; text: "Показывать дополнительные потоки"; checked: Config.volumeShowStreams; onToggled: { Config.volumeShowStreams=checked; settings.save() } }
        }

        MorphGeometry {
            id: volumeStreamTrackOffsetMorph
            width: parent.width
            clip: true
            visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 3
                && (Config.volumeShowStreams || normalizedProgress > 0.001)
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, volumeStreamTrackOffsetContent.implicitHeight)
            progress: Config.volumeShowStreams ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("standard", Config.volumeShowStreams ? "enter" : "exit")

            SettingsRow {
                id: volumeStreamTrackOffsetContent
                label: "Смещение полос потоков Y"
                labelWidth: 210
                width: parent.width
                height: 30
                spacing: 8
                
                SettingsNumberField {
                    id: volumeStreamTrackOffsetField
                    label: ""
                    value: Config.volumeStreamTrackOffsetY
                    minimum: -20
                    maximum: 20
                    step: 1
                    wheelStep: 1
                    labelWidth: 0
                    fieldWidth: 100
                    compact: true
                    targetObject: Config
                    targetProperty: "volumeStreamTrackOffsetY"
                    settingsObject: settings
                    saveOnEdit: true
                }
            }
        }
        SettingsRow {
            label: "Ширина иконки громкости"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 3; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeMainIconWidthField
                label: ""
                value: Config.volumeMainIconWidth
                minimum: 16
                maximum: 80
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeMainIconWidth"
                settingsObject: settings
                saveOnEdit: true
            }
        }
        MorphGeometry {
            id: volumeStreamLabelFontMorph
            width: parent.width
            clip: true
            visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 3
                && (Config.volumeShowStreams || normalizedProgress > 0.001)
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, volumeStreamLabelFontContent.implicitHeight)
            progress: Config.volumeShowStreams ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("standard", Config.volumeShowStreams ? "enter" : "exit")

            SettingsRow {
                id: volumeStreamLabelFontContent
                label: "Размер текста потоков"
                labelWidth: 210
                width: parent.width
                height: 30
                spacing: 8
                
                SettingsNumberField {
                    id: volumeStreamLabelFontField
                    label: ""
                    value: Config.volumeStreamLabelFontSize
                    minimum: 8
                    maximum: 32
                    step: 1
                    wheelStep: 1
                    labelWidth: 0
                    fieldWidth: 100
                    compact: true
                    targetObject: Config
                    targetProperty: "volumeStreamLabelFontSize"
                    settingsObject: settings
                    saveOnEdit: true
                }
            }
        }
        SettingsRow {
            label: "Радиус полос громкости"
            labelWidth: 210
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 3; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
                id: volumeTrackRadiusField
                label: ""
                value: Config.volumeTrackRadius
                minimum: 0
                maximum: 20
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeTrackRadius"
                settingsObject: settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 4
settingsSearchSubTabIndex: 4
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["volumeMaxHeight", "volumeMinHeight"] })
        padding: 8
        contentSpacing: 6

        Text {
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 4
            text: "Адаптивные блоки"
            color: Config.accent
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
        }

        Text {
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 4
            text: "Высота блока автоматически растёт по содержимому в пределах этих ограничений."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
            width: parent.width
        }

        SettingsRow {
            label: "Минимальная высота громкости"
            labelWidth: 210
            width: parent.width; height: 30; spacing: 8
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 4
            
            SettingsNumberField {
                id: volumeMinHeightField
                label: ""
                value: Config.volumeMinHeight
                minimum: 30
                maximum: 1000
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeMinHeight"
                settingsObject: settings
                saveOnEdit: true
            }
        }

        SettingsRow {
            label: "Максимальная высота громкости"
            labelWidth: 210
            width: parent.width; height: 30; spacing: 8
            visible: host.currentPageId === "volume" && host.currentPageSubTabIndex === 4
            
            SettingsNumberField {
                id: volumeMaxHeightField
                label: ""
                value: Config.volumeMaxHeight
                minimum: 100
                maximum: 2000
                step: 1
                wheelStep: 1
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeMaxHeight"
                settingsObject: settings
                saveOnEdit: true
            }
        }
    }


    SettingsAnimationGroup {
        visible: host && host.currentPageId === "volume" && host.currentPageSubTabIndex === 5
        width: root.width
        settings: root.settings
        heading: "Внутренние переходы списка потоков"
        detailsHeading: "Параметры анимации"
        changeKeys: ({ keys: ["animationVolumeStreamsVisibilityStyle", "animationVolumeMorphProfile", "volumeStreamsAnimationDuration"] })
        duration: Config.volumeStreamsAnimationDuration
        profile: Config.animationVolumeMorphProfile

        onDurationEdited: function(value) {
            Config.volumeStreamsAnimationDuration = value
            root.settings.save()
        }
        onProfileEdited: function(value) {
            Config.animationVolumeMorphProfile = value
            root.settings.save()
        }

        SettingsGroup {
            width: parent.width
            showFrame: true
            heading: "Вид перехода"
            changeKeys: ({ keys: ["animationVolumeStreamsVisibilityStyle"] })
            padding: 8
            contentSpacing: 6

            SettingsRow {
                label: "Направление"
                labelWidth: 210
                width: parent.width
                height: 30
                spacing: 8
                
                SettingsComboBox {
                    id: volumeStreamsAnimationStyleBox
                    width: 180
                    height: 30
                    property var values: ["fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                    model: ["Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                    currentIndex: Math.max(0, values.indexOf(Config.animationVolumeStreamsVisibilityStyle))
                    onItemChosen: function(index) {
                        if (index >= 0 && index < values.length) {
                            Config.animationVolumeStreamsVisibilityStyle = values[index]
                            root.settings.save()
                        }
                    }
                    Connections {
                        target: Config
                        function onAnimationVolumeStreamsVisibilityStyleChanged() {
                            volumeStreamsAnimationStyleBox.currentIndex = Math.max(0, volumeStreamsAnimationStyleBox.values.indexOf(Config.animationVolumeStreamsVisibilityStyle))
                        }
                    }
                    background: Rectangle {
                        color: Config.settingsBackground
                        border.color: (volumeStreamsAnimationStyleBox.activeFocus || volumeStreamsAnimationStyleBox.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: 4
                    }
                    contentItem: Text {
                        text: volumeStreamsAnimationStyleBox.currentText
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Профиль кривой и длительность управляют раскрытием и сворачиванием списка. Направление задаёт затухание или сторону сдвига. Анимация появления самого модуля остаётся независимой."
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }
        }
    }

}
