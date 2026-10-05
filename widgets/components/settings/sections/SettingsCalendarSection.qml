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

    }
}
