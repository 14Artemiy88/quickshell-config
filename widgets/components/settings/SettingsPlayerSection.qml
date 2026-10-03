import QtQuick
import QtQuick.Controls
import "../.."

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0

    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        text: "Плеер"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        width: parent.width
        height: 34
        spacing: 8

        Text {
            width: 210
            text: "Текст при отсутствии воспроизведения"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        SettingsTextField {
            id: playerSilenceField
            width: 140
            height: 30
            text: Config.playerSilenceText
            color: Config.text
            selectionColor: Config.accent
            selectedTextColor: Config.black
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            activeFocusOnTab: true
            background: Rectangle {
                color: Config.settingsBackground
                border.color: (playerSilenceField.activeFocus || playerSilenceField.pointerHovered) ? Config.accent : Config.baseColor
                border.width: 1
                radius: 4
            }
            onEditingFinished: {
                Config.playerSilenceText = text
                settings.save()
            }
            Connections {
                target: Config
                function onPlayerSilenceTextChanged() {
                    playerSilenceField.text = Config.playerSilenceText
                }
            }
        }
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        width: parent.width
        height: 34
        spacing: 8

        Text {
            width: 210
            text: "Основной шрифт плеера"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }

        SettingsTextField {
            id: playerFontField
            width: 140
            height: 30
            text: Config.playerFont
            color: Config.text
            selectionColor: Config.accent
            selectedTextColor: Config.black
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            activeFocusOnTab: true
            background: Rectangle {
                color: Config.settingsBackground
                border.color: (playerFontField.activeFocus || playerFontField.pointerHovered) ? Config.accent : Config.baseColor
                border.width: 1
                radius: 4
            }
            onEditingFinished: {
                Config.playerFont = text
                settings.save()
            }
            Connections {
                target: Config
                function onPlayerFontChanged() {
                    playerFontField.text = Config.playerFont
                }
            }
        }
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        Text { width: 210; text: "Размер текста Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: silenceSizeField; width: 72; height: 30; text: String(Config.playerSilenceFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerSilenceFontSize; n=Math.max(8,Math.min(100,Math.round(n))); Config.playerSilenceFontSize=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ silenceSizeField.applyValue(Config.playerSilenceFontSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
        }
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        Text { width: 210; text: "Размер длинного Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: silenceLongSizeField; width: 72; height: 30; text: String(Config.playerSilenceLongFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerSilenceLongFontSize; n=Math.max(8,Math.min(100,Math.round(n))); Config.playerSilenceLongFontSize=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ silenceLongSizeField.applyValue(Config.playerSilenceLongFontSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
        }
    }
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Ширина области Silence"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: playerSilenceWidthField; width: 72; height: 30; text: String(Config.playerSilenceWidth); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (playerSilenceWidthField.activeFocus || playerSilenceWidthField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerSilenceWidth; n=Math.max(100,Math.min(600,Math.round(n))); Config.playerSilenceWidth=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerSilenceWidthField.applyValue(Config.playerSilenceWidth+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerSilenceWidthChanged(){ playerSilenceWidthField.text=String(Config.playerSilenceWidth) } }
        }
    }
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 1
        text: "Оставшееся время"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Размер оставшегося времени"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: playerTimeFontSizeField
            width: 72
            height: 30
            text: String(Config.playerTimeFontSize)
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            horizontalAlignment: Text.AlignHCenter
            activeFocusOnTab: true
            inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (playerTimeFontSizeField.activeFocus || playerTimeFontSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerTimeFontSize; n=Math.max(8,Math.min(48,Math.round(n))); Config.playerTimeFontSize=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { playerTimeFontSizeField.applyValue(Config.playerTimeFontSize + host.wheelDelta(wheel, 1)); wheel.accepted=true } }
            Connections { target: Config; function onPlayerTimeFontSizeChanged() { playerTimeFontSizeField.text=String(Config.playerTimeFontSize) } }
        }
    }
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Шрифт оставшегося времени"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: playerTimeFontField; width: 140; height: 30; text: Config.playerTimeFont; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerTimeFontField.activeFocus || playerTimeFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: { var v=text.trim(); if (v.length > 0) Config.playerTimeFont=v; text=Config.playerTimeFont; settings.save() }
            Connections { target: Config; function onPlayerTimeFontChanged() { playerTimeFontField.text=Config.playerTimeFont } }
        }
    }
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Отступ оставшегося времени справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: playerTimeRightPaddingField
            width: 72
            height: 30
            text: String(Config.playerTimeRightPadding)
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            horizontalAlignment: Text.AlignHCenter
            activeFocusOnTab: true
            inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (playerTimeRightPaddingField.activeFocus || playerTimeRightPaddingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerTimeRightPadding; n=Math.max(0,Math.min(100,Math.round(n))); Config.playerTimeRightPadding=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { playerTimeRightPaddingField.applyValue(Config.playerTimeRightPadding + host.wheelDelta(wheel, 1)); wheel.accepted=true } }
            Connections { target: Config; function onPlayerTimeRightPaddingChanged() { playerTimeRightPaddingField.text=String(Config.playerTimeRightPadding) } }
        }
    }
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 2
        text: "Метаданные"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        width: parent.width
        height: 34
        spacing: 8

        Text {
            width: 210
            text: "Шрифт метаданных плеера"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }

        SettingsTextField {
            id: playerMetaFontField
            width: 140
            height: 30
            text: Config.playerMetaFont
            color: Config.text
            selectionColor: Config.accent
            selectedTextColor: Config.black
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            activeFocusOnTab: true
            background: Rectangle {
                color: Config.settingsBackground
                border.color: (playerMetaFontField.activeFocus || playerMetaFontField.pointerHovered) ? Config.accent : Config.baseColor
                border.width: 1
                radius: 4
            }
            onEditingFinished: {
                Config.playerMetaFont = text
                settings.save()
            }
            Connections {
                target: Config
                function onPlayerMetaFontChanged() {
                    playerMetaFontField.text = Config.playerMetaFont
                }
            }
        }
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        Text { width: 210; text: "Размер основной строки метаданных"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsTextField { id: metaSizeField; width: 72; height: 30; text: String(Config.playerMetaFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerMetaFontSize; n=Math.max(8,Math.min(48,Math.round(n))); Config.playerMetaFontSize=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ metaSizeField.applyValue(Config.playerMetaFontSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
        }
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        Text { width: 210; text: "Размер остальных строк"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: metaSecondarySizeField; width: 72; height: 30; text: String(Config.playerMetaSecondaryFontSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerMetaSecondaryFontSize; n=Math.max(8,Math.min(48,Math.round(n))); Config.playerMetaSecondaryFontSize=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ metaSecondarySizeField.applyValue(Config.playerMetaSecondaryFontSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
        }
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: metaSpacingField; width: 72; height: 30; text: String(Config.playerMetaLineSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle {
            color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerMetaLineSpacing; n=Math.max(0,Math.min(100,Math.round(n))); Config.playerMetaLineSpacing=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ metaSpacingField.applyValue(Config.playerMetaLineSpacing+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
        }
    }
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Отступ метаданных по X"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: playerMetaXPadField; width: 72; height: 30; text: String(Config.playerMetadataXPadding); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (playerMetaXPadField.activeFocus || playerMetaXPadField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerMetadataXPadding; n=Math.max(0,Math.min(100,Math.round(n))); Config.playerMetadataXPadding=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerMetaXPadField.applyValue(Config.playerMetadataXPadding+host.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onPlayerMetadataXPaddingChanged(){playerMetaXPadField.text=String(Config.playerMetadataXPadding)}}
        }
    }
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Положение метаданных по Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: playerMetaYField; width: 72; height: 30; text: String(Config.playerMetadataY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (playerMetaYField.activeFocus || playerMetaYField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerMetadataY; n=Math.max(0,Math.min(100,Math.round(n))); Config.playerMetadataY=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerMetaYField.applyValue(Config.playerMetadataY+host.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onPlayerMetadataYChanged(){playerMetaYField.text=String(Config.playerMetadataY)}}
        }
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        SettingsCheckBox { id: boldArtistBox; width: 210; height: 30; text: "Жирный исполнитель"; checked: Config.playerBoldArtist; onToggled: { Config.playerBoldArtist=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3
        width: parent.width
        height: 30
        spacing: 8
        SettingsCheckBox {
            id: playerTextOutlineBox
            width: 210
            height: 30
            text: "Обводка текста"
            checked: Config.playerTextOutlineEnabled
            onToggled: { Config.playerTextOutlineEnabled = checked; settings.save() }
            contentItem: Text {
                text: parent.text
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                leftPadding: parent.indicator.width + 5
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 3 && Config.playerTextOutlineEnabled
        width: parent.width
        height: 30
        spacing: 8
        Text {
            width: 210
            text: "Цвет обводки"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }
        SettingsTextField {
            id: playerTextOutlineColorField
            width: 90
            height: 30
            text: Config.playerTextOutlineColor
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            horizontalAlignment: Text.AlignHCenter
            activeFocusOnTab: true
            background: Rectangle { color: Config.settingsBackground; border.color: (playerTextOutlineColorField.activeFocus || playerTextOutlineColorField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: {
                var value = text.trim()
                if (/^#[0-9A-Fa-f]{6}$/.test(value)) { Config.playerTextOutlineColor = value; text = value; settings.save() }
                else text = Config.playerTextOutlineColor
            }
            Connections { target: Config; function onPlayerTextOutlineColorChanged() { playerTextOutlineColorField.text = Config.playerTextOutlineColor } }
        }
    }
    Text { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 4; text: "Иконки и управление"; color: Config.settingsSubheading; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
    Column {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 4
        width: parent.width
        spacing: 4
        Row {
            width: parent.width
            height: 18
            spacing: 8
            Text { width: 58; text: "Иконка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
            Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter }
        }
        Row {
            width: parent.width
            height: 30
            spacing: 8
            SettingsTextField { id: playerPlayingIconField; width: 58; height: 30; text: Config.playerPlayingIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerPlayingIconField.activeFocus || playerPlayingIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.playerPlayingIcon=text; settings.save() } Connections { target: Config; function onPlayerPlayingIconChanged(){playerPlayingIconField.text=Config.playerPlayingIcon} } }
            SettingsTextField { id: playerPlayingIconSizeField; width: 58; height: 30; text: String(Config.playerPlayingIconSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (playerPlayingIconSizeField.activeFocus || playerPlayingIconSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerPlayingIconSize; n=Math.max(8,Math.min(64,Math.round(n))); Config.playerPlayingIconSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerPlayingIconSizeField.applyValue(Config.playerPlayingIconSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerPlayingIconSizeChanged(){ playerPlayingIconSizeField.text=String(Config.playerPlayingIconSize) } } }
            SettingsTextField { id: playerPlayingIconYField; width: 58; height: 30; text: String(Config.playerPlayingIconY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerPlayingIconYField.activeFocus || playerPlayingIconYField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerPlayingIconY; n=Math.max(-100,Math.min(100,Math.round(n))); Config.playerPlayingIconY=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerPlayingIconYField.applyValue(Config.playerPlayingIconY+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerPlayingIconYChanged(){ playerPlayingIconYField.text=String(Config.playerPlayingIconY) } } }
        }
        Row {
            width: parent.width
            height: 30
            spacing: 8
            SettingsTextField { id: playerPausedIconField; width: 58; height: 30; text: Config.playerPausedIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerPausedIconField.activeFocus || playerPausedIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.playerPausedIcon=text; settings.save() } Connections { target: Config; function onPlayerPausedIconChanged(){playerPausedIconField.text=Config.playerPausedIcon} } }
            SettingsTextField { id: playerPausedIconSizeField; width: 58; height: 30; text: String(Config.playerPausedIconSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (playerPausedIconSizeField.activeFocus || playerPausedIconSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerPausedIconSize; n=Math.max(8,Math.min(64,Math.round(n))); Config.playerPausedIconSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerPausedIconSizeField.applyValue(Config.playerPausedIconSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerPausedIconSizeChanged(){ playerPausedIconSizeField.text=String(Config.playerPausedIconSize) } } }
            SettingsTextField { id: playerPausedIconYField; width: 58; height: 30; text: String(Config.playerPausedIconY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerPausedIconYField.activeFocus || playerPausedIconYField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerPausedIconY; n=Math.max(-100,Math.min(100,Math.round(n))); Config.playerPausedIconY=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerPausedIconYField.applyValue(Config.playerPausedIconY+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerPausedIconYChanged(){ playerPausedIconYField.text=String(Config.playerPausedIconY) } } }
        }
        Row {
            width: parent.width
            height: 30
            spacing: 8
            SettingsTextField { id: playerNextIconField; width: 58; height: 30; text: Config.playerNextIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerNextIconField.activeFocus || playerNextIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.playerNextIcon=text; settings.save() } Connections { target: Config; function onPlayerNextIconChanged(){playerNextIconField.text=Config.playerNextIcon} } }
            SettingsTextField { id: playerNextIconSizeField; width: 58; height: 30; text: String(Config.playerNextIconSize); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (playerNextIconSizeField.activeFocus || playerNextIconSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerNextIconSize; n=Math.max(8,Math.min(64,Math.round(n))); Config.playerNextIconSize=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerNextIconSizeField.applyValue(Config.playerNextIconSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerNextIconSizeChanged(){ playerNextIconSizeField.text=String(Config.playerNextIconSize) } } }
            SettingsTextField { id: playerNextIconYField; width: 58; height: 30; text: String(Config.playerNextIconY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (playerNextIconYField.activeFocus || playerNextIconYField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerNextIconY; n=Math.max(-100,Math.min(100,Math.round(n))); Config.playerNextIconY=n; text=String(n); settings.save() } onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerNextIconYField.applyValue(Config.playerNextIconY+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerNextIconYChanged(){ playerNextIconYField.text=String(Config.playerNextIconY) } } }
        }
    }
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 4
        text: "Полоска прогресса"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }
    Row { width: parent.width; height: 30; spacing: 8
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5
        SettingsCheckBox { id: showProgressBox; width: 210; height: 30; text: "Показывать прогресс"; checked: Config.playerShowProgress; onToggled: { Config.playerShowProgress=checked; settings.save() } contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width+5; verticalAlignment: Text.AlignVCenter } }
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5
        width: parent.width
        height: 24
        spacing: 8
        Item { width: 210; height: 24 }
        Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Text { width: 58; text: "Высота"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Text { width: 58; text: "Смещение"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Полоса прогресса"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsTextField { id: playerProgressYField; width: 72; height: 30; text: String(Config.playerProgressY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (playerProgressYField.activeFocus || playerProgressYField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                                function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerProgressY; n=Math.max(0,Math.min(100,Math.round(n))); Config.playerProgressY=n; text=String(n); settings.save() }
                                onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerProgressYField.applyValue(Config.playerProgressY+host.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onPlayerProgressYChanged(){playerProgressYField.text=String(Config.playerProgressY)}}
                            }
        SettingsTextField { id: playerProgressTrackHeightField; width: 72; height: 30; text: String(Config.playerProgressTrackHeight); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (playerProgressTrackHeightField.activeFocus || playerProgressTrackHeightField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                                function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerProgressTrackHeight; n=Math.max(1,Math.min(20,Math.round(n))); Config.playerProgressTrackHeight=n; text=String(n); settings.save() }
                                onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerProgressTrackHeightField.applyValue(Config.playerProgressTrackHeight+host.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onPlayerProgressTrackHeightChanged(){playerProgressTrackHeightField.text=String(Config.playerProgressTrackHeight)}}
                            }
        SettingsTextField { id: playerProgressTrackOffsetYField; width: 72; height: 30; text: String(Config.playerProgressTrackOffsetY); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.settingsBackground; border.color: (playerProgressTrackOffsetYField.activeFocus || playerProgressTrackOffsetYField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                                function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerProgressTrackOffsetY; n=Math.max(-10,Math.min(20,Math.round(n))); Config.playerProgressTrackOffsetY=n; text=String(n); settings.save() }
                                onEditingFinished: applyValue(text); MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ playerProgressTrackOffsetYField.applyValue(Config.playerProgressTrackOffsetY+host.wheelDelta(wheel, 1)); wheel.accepted=true } } Connections { target: Config; function onPlayerProgressTrackOffsetYChanged(){ playerProgressTrackOffsetYField.text=String(Config.playerProgressTrackOffsetY) } }
                            }
    }
    Row { visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5; width: parent.width; height: 30; spacing: 8
        Text { width: 210; text: "Прозрачность обложки (0–1)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField { id: playerCoverOpacityField; width: 72; height: 30; text: Number(Config.playerCoverOpacity).toFixed(2); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.settingsBackground; border.color: (playerCoverOpacityField.activeFocus || playerCoverOpacityField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v){ var n=Number(v); if(!isFinite(n)) n=Config.playerCoverOpacity; n=Math.max(0,Math.min(1,Math.round(n*20)/20)); Config.playerCoverOpacity=n; text=Number(n).toFixed(2); settings.save() }
            onEditingFinished: applyValue(text); MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{playerCoverOpacityField.applyValue(Config.playerCoverOpacity+host.wheelDelta(wheel, 0.05));wheel.accepted=true}} Connections{target:Config;function onPlayerCoverOpacityChanged(){playerCoverOpacityField.text=Number(Config.playerCoverOpacity).toFixed(2)}}
        }
    }
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 5
        text: "Обложка и фон"
        color: Config.settingsSubheading
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 6
        width: parent.width
        height: 30
        spacing: 8
        SettingsCheckBox {
            id: playerBlurEnabledBox
            width: 210
            height: 30
            text: "Блюр фона плеера"
            checked: Config.playerBlurEnabled
            onToggled: { Config.playerBlurEnabled = checked; settings.save() }
            contentItem: Text { text: parent.text; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); leftPadding: parent.indicator.width + 5; verticalAlignment: Text.AlignVCenter }
        }
    }
    Text {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 6
        text: "Размывает содержимое позади плеера; сила блюра задаётся композитором Niri."
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(9)
        wrapMode: Text.WordWrap
        width: parent.width
    }
    Row {
        visible: host.currentOtherTab === 2 && host.currentOtherSubTab === 6
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 210; text: "Радиус области блюра (0–40)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: playerBlurRadiusField
            width: 72
            height: 30
            text: String(Config.playerBlurRadius)
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            horizontalAlignment: Text.AlignHCenter
            activeFocusOnTab: true
            inputMethodHints: Qt.ImhDigitsOnly
            background: Rectangle { color: Config.settingsBackground; border.color: (playerBlurRadiusField.activeFocus || playerBlurRadiusField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.playerBlurRadius; n=Math.max(0,Math.min(40,Math.round(n))); Config.playerBlurRadius=n; text=String(n); settings.save() }
            onEditingFinished: applyValue(text)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel => { playerBlurRadiusField.applyValue(Config.playerBlurRadius + host.wheelDelta(wheel, 1)); wheel.accepted = true } }
            Connections { target: Config; function onPlayerBlurRadiusChanged() { playerBlurRadiusField.text = String(Config.playerBlurRadius) } }
        }
    }
}
