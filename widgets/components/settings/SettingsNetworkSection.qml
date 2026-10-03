import QtQuick
import QtQuick.Controls
import "../.."

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 6
    width: parent ? parent.width : 0
    spacing: 10

                Text {
                    visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1
                    text: "Сеть"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1
                    text: "Отображение сетевого трафика и общий интервал system monitor"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Интервал обновления данных (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField {
                        id: networkIntervalField
                        width: 100; height: 30; text: String(Config.systemMonitorInterval)
                        color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                        background: Rectangle { color: Config.settingsBackground; border.color: (networkIntervalField.activeFocus || networkIntervalField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.systemMonitorInterval; n=Math.max(200,Math.min(10000,Math.round(n))); Config.systemMonitorInterval=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text)
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkIntervalField.applyValue(Config.systemMonitorInterval+host.wheelDelta(wheel, 100)); wheel.accepted=true } }
                        Connections { target: Config; function onSystemMonitorIntervalChanged() { networkIntervalField.text=String(Config.systemMonitorInterval) } }
                    }
                }

                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ блока слева/справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: networkPaddingField; width: 100; height: 30; text: String(Config.networkHorizontalPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (networkPaddingField.activeFocus || networkPaddingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkHorizontalPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.networkHorizontalPadding=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkPaddingField.applyValue(Config.networkHorizontalPadding+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkHorizontalPaddingChanged(){ networkPaddingField.text=String(Config.networkHorizontalPadding) } }
                    }
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ иконки слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: networkIconPaddingField; width: 100; height: 30; text: String(Config.networkIconLeftPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (networkIconPaddingField.activeFocus || networkIconPaddingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkIconLeftPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.networkIconLeftPadding=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkIconPaddingField.applyValue(Config.networkIconLeftPadding+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkIconLeftPaddingChanged(){ networkIconPaddingField.text=String(Config.networkIconLeftPadding) } }
                    }
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ширина колонки иконки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: networkIconColumnWidthField; width: 100; height: 30; text: String(Config.networkIconColumnWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (networkIconColumnWidthField.activeFocus || networkIconColumnWidthField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkIconColumnWidth; n=Math.max(16,Math.min(80,Math.round(n))); Config.networkIconColumnWidth=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkIconColumnWidthField.applyValue(Config.networkIconColumnWidth+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkIconColumnWidthChanged(){ networkIconColumnWidthField.text=String(Config.networkIconColumnWidth) } }
                    }
                }

                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    SettingsCheckBox { width: 210; height: 30; text: "Показывать Upload"; checked: Config.networkShowUpload; onToggled: { Config.networkShowUpload=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    SettingsCheckBox { width: 210; height: 30; text: "Показывать Download"; checked: Config.networkShowDownload; onToggled: { Config.networkShowDownload=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
                }

                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: networkRowHeightField; width: 100; height: 30; text: String(Config.networkRowHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (networkRowHeightField.activeFocus || networkRowHeightField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkRowHeight; n=Math.max(12,Math.min(60,Math.round(n))); Config.networkRowHeight=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkRowHeightField.applyValue(Config.networkRowHeight+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkRowHeightChanged(){ networkRowHeightField.text=String(Config.networkRowHeight) } }
                    }
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: networkRowSpacingField; width: 100; height: 30; text: String(Config.networkRowSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (networkRowSpacingField.activeFocus || networkRowSpacingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkRowSpacing; n=Math.max(0,Math.min(30,Math.round(n))); Config.networkRowSpacing=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkRowSpacingField.applyValue(Config.networkRowSpacing+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkRowSpacingChanged(){ networkRowSpacingField.text=String(Config.networkRowSpacing) } }
                    }
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Размер иконки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: networkIconSizeField; width: 100; height: 30; text: String(Config.networkIconSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (networkIconSizeField.activeFocus || networkIconSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkIconSize; n=Math.max(8,Math.min(40,Math.round(n))); Config.networkIconSize=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkIconSizeField.applyValue(Config.networkIconSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkIconSizeChanged(){ networkIconSizeField.text=String(Config.networkIconSize) } }
                    }
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Размер текста"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: networkFontSizeField; width: 100; height: 30; text: String(Config.networkValueFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (networkFontSizeField.activeFocus || networkFontSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkValueFontSize; n=Math.max(8,Math.min(32,Math.round(n))); Config.networkValueFontSize=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkFontSizeField.applyValue(Config.networkValueFontSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkValueFontSizeChanged(){ networkFontSizeField.text=String(Config.networkValueFontSize) } }
                    }
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ значений справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: networkRightPaddingField; width: 100; height: 30; text: String(Config.networkRightPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (networkRightPaddingField.activeFocus || networkRightPaddingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.networkRightPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.networkRightPadding=n; text=String(n); settings.save() }
                        onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ networkRightPaddingField.applyValue(Config.networkRightPadding+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onNetworkRightPaddingChanged(){ networkRightPaddingField.text=String(Config.networkRightPadding) } }
                    }
                }
}
