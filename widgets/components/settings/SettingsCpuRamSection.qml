import QtQuick
import QtQuick.Controls
import "../.."

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 5
    width: parent ? parent.width : 0
    spacing: 10

    Text {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        text: "CPU и RAM"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    Text {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        text: "Настройки полос CPU и RAM"
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Интервал обновления CPU (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: cpuSettingsIntervalField
            width: 100; height: 30
            text: String(Config.cpuUpdateInterval)
            color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true
            inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (cpuSettingsIntervalField.activeFocus || cpuSettingsIntervalField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuUpdateInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.cpuUpdateInterval=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuSettingsIntervalField.applyValue(Config.cpuUpdateInterval+host.wheelDelta(wheel, 100)); wheel.accepted=true } }
            Connections { target: Config; function onCpuUpdateIntervalChanged() { cpuSettingsIntervalField.text = String(Config.cpuUpdateInterval) } }
        }
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Толщина полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: cpuBarThicknessField
            width: 100; height: 30; text: String(Config.cpuBarThickness)
            color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (cpuBarThicknessField.activeFocus || cpuBarThicknessField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuBarThickness; n=Math.max(1,Math.min(30,Math.round(n))); Config.cpuBarThickness=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuBarThicknessField.applyValue(Config.cpuBarThickness+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
            Connections { target: Config; function onCpuBarThicknessChanged() { cpuBarThicknessField.text=String(Config.cpuBarThickness) } }
        }
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Ширина полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: cpuBarWidthField
            width: 100; height: 30; text: String(Config.cpuBarWidth)
            color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (cpuBarWidthField.activeFocus || cpuBarWidthField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuBarWidth; n=Math.max(40,Math.min(1000,Math.round(n))); Config.cpuBarWidth=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuBarWidthField.applyValue(Config.cpuBarWidth+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
            Connections { target: Config; function onCpuBarWidthChanged() { cpuBarWidthField.text=String(Config.cpuBarWidth) } }
        }
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Высота строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: cpuRowHeightField
            width: 100; height: 30; text: String(Config.cpuRowHeight)
            color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (cpuRowHeightField.activeFocus || cpuRowHeightField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuRowHeight; n=Math.max(10,Math.min(60,Math.round(n))); Config.cpuRowHeight=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuRowHeightField.applyValue(Config.cpuRowHeight+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
            Connections { target: Config; function onCpuRowHeightChanged() { cpuRowHeightField.text=String(Config.cpuRowHeight) } }
        }
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: cpuRowSpacingField
            width: 100; height: 30; text: String(Config.cpuRowSpacing)
            color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (cpuRowSpacingField.activeFocus || cpuRowSpacingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuRowSpacing; n=Math.max(0,Math.min(30,Math.round(n))); Config.cpuRowSpacing=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuRowSpacingField.applyValue(Config.cpuRowSpacing+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
            Connections { target: Config; function onCpuRowSpacingChanged() { cpuRowSpacingField.text=String(Config.cpuRowSpacing) } }
        }
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Отступ подписи слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: cpuLabelPaddingField; width: 100; height: 30; text: String(Config.cpuLabelLeftPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (cpuLabelPaddingField.activeFocus || cpuLabelPaddingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuLabelLeftPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.cpuLabelLeftPadding=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuLabelPaddingField.applyValue(Config.cpuLabelLeftPadding+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuLabelLeftPaddingChanged(){ cpuLabelPaddingField.text=String(Config.cpuLabelLeftPadding) } }
        }
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Смещение полос слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: cpuBarOffsetField; width: 100; height: 30; text: String(Config.cpuBarLeftOffset); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (cpuBarOffsetField.activeFocus || cpuBarOffsetField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuBarLeftOffset; n=Math.max(0,Math.min(200,Math.round(n))); Config.cpuBarLeftOffset=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuBarOffsetField.applyValue(Config.cpuBarLeftOffset+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuBarLeftOffsetChanged(){ cpuBarOffsetField.text=String(Config.cpuBarLeftOffset) } }
        }
    }

    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 0
        width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Радиус полос"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: cpuBarRadiusField; width: 100; height: 30; text: String(Config.cpuBarRadius); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (cpuBarRadiusField.activeFocus || cpuBarRadiusField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuBarRadius; n=Math.max(0,Math.min(40,Math.round(n))); Config.cpuBarRadius=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuBarRadiusField.applyValue(Config.cpuBarRadius+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuBarRadiusChanged(){ cpuBarRadiusField.text=String(Config.cpuBarRadius) } }
        }
    }

    Text { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; text: "График CPU"; color: Config.accent; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12) }

    Row { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Ширина сегмента графика"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: cpuGraphSlotField; width: 100; height: 30; text: String(Config.cpuGraphSegmentSlotWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (cpuGraphSlotField.activeFocus || cpuGraphSlotField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuGraphSegmentSlotWidth; n=Math.max(1,Math.min(20,Math.round(n))); Config.cpuGraphSegmentSlotWidth=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuGraphSlotField.applyValue(Config.cpuGraphSegmentSlotWidth+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuGraphSegmentSlotWidthChanged(){ cpuGraphSlotField.text=String(Config.cpuGraphSegmentSlotWidth) } }
        }
    }

    Row { visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Толщина полос графика"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: cpuGraphBarWidthField; width: 100; height: 30; text: String(Config.cpuGraphBarWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (cpuGraphBarWidthField.activeFocus || cpuGraphBarWidthField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.cpuGraphBarWidth; n=Math.max(1,Math.min(10,Math.round(n))); Config.cpuGraphBarWidth=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ cpuGraphBarWidthField.applyValue(Config.cpuGraphBarWidth+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onCpuGraphBarWidthChanged(){ cpuGraphBarWidthField.text=String(Config.cpuGraphBarWidth) } }
        }
    }



    Row {
        visible: host.currentOtherTab === 5 && host.currentOtherSubTab === 1
        width: parent.width; height: 30; spacing: 8
        SettingsCheckBox {
            width: 210; height: 30; text: "Показывать RAM"; checked: Config.cpuShowRam
            onToggled: { Config.cpuShowRam=checked; settings.save() }
            contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter }
        }
    }

}
