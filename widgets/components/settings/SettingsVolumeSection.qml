import QtQuick
import QtQuick.Controls
import "../.."

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 7
    width: parent ? parent.width : 0
    spacing: 10

// -------------------- Volume --------------------
Text { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; text: "Иконки громкости"; color: Config.settingsSubheading; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Громкость"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeIconField; width: 100; height: 30; text: Config.volumeIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (volumeIconField.activeFocus || volumeIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.volumeIcon=text; settings.save() } Connections { target: Config; function onVolumeIconChanged(){volumeIconField.text=Config.volumeIcon} } }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Без звука"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeMutedIconField; width: 100; height: 30; text: Config.volumeMutedIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (volumeMutedIconField.activeFocus || volumeMutedIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.volumeMutedIcon=text; settings.save() } Connections { target: Config; function onVolumeMutedIconChanged(){volumeMutedIconField.text=Config.volumeMutedIcon} } }
}

Text {
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0
    text: "Громкость"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(14)
}
Text {
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0
    text: "Основная полоса и дополнительные аудиопотоки"
    color: Config.settingsSubheading
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(10)
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Интервал опроса громкости (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeUpdateField; width: 100; height: 30; text: String(Config.volumeUpdateInterval); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeUpdateField.activeFocus || volumeUpdateField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeUpdateInterval; n=Math.max(50,Math.min(5000,Math.round(n))); Config.volumeUpdateInterval=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeUpdateField.applyValue(Config.volumeUpdateInterval+host.wheelDelta(wheel, 10)); wheel.accepted=true } } Connections { target: Config; function onVolumeUpdateIntervalChanged(){ volumeUpdateField.text=String(Config.volumeUpdateInterval) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Высота основной строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeMainRowHeightField; width: 100; height: 30; text: String(Config.volumeMainRowHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeMainRowHeightField.activeFocus || volumeMainRowHeightField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainRowHeight; n=Math.max(20,Math.min(80,Math.round(n))); Config.volumeMainRowHeight=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainRowHeightField.applyValue(Config.volumeMainRowHeight+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainRowHeightChanged(){ volumeMainRowHeightField.text=String(Config.volumeMainRowHeight) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Высота строк потоков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeStreamRowHeightField; width: 100; height: 30; text: String(Config.volumeStreamRowHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeStreamRowHeightField.activeFocus || volumeStreamRowHeightField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamRowHeight; n=Math.max(12,Math.min(60,Math.round(n))); Config.volumeStreamRowHeight=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamRowHeightField.applyValue(Config.volumeStreamRowHeight+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamRowHeightChanged(){ volumeStreamRowHeightField.text=String(Config.volumeStreamRowHeight) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Расстояние между потоками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeStreamSpacingField; width: 100; height: 30; text: String(Config.volumeStreamSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeStreamSpacingField.activeFocus || volumeStreamSpacingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamSpacing; n=Math.max(0,Math.min(20,Math.round(n))); Config.volumeStreamSpacing=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamSpacingField.applyValue(Config.volumeStreamSpacing+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamSpacingChanged(){ volumeStreamSpacingField.text=String(Config.volumeStreamSpacing) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Отступ блока слева/справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeHorizontalPaddingField; width: 100; height: 30; text: String(Config.volumeHorizontalPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeHorizontalPaddingField.activeFocus || volumeHorizontalPaddingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeHorizontalPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.volumeHorizontalPadding=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeHorizontalPaddingField.applyValue(Config.volumeHorizontalPadding+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeHorizontalPaddingChanged(){ volumeHorizontalPaddingField.text=String(Config.volumeHorizontalPadding) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Отступ блока сверху/снизу"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeVerticalPaddingField; width: 100; height: 30; text: String(Config.volumeVerticalPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeVerticalPaddingField.activeFocus || volumeVerticalPaddingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeVerticalPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.volumeVerticalPadding=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeVerticalPaddingField.applyValue(Config.volumeVerticalPadding+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeVerticalPaddingChanged(){ volumeVerticalPaddingField.text=String(Config.volumeVerticalPadding) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Ширина основной полосы"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeMainTrackWidthField; width: 100; height: 30; text: String(Config.volumeMainTrackWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeMainTrackWidthField.activeFocus || volumeMainTrackWidthField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainTrackWidth; n=Math.max(40,Math.min(1000,Math.round(n))); Config.volumeMainTrackWidth=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainTrackWidthField.applyValue(Config.volumeMainTrackWidth+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainTrackWidthChanged(){ volumeMainTrackWidthField.text=String(Config.volumeMainTrackWidth) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Высота полосы громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeMainTrackHeightField; width: 100; height: 30; text: String(Config.volumeMainTrackHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeMainTrackHeightField.activeFocus || volumeMainTrackHeightField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainTrackHeight; n=Math.max(1,Math.min(30,Math.round(n))); Config.volumeMainTrackHeight=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainTrackHeightField.applyValue(Config.volumeMainTrackHeight+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainTrackHeightChanged(){ volumeMainTrackHeightField.text=String(Config.volumeMainTrackHeight) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Высота полос потоков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeStreamTrackHeightField; width: 100; height: 30; text: String(Config.volumeStreamTrackHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeStreamTrackHeightField.activeFocus || volumeStreamTrackHeightField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamTrackHeight; n=Math.max(1,Math.min(20,Math.round(n))); Config.volumeStreamTrackHeight=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamTrackHeightField.applyValue(Config.volumeStreamTrackHeight+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamTrackHeightChanged(){ volumeStreamTrackHeightField.text=String(Config.volumeStreamTrackHeight) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Смещение основной полосы Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeMainTrackOffsetField; width: 100; height: 30; text: String(Config.volumeMainTrackOffsetY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.settingsBackground; border.color: (volumeMainTrackOffsetField.activeFocus || volumeMainTrackOffsetField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainTrackOffsetY; n=Math.max(-30,Math.min(30,Math.round(n))); Config.volumeMainTrackOffsetY=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainTrackOffsetField.applyValue(Config.volumeMainTrackOffsetY+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainTrackOffsetYChanged(){ volumeMainTrackOffsetField.text=String(Config.volumeMainTrackOffsetY) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    SettingsCheckBox { width: 210; height: 30; text: "Показывать дополнительные потоки"; checked: Config.volumeShowStreams; onToggled: { Config.volumeShowStreams=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
}

Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Смещение полос потоков Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeStreamTrackOffsetField; width: 100; height: 30; text: String(Config.volumeStreamTrackOffsetY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.settingsBackground; border.color: (volumeStreamTrackOffsetField.activeFocus || volumeStreamTrackOffsetField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamTrackOffsetY; n=Math.max(-20,Math.min(20,Math.round(n))); Config.volumeStreamTrackOffsetY=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamTrackOffsetField.applyValue(Config.volumeStreamTrackOffsetY+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamTrackOffsetYChanged(){ volumeStreamTrackOffsetField.text=String(Config.volumeStreamTrackOffsetY) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Ширина иконки громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeMainIconWidthField; width: 100; height: 30; text: String(Config.volumeMainIconWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeMainIconWidthField.activeFocus || volumeMainIconWidthField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMainIconWidth; n=Math.max(16,Math.min(80,Math.round(n))); Config.volumeMainIconWidth=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMainIconWidthField.applyValue(Config.volumeMainIconWidth+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeMainIconWidthChanged(){ volumeMainIconWidthField.text=String(Config.volumeMainIconWidth) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Размер текста потоков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeStreamLabelFontField; width: 100; height: 30; text: String(Config.volumeStreamLabelFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeStreamLabelFontField.activeFocus || volumeStreamLabelFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeStreamLabelFontSize; n=Math.max(8,Math.min(32,Math.round(n))); Config.volumeStreamLabelFontSize=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeStreamLabelFontField.applyValue(Config.volumeStreamLabelFontSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeStreamLabelFontSizeChanged(){ volumeStreamLabelFontField.text=String(Config.volumeStreamLabelFontSize) } }
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Радиус полос громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeTrackRadiusField; width: 100; height: 30; text: String(Config.volumeTrackRadius); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (volumeTrackRadiusField.activeFocus || volumeTrackRadiusField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeTrackRadius; n=Math.max(0,Math.min(20,Math.round(n))); Config.volumeTrackRadius=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeTrackRadiusField.applyValue(Config.volumeTrackRadius+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onVolumeTrackRadiusChanged(){ volumeTrackRadiusField.text=String(Config.volumeTrackRadius) } }
    }
}

Text {
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 3
    text: "Адаптивные блоки"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(12)
}

Text {
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 3
    text: "Высота блока автоматически растёт по содержимому в пределах этих ограничений."
    color: Config.textMuted
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(9)
    wrapMode: Text.WordWrap
    width: parent.width
}

Row { width: parent.width; height: 30; spacing: 8
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 3
    Text { width: 210; text: "Минимальная высота громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeMinHeightField; width: 100; height: 30; text: String(Config.volumeMinHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
        color: Config.settingsBackground; border.color: (volumeMinHeightField.activeFocus || volumeMinHeightField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMinHeight; n=Math.max(30,Math.min(1000,Math.round(n))); Config.volumeMinHeight=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMinHeightField.applyValue(Config.volumeMinHeight+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
        Connections { target: Config; function onVolumeMinHeightChanged(){ volumeMinHeightField.text=String(Config.volumeMinHeight) } }
    }
}

Row { width: parent.width; height: 30; spacing: 8
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 3
    Text { width: 210; text: "Максимальная высота громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeMaxHeightField; width: 100; height: 30; text: String(Config.volumeMaxHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
        color: Config.settingsBackground; border.color: (volumeMaxHeightField.activeFocus || volumeMaxHeightField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.volumeMaxHeight; n=Math.max(100,Math.min(2000,Math.round(n))); Config.volumeMaxHeight=n; text=String(n); settings.save() }
        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ volumeMaxHeightField.applyValue(Config.volumeMaxHeight+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
        Connections { target: Config; function onVolumeMaxHeightChanged(){ volumeMaxHeightField.text=String(Config.volumeMaxHeight) } }
    }
}

}
