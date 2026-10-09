import QtQuick
import QtQuick.Controls
import "../primitives"
import "../../.."

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0

    visible: host && host.currentOtherTab === 10 && host.currentOtherSubTab === 1

    Text {
        text: "Время очереди"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    SettingsCheckBox {
        id: showQueueTimeCheckBox
        width: parent.width
        height: 30
        text: "Показывать время очереди"
        checked: Config.mopidyShowQueueTotalDuration
        onClicked: { Config.mopidyShowQueueTotalDuration = checked; settings.save() }
        Connections { target: Config; function onMopidyShowQueueTotalDurationChanged() { showQueueTimeCheckBox.checked = Config.mopidyShowQueueTotalDuration } }
    }

    Row {
        width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Отображать"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsComboBox {
            id: queueDurationModeCombo
            width: 160; height: 30
            model: ["Общее", "Оставшееся"]
            currentIndex: Config.mopidyQueueDurationMode === "remaining" ? 1 : 0
            onItemChosen: function(index) { Config.mopidyQueueDurationMode = index === 1 ? "remaining" : "total"; settings.save() }
            Connections { target: Config; function onMopidyQueueDurationModeChanged() { queueDurationModeCombo.currentIndex = Config.mopidyQueueDurationMode === "remaining" ? 1 : 0 } }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: queueDurationFontField
            width: 140; height: 30; text: Config.mopidyQueueDurationFont; color: Config.text; activeFocusOnTab: true
            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
            background: Rectangle { color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: function() { var v = queueDurationFontField.text.trim(); if (v.length > 0) Config.mopidyQueueDurationFont = v; queueDurationFontField.text = Config.mopidyQueueDurationFont; settings.save() }
            Connections { target: Config; function onMopidyQueueDurationFontChanged() { queueDurationFontField.text = Config.mopidyQueueDurationFont } }
        }
        SettingsNumberField {
            width: 72; height: 30; value: Config.mopidyQueueDurationFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config; targetProperty: "mopidyQueueDurationFontSize"; settingsObject: root.settings; saveOnEdit: true
        }
    }

    SettingsColorField {
        width: parent.width; height: 30
        label: "Цвет"
        value: Config.mopidyQueueDurationColor
        targetObject: Config; targetProperty: "mopidyQueueDurationColor"
        settingsObject: root.settings; saveOnEdit: true
        allowAlpha: true; allowTransparent: true; fieldWidth: 120; fieldHeight: 30
    }

    Row {
        width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Положение X / Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        Text { width: 46; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyQueueDurationX; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "mopidyQueueDurationX"; settingsObject: root.settings; saveOnEdit: true }
        Text { width: 46; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
        SettingsNumberField { width: 58; height: 30; value: Config.mopidyQueueDurationY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyQueueDurationY"; settingsObject: root.settings; saveOnEdit: true }
    }

    Row {
        width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Выравнивание времени очереди"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsComboBox {
            id: queueDurationAlignmentCombo
            width: 140; height: 30
            model: ["Справа", "Слева"]
            currentIndex: Config.mopidyQueueDurationAlignment === "left" ? 1 : 0
            onItemChosen: function(index) {
                Config.mopidyQueueDurationAlignment = index === 1 ? "left" : "right"
                settings.save()
            }
            Connections {
                target: Config
                function onMopidyQueueDurationAlignmentChanged() {
                    queueDurationAlignmentCombo.currentIndex = Config.mopidyQueueDurationAlignment === "left" ? 1 : 0
                }
            }
        }
    }

    Text {
        text: "Время треков и альбомов"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    SettingsCheckBox {
        id: showTrackRemainingCheckBox
        width: parent.width; height: 30
        text: "Показывать оставшееся время текущего трека"
        checked: Config.mopidyShowTrackRemaining
        onClicked: { Config.mopidyShowTrackRemaining = checked; settings.save() }
        Connections { target: Config; function onMopidyShowTrackRemainingChanged() { showTrackRemainingCheckBox.checked = Config.mopidyShowTrackRemaining } }
    }

    SettingsCheckBox {
        id: showAlbumRemainingCheckBox
        width: parent.width; height: 30
        text: "Показывать оставшееся время текущего альбома"
        checked: Config.mopidyShowAlbumRemaining
        onClicked: { Config.mopidyShowAlbumRemaining = checked; settings.save() }
        Connections { target: Config; function onMopidyShowAlbumRemainingChanged() { showAlbumRemainingCheckBox.checked = Config.mopidyShowAlbumRemaining } }
    }

    Text {
        text: "Отображение названия и исполнителя"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    Row {
        width: parent.width
        height: 30
        spacing: 8
        Text {
            width: 180
            text: "Режим отображения"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }
        SettingsComboBox {
            id: trackArtistDisplayModeCombo
            width: 250
            height: 30
            model: ["В две строки", "В одну строку (исполнитель + разделитель + название)"]
            currentIndex: Config.mopidyTrackArtistDisplayMode === "one-line" ? 1 : 0
            onItemChosen: function(index) {
                Config.mopidyTrackArtistDisplayMode = index === 1 ? "one-line" : "two-lines"
                settings.save()
            }
            Connections {
                target: Config
                function onMopidyTrackArtistDisplayModeChanged() {
                    trackArtistDisplayModeCombo.currentIndex = Config.mopidyTrackArtistDisplayMode === "one-line" ? 1 : 0
                }
            }
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 8
        Text {
            width: 180
            text: "Высота строки списка"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }
        SettingsNumberField {
            width: 72; height: 30
            value: Config.mopidyTrackRowHeight
            minimum: 30; maximum: 80; step: 1; wheelStep: 1; decimals: 0
            compact: true; fieldWidth: 72; fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config; targetProperty: "mopidyTrackRowHeight"
            settingsObject: root.settings; saveOnEdit: true
        }
        Text {
            text: "px"
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            verticalAlignment: Text.AlignVCenter
        }
    }

    Row {
        width: parent.width; height: 30; spacing: 8
        Text {
            width: 180
            text: "Разделитель в одну строку"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }
        SettingsTextField {
            id: trackArtistSeparatorField
            width: 160; height: 30
            text: Config.mopidyTrackArtistSeparator
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            activeFocusOnTab: true
            onEditingFinished: function() {
                Config.mopidyTrackArtistSeparator = trackArtistSeparatorField.text
                settings.save()
            }
            Connections {
                target: Config
                function onMopidyTrackArtistSeparatorChanged() {
                    trackArtistSeparatorField.text = Config.mopidyTrackArtistSeparator
                }
            }
        }
        Text {
            text: "пример:  ·  /  —  /  |"
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            verticalAlignment: Text.AlignVCenter
        }
    }

    SettingsCheckBox {
        id: artistBoldCheckBox
        width: parent.width; height: 28
        text: "Исполнитель жирным"
        checked: Config.mopidyArtistBold
        onClicked: { Config.mopidyArtistBold = checked; settings.save() }
        Connections { target: Config; function onMopidyArtistBoldChanged() { artistBoldCheckBox.checked = Config.mopidyArtistBold } }
    }

    SettingsCheckBox {
        id: artistItalicCheckBox
        width: parent.width; height: 28
        text: "Исполнитель курсивом"
        checked: Config.mopidyArtistItalic
        onClicked: { Config.mopidyArtistItalic = checked; settings.save() }
        Connections { target: Config; function onMopidyArtistItalicChanged() { artistItalicCheckBox.checked = Config.mopidyArtistItalic } }
    }

    Text {
        text: "Шрифты очереди"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    // Keep the existing four queue text settings together so they are no longer
    // mixed into the general Mopidy behavior settings.
    Row {
        width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Шрифт альбома"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: albumFontField
            width: 140; height: 30; text: Config.mopidyAlbumFont; color: Config.text; activeFocusOnTab: true
            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
            background: Rectangle { color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: function() { var v = albumFontField.text.trim(); if (v.length > 0) Config.mopidyAlbumFont = v; albumFontField.text = Config.mopidyAlbumFont; settings.save() }
            Connections { target: Config; function onMopidyAlbumFontChanged() { albumFontField.text = Config.mopidyAlbumFont } }
        }
        SettingsNumberField { width: 72; height: 30; value: Config.mopidyAlbumFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyAlbumFontSize"; settingsObject: root.settings; saveOnEdit: true }
    }

    Row {
        width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Шрифт названия трека"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        SettingsTextField {
            id: trackFontField
            width: 140; height: 30; text: Config.mopidyTrackFont; color: Config.text; activeFocusOnTab: true
            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
            background: Rectangle { color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: function() { var v = trackFontField.text.trim(); if (v.length > 0) Config.mopidyTrackFont = v; trackFontField.text = Config.mopidyTrackFont; settings.save() }
            Connections { target: Config; function onMopidyTrackFontChanged() { trackFontField.text = Config.mopidyTrackFont } }
        }
        SettingsNumberField { width: 72; height: 30; value: Config.mopidyTrackFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyTrackFontSize"; settingsObject: root.settings; saveOnEdit: true }
    }

    Row {
        width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Шрифт исполнителя"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: artistFontField
            width: 140; height: 30; text: Config.mopidyArtistFont; color: Config.text; activeFocusOnTab: true
            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
            background: Rectangle { color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: function() { var v = artistFontField.text.trim(); if (v.length > 0) Config.mopidyArtistFont = v; artistFontField.text = Config.mopidyArtistFont; settings.save() }
            Connections { target: Config; function onMopidyArtistFontChanged() { artistFontField.text = Config.mopidyArtistFont } }
        }
        SettingsNumberField { width: 72; height: 30; value: Config.mopidyArtistFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyArtistFontSize"; settingsObject: root.settings; saveOnEdit: true }
    }

    Row {
        width: parent.width; height: 30; spacing: 8
        Text { width: 180; text: "Шрифт длительности"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsTextField {
            id: durationFontField
            width: 140; height: 30; text: Config.mopidyDurationFont; color: Config.text; activeFocusOnTab: true
            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
            background: Rectangle { color: Config.settingsBackground; border.color: (parent.activeFocus || parent.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
            onEditingFinished: function() { var v = durationFontField.text.trim(); if (v.length > 0) Config.mopidyDurationFont = v; durationFontField.text = Config.mopidyDurationFont; settings.save() }
            Connections { target: Config; function onMopidyDurationFontChanged() { durationFontField.text = Config.mopidyDurationFont } }
        }
        SettingsNumberField { width: 72; height: 30; value: Config.mopidyDurationFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyDurationFontSize"; settingsObject: root.settings; saveOnEdit: true }
    }
}
