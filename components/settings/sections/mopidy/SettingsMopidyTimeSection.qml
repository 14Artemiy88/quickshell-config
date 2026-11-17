import QtQuick
import QtQuick.Controls
import "../../primitives"
import "../../../.."

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0

    visible: host && host.currentPageId === "mopidy" && host.currentPageSubTabIndex === 1

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyQueueDurationAlignment", "mopidyQueueDurationColor", "mopidyQueueDurationFont", "mopidyQueueDurationFontSize", "mopidyQueueDurationMode", "mopidyQueueDurationX", "mopidyQueueDurationY", "mopidyShowQueueTotalDuration"] })
        heading: "Время очереди"
        padding: 8
        contentSpacing: 6



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
                Text { width: 210; height: 30; text: "Отображать"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
                Text { width: 210; height: 30; text: "Шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsFontField {
                    width: 178
                    height: 30
                    compact: true
                    fieldWidth: 140
                    fieldFontSize: 11
                    value: Config.mopidyQueueDurationFont
                    targetObject: Config
                    targetProperty: "mopidyQueueDurationFont"
                    settingsObject: root.settings
                    saveOnEdit: true
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
                Text { width: 210; height: 30; text: "Положение"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                Text { width: 46; height: 30; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                SettingsNumberField { width: 58; height: 30; value: Config.mopidyQueueDurationX; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "mopidyQueueDurationX"; settingsObject: root.settings; saveOnEdit: true }
                Text { width: 46; height: 30; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                SettingsNumberField { width: 58; height: 30; value: Config.mopidyQueueDurationY; minimum: -20; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 58; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyQueueDurationY"; settingsObject: root.settings; saveOnEdit: true }
            }

            Row {
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Выравнивание"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
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
    }

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyShowAlbumRemaining", "mopidyShowTrackRemaining"] })
        heading: "Время треков и альбомов"
        padding: 8
        contentSpacing: 6



            SettingsCheckBox {
                id: showTrackRemainingCheckBox
                width: parent.width; height: 30
                text: "Показывать оставшееся время трека"
                checked: Config.mopidyShowTrackRemaining
                onClicked: { Config.mopidyShowTrackRemaining = checked; settings.save() }
                Connections { target: Config; function onMopidyShowTrackRemainingChanged() { showTrackRemainingCheckBox.checked = Config.mopidyShowTrackRemaining } }
            }

            SettingsCheckBox {
                id: showAlbumRemainingCheckBox
                width: parent.width; height: 30
                text: "Показывать оставшееся время альбома"
                checked: Config.mopidyShowAlbumRemaining
                onClicked: { Config.mopidyShowAlbumRemaining = checked; settings.save() }
                Connections { target: Config; function onMopidyShowAlbumRemainingChanged() { showAlbumRemainingCheckBox.checked = Config.mopidyShowAlbumRemaining } }
            }
    }

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyArtistBold", "mopidyArtistItalic", "mopidyTrackArtistDisplayMode", "mopidyTrackArtistSeparator", "mopidyTrackRowHeight"] })
        heading: "Название и исполнитель"
        padding: 8
        contentSpacing: 6



            Row {
                width: parent.width
                height: 30
                spacing: 8
                Text {
                    width: 210
                    height: 30
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
                    width: 210
                    height: 30
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
                    width: 210
                    height: 30
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
    }

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyAlbumFont", "mopidyAlbumFontSize", "mopidyArtistFont", "mopidyArtistFontSize", "mopidyDurationFont", "mopidyDurationFontSize", "mopidyTrackFont", "mopidyTrackFontSize"] })
        heading: "Шрифты очереди"
        padding: 8
        contentSpacing: 6



            // Keep the existing four queue text settings together so they are no longer
            // mixed into the general Mopidy behavior settings.
            Row {
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Шрифт альбома"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsFontField {
                    width: 178
                    height: 30
                    compact: true
                    fieldWidth: 140
                    fieldFontSize: 11
                    value: Config.mopidyAlbumFont
                    targetObject: Config
                    targetProperty: "mopidyAlbumFont"
                    settingsObject: root.settings
                    saveOnEdit: true
                }
                SettingsNumberField { width: 72; height: 30; value: Config.mopidyAlbumFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyAlbumFontSize"; settingsObject: root.settings; saveOnEdit: true }
            }

            Row {
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Шрифт названия трека"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                SettingsFontField {
                    width: 178
                    height: 30
                    compact: true
                    fieldWidth: 140
                    fieldFontSize: 11
                    value: Config.mopidyTrackFont
                    targetObject: Config
                    targetProperty: "mopidyTrackFont"
                    settingsObject: root.settings
                    saveOnEdit: true
                }
                SettingsNumberField { width: 72; height: 30; value: Config.mopidyTrackFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyTrackFontSize"; settingsObject: root.settings; saveOnEdit: true }
            }

            Row {
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Шрифт исполнителя"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsFontField {
                    width: 178
                    height: 30
                    compact: true
                    fieldWidth: 140
                    fieldFontSize: 11
                    value: Config.mopidyArtistFont
                    targetObject: Config
                    targetProperty: "mopidyArtistFont"
                    settingsObject: root.settings
                    saveOnEdit: true
                }
                SettingsNumberField { width: 72; height: 30; value: Config.mopidyArtistFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyArtistFontSize"; settingsObject: root.settings; saveOnEdit: true }
            }

            Row {
                width: parent.width; height: 30; spacing: 8
                Text { width: 210; height: 30; text: "Шрифт длительности"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                SettingsFontField {
                    width: 178
                    height: 30
                    compact: true
                    fieldWidth: 140
                    fieldFontSize: 11
                    value: Config.mopidyDurationFont
                    targetObject: Config
                    targetProperty: "mopidyDurationFont"
                    settingsObject: root.settings
                    saveOnEdit: true
                }
                SettingsNumberField { width: 72; height: 30; value: Config.mopidyDurationFontSize; minimum: 6; maximum: 40; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "mopidyDurationFontSize"; settingsObject: root.settings; saveOnEdit: true }
            }
    }
}
