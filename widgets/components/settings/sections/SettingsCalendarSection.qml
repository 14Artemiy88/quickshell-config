import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Item {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 8
             && host.currentOtherSubTab === 0
    width: parent ? parent.width : 0
    height: visible ? calendarColumn.implicitHeight : 0
    implicitHeight: calendarColumn.implicitHeight

    Column {
        id: calendarColumn
        width: parent.width
        spacing: 10

Text {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    text: "Стрелки навигации"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(13)
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width
    height: 24
    spacing: 8
    Item { width: 210; height: parent.height }
    Text { width: 80; height: parent.height; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
    Text { width: 58; height: parent.height; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
    Text { width: 58; height: parent.height; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
    Text { width: 58; height: parent.height; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width; height: 30; spacing: 8
    Text { width: 210; height: 30; text: "Предыдущий месяц"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
    SettingsTextField { id: calendarPrevIconField; width: 80; height: 30; text: Config.calendarPreviousIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarPreviousIcon = text; settings.save() } }
    SettingsNumberField {
    id: calendarArrowSizeField
    width: 58
    height: 30
    value: Config.calendarPreviousSize
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
    targetProperty: "calendarPreviousSize"
    settingsObject: root.settings
    saveOnEdit: true
}
    SettingsNumberField {
    id: calendarPrevXField
    width: 58
    height: 30
    value: Config.calendarPreviousX
    minimum: -20
    maximum: 20
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    targetObject: Config
    targetProperty: "calendarPreviousX"
    settingsObject: root.settings
    saveOnEdit: true
}
    SettingsNumberField {
    id: calendarArrowYField
    width: 58
    height: 30
    value: Config.calendarArrowY
    minimum: -20
    maximum: 20
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    targetObject: Config
    targetProperty: "calendarArrowY"
    settingsObject: root.settings
    saveOnEdit: true
}
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width; height: 30; spacing: 8
    Text { width: 210; height: 30; text: "Следующий месяц"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
    SettingsTextField { id: calendarNextIconField; width: 80; height: 30; text: Config.calendarNextIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarNextIcon = text; settings.save() } }
    SettingsNumberField {
    id: calendarNextSizeField
    width: 58
    height: 30
    value: Config.calendarNextSize
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
    targetProperty: "calendarNextSize"
    settingsObject: root.settings
    saveOnEdit: true
}
    SettingsNumberField {
    id: calendarNextXField
    width: 58
    height: 30
    value: Config.calendarNextX
    minimum: -20
    maximum: 20
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    targetObject: Config
    targetProperty: "calendarNextX"
    settingsObject: root.settings
    saveOnEdit: true
}
    Text { width: 58; height: 30; text: ""; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width; height: 24; spacing: 8
    Item { width: 210; height: parent.height }
    Text { width: 58; height: parent.height; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
    Text { width: 58; height: parent.height; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
    Text { width: 130; height: parent.height; text: "Шрифт"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width; height: 30; spacing: 8
    Text { width: 210; height: 30; text: "Месяц"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
    id: calendarTitleY2Field
    width: 58
    height: 30
    value: Config.calendarTitleY
    minimum: -20
    maximum: 20
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    targetObject: Config
    targetProperty: "calendarTitleY"
    settingsObject: root.settings
    saveOnEdit: true
}
    SettingsNumberField {
    id: calendarTitleSizeField2
    width: 58
    height: 30
    value: Config.calendarTitleFontSize
    minimum: 8
    maximum: 48
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "calendarTitleFontSize"
    settingsObject: root.settings
    saveOnEdit: true
}
    SettingsTextField { id: calendarTitleFontField; width: 130; height: 30; text: Config.calendarTitleFont; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarTitleFont = text; settings.save() } }
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width; height: 30; spacing: 8
    Text { width: 210; height: 30; text: "Дни недели"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
    id: calendarWeekdayYField
    width: 58
    height: 30
    value: Config.calendarWeekdayY
    minimum: -20
    maximum: 20
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    targetObject: Config
    targetProperty: "calendarWeekdayY"
    settingsObject: root.settings
    saveOnEdit: true
}
    SettingsNumberField {
    id: calendarWeekdaySizeField
    width: 58
    height: 30
    value: Config.calendarWeekdayFontSize
    minimum: 8
    maximum: 32
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "calendarWeekdayFontSize"
    settingsObject: root.settings
    saveOnEdit: true
}
    SettingsTextField { id: calendarWeekdayFontField; width: 130; height: 30; text: Config.calendarWeekdayFont; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarWeekdayFont = text; settings.save() } }
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width; height: 30; spacing: 8
    Text { width: 210; height: 30; text: "Дни"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
    id: calendarDayYField
    width: 58
    height: 30
    value: Config.calendarDayY
    minimum: -20
    maximum: 20
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    targetObject: Config
    targetProperty: "calendarDayY"
    settingsObject: root.settings
    saveOnEdit: true
}
    SettingsNumberField {
    id: calendarDaySizeField
    width: 58
    height: 30
    value: Config.calendarDayFontSize
    minimum: 8
    maximum: 32
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 58
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "calendarDayFontSize"
    settingsObject: root.settings
    saveOnEdit: true
}
    SettingsTextField { id: calendarDayFontField; width: 130; height: 30; text: Config.calendarDayFont; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarDayFont = text; settings.save() } }
}

Text {
    text: "Метки заметок"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(13)
}

Row {
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; height: 30; text: "Вид метки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsComboBox {
        id: calendarNoteMarkerStyleBox
        width: 180
        height: 30
        property var values: ["dot", "line", "ring", "note", "frame"]
        model: ["Точка", "Полоска", "Кольцо", "Значок заметки", "Рамка"]
        currentIndex: Math.max(0, values.indexOf(Config.calendarNoteMarkerStyle))
        onItemChosen: function(index) {
            Config.calendarNoteMarkerStyle = values[index]
            settings.save()
        }
        Connections {
            target: Config
            function onCalendarNoteMarkerStyleChanged() {
                calendarNoteMarkerStyleBox.currentIndex = Math.max(0, calendarNoteMarkerStyleBox.values.indexOf(Config.calendarNoteMarkerStyle))
            }
        }
        background: Rectangle { color: Config.settingsBackground; border.color: (calendarNoteMarkerStyleBox.activeFocus || calendarNoteMarkerStyleBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        contentItem: Text { text: calendarNoteMarkerStyleBox.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
    }
}

Row {
    width: parent.width
    height: Config.calendarNoteMarkerStyle === "frame" ? 0 : 30
    visible: Config.calendarNoteMarkerStyle !== "frame"
    spacing: 8
    Text { width: 210; height: 30; text: "Положение метки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsComboBox {
        id: calendarNoteMarkerPositionBox
        width: 180
        height: 30
        property var values: Config.calendarNoteMarkerStyle === "line"
                             ? ["leftCenter", "rightCenter", "topCenter", "bottomCenter"]
                             : ["topLeft", "topCenter", "topRight", "leftCenter", "rightCenter", "bottomLeft", "bottomCenter", "bottomRight"]
        model: Config.calendarNoteMarkerStyle === "line"
               ? ["Слева", "Справа", "Сверху", "Снизу"]
               : ["Сверху слева", "Сверху", "Сверху справа", "Слева", "Справа", "Снизу слева", "Снизу", "Снизу справа"]
        currentIndex: Math.max(0, values.indexOf(Config.calendarNoteMarkerPosition))
        onItemChosen: function(index) {
            Config.calendarNoteMarkerPosition = values[index]
            settings.save()
        }
        Connections {
            target: Config
            function onCalendarNoteMarkerStyleChanged() {
                // A stripe only supports its four edges. Preserve the nearest
                // edge when switching from a corner marker to the stripe style.
                if (Config.calendarNoteMarkerStyle === "line" &&
                    calendarNoteMarkerPositionBox.values.indexOf(Config.calendarNoteMarkerPosition) < 0) {
                    var pos = String(Config.calendarNoteMarkerPosition || "bottomCenter")
                    if (pos.indexOf("top") === 0)
                        Config.calendarNoteMarkerPosition = "topCenter"
                    else if (pos.indexOf("bottom") === 0)
                        Config.calendarNoteMarkerPosition = "bottomCenter"
                    else if (pos.indexOf("left") === 0)
                        Config.calendarNoteMarkerPosition = "leftCenter"
                    else if (pos.indexOf("right") === 0)
                        Config.calendarNoteMarkerPosition = "rightCenter"
                    else
                        Config.calendarNoteMarkerPosition = "bottomCenter"
                    settings.save()
                }
                calendarNoteMarkerPositionBox.currentIndex = Math.max(0, calendarNoteMarkerPositionBox.values.indexOf(Config.calendarNoteMarkerPosition))
            }
            function onCalendarNoteMarkerPositionChanged() {
                calendarNoteMarkerPositionBox.currentIndex = Math.max(0, calendarNoteMarkerPositionBox.values.indexOf(Config.calendarNoteMarkerPosition))
            }
        }
        background: Rectangle { color: Config.settingsBackground; border.color: (calendarNoteMarkerPositionBox.activeFocus || calendarNoteMarkerPositionBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        contentItem: Text { text: calendarNoteMarkerPositionBox.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight }
    }
}

Row {
    width: parent.width
    height: Config.calendarNoteMarkerStyle === "frame" ? 30 : 0
    visible: Config.calendarNoteMarkerStyle === "frame"
    spacing: 8
    SettingsColorField {
        width: parent.width
        label: "Цвет рамки"
        value: String(Config.calendarNoteFrameColor)
        targetObject: Config
        targetProperty: "calendarNoteFrameColor"
        settingsObject: settings
        saveOnEdit: true
        allowAlpha: true
        allowTransparent: false
        fieldWidth: 120
        compact: false
    }
}

Text {
    text: "Анимация появления/исчезновения"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(13)
}

Row {
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Стиль"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsComboBox {
        id: animationCalendarVisibilityBox
        width: 180
        height: 30
        property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
        model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
        currentIndex: Math.max(0, values.indexOf(Config.animationCalendarVisibilityStyle))
        onItemChosen: function(index) { Config.animationCalendarVisibilityStyle = values[index]; settings.save() }
        Connections {
            target: Config
            function onAnimationCalendarVisibilityStyleChanged() { animationCalendarVisibilityBox.currentIndex = Math.max(0, animationCalendarVisibilityBox.values.indexOf(Config.animationCalendarVisibilityStyle)) }
        }
        background: Rectangle { color: Config.settingsBackground; border.color: (animationCalendarVisibilityBox.activeFocus || animationCalendarVisibilityBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        contentItem: Text { text: animationCalendarVisibilityBox.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
    }
}

Row {
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Раскрытие (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: calendarAnimationSlideField
        width: 100; height: 30
        value: Config.animationCalendarSlideDuration
        minimum: 0; maximum: 5000; step: 50; wheelStep: 50; decimals: 0; compact: true
        fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
        targetObject: Config; targetProperty: "animationCalendarSlideDuration"; settingsObject: root.settings; saveOnEdit: true
    }
}

Row {
    width: parent.width
    height: 30
    spacing: 8
    Text { width: 210; text: "Исчезновение (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: calendarAnimationFadeField
        width: 100; height: 30
        value: Config.animationCalendarFadeDuration
        minimum: 0; maximum: 5000; step: 50; wheelStep: 50; decimals: 0; compact: true
        fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
        targetObject: Config; targetProperty: "animationCalendarFadeDuration"; settingsObject: root.settings; saveOnEdit: true
    }
}

    }
}
