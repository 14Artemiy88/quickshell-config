import QtQuick
import QtQuick.Controls
import "../.."

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
    SettingsTextField { id: calendarArrowSizeField; width: 58; height: 30; text: String(Config.calendarPreviousSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v) { var n=Number(v); if(!isFinite(n)) n=Config.calendarPreviousSize; n=Math.max(8,Math.min(64,Math.round(n))); Config.calendarPreviousSize=n; text=String(n); settings.save() } onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { calendarArrowSizeField.apply(Config.calendarPreviousSize + host.wheelDelta(wheel, 1)); wheel.accepted = true } } }
    SettingsTextField { id: calendarPrevXField; width: 58; height: 30; text: String(Config.calendarPreviousX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v) { var n=Number(v); if(!isFinite(n)) n=Config.calendarPreviousX; n=Math.max(-20,Math.min(20,Math.round(n))); Config.calendarPreviousX=n; text=String(n); settings.save() } onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { calendarPrevXField.apply(Config.calendarPreviousX + host.wheelDelta(wheel, 1)); wheel.accepted = true } } }
    SettingsTextField { id: calendarArrowYField; width: 58; height: 30; text: String(Config.calendarArrowY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v) { var n=Number(v); if(!isFinite(n)) n=Config.calendarArrowY; n=Math.max(-20,Math.min(20,Math.round(n))); Config.calendarArrowY=n; text=String(n); settings.save() } onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { calendarArrowYField.apply(Config.calendarArrowY + host.wheelDelta(wheel, 1)); wheel.accepted = true } } }
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width; height: 30; spacing: 8
    Text { width: 210; height: 30; text: "Следующий месяц"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
    SettingsTextField { id: calendarNextIconField; width: 80; height: 30; text: Config.calendarNextIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarNextIcon = text; settings.save() } }
    SettingsTextField { id: calendarNextSizeField; width: 58; height: 30; text: String(Config.calendarNextSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v) { var n=Number(v); if(!isFinite(n)) n=Config.calendarNextSize; n=Math.max(8,Math.min(64,Math.round(n))); Config.calendarNextSize=n; text=String(n); settings.save() } onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { calendarNextSizeField.apply(Config.calendarNextSize + host.wheelDelta(wheel, 1)); wheel.accepted = true } } }
    SettingsTextField { id: calendarNextXField; width: 58; height: 30; text: String(Config.calendarNextX); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v) { var n=Number(v); if(!isFinite(n)) n=Config.calendarNextX; n=Math.max(-20,Math.min(20,Math.round(n))); Config.calendarNextX=n; text=String(n); settings.save() } onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { calendarNextXField.apply(Config.calendarNextX + host.wheelDelta(wheel, 1)); wheel.accepted = true } } }
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
    SettingsTextField { id: calendarTitleY2Field; width: 58; height: 30; text: String(Config.calendarTitleY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v){var n=Number(v);if(!isFinite(n))n=Config.calendarTitleY;n=Math.max(-20,Math.min(20,Math.round(n)));Config.calendarTitleY=n;text=String(n);settings.save()} onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{calendarTitleY2Field.apply(Config.calendarTitleY+host.wheelDelta(wheel,1));wheel.accepted=true} } }
    SettingsTextField { id: calendarTitleSizeField2; width: 58; height: 30; text: String(Config.calendarTitleFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v){var n=Number(v);if(!isFinite(n))n=Config.calendarTitleFontSize;n=Math.max(8,Math.min(48,Math.round(n)));Config.calendarTitleFontSize=n;text=String(n);settings.save()} onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{calendarTitleSizeField2.apply(Config.calendarTitleFontSize+host.wheelDelta(wheel,1));wheel.accepted=true} } }
    SettingsTextField { id: calendarTitleFontField; width: 130; height: 30; text: Config.calendarTitleFont; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarTitleFont = text; settings.save() } }
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width; height: 30; spacing: 8
    Text { width: 210; height: 30; text: "Дни недели"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: calendarWeekdayYField; width: 58; height: 30; text: String(Config.calendarWeekdayY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v){var n=Number(v);if(!isFinite(n))n=Config.calendarWeekdayY;n=Math.max(-20,Math.min(20,Math.round(n)));Config.calendarWeekdayY=n;text=String(n);settings.save()} onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{calendarWeekdayYField.apply(Config.calendarWeekdayY+host.wheelDelta(wheel,1));wheel.accepted=true} } }
    SettingsTextField { id: calendarWeekdaySizeField; width: 58; height: 30; text: String(Config.calendarWeekdayFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v){var n=Number(v);if(!isFinite(n))n=Config.calendarWeekdayFontSize;n=Math.max(8,Math.min(32,Math.round(n)));Config.calendarWeekdayFontSize=n;text=String(n);settings.save()} onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{calendarWeekdaySizeField.apply(Config.calendarWeekdayFontSize+host.wheelDelta(wheel,1));wheel.accepted=true} } }
    SettingsTextField { id: calendarWeekdayFontField; width: 130; height: 30; text: Config.calendarWeekdayFont; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarWeekdayFont = text; settings.save() } }
}

Row {
    visible: host.currentOtherTab === 8 && host.currentOtherSubTab === 0
    width: parent.width; height: 30; spacing: 8
    Text { width: 210; height: 30; text: "Дни"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: calendarDayYField; width: 58; height: 30; text: String(Config.calendarDayY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v){var n=Number(v);if(!isFinite(n))n=Config.calendarDayY;n=Math.max(-20,Math.min(20,Math.round(n)));Config.calendarDayY=n;text=String(n);settings.save()} onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{calendarDayYField.apply(Config.calendarDayY+host.wheelDelta(wheel,1));wheel.accepted=true} } }
    SettingsTextField { id: calendarDaySizeField; width: 58; height: 30; text: String(Config.calendarDayFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; function apply(v){var n=Number(v);if(!isFinite(n))n=Config.calendarDayFontSize;n=Math.max(8,Math.min(32,Math.round(n)));Config.calendarDayFontSize=n;text=String(n);settings.save()} onEditingFinished: apply(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{calendarDaySizeField.apply(Config.calendarDayFontSize+host.wheelDelta(wheel,1));wheel.accepted=true} } }
    SettingsTextField { id: calendarDayFontField; width: 130; height: 30; text: Config.calendarDayFont; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; onEditingFinished: { Config.calendarDayFont = text; settings.save() } }
}

    }
}
