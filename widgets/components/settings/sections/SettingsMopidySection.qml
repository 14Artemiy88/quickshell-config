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

    visible: host && host.currentOtherTab === 10 && host.currentOtherSubTab === 0

    Text {
        text: "Поведение"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    SettingsCheckBox {
        id: toggleWithPlayerCheckBox
        width: parent.width
        height: 30
        text: "Открывать/скрывать Mopidy по ПКМ на Player"
        checked: Config.mopidyToggleWithPlayerRightClick
        onClicked: {
            Config.mopidyToggleWithPlayerRightClick = checked
            settings.save()
        }
        Connections {
            target: Config
            function onMopidyToggleWithPlayerRightClickChanged() {
                toggleWithPlayerCheckBox.checked = Config.mopidyToggleWithPlayerRightClick
            }
        }
    }

    Row {
        width: parent.width
        height: 30
        spacing: 8

        Text {
            width: 180
            text: "Наведение"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }

        SettingsComboBox {
            id: hoverModeComboBox
            width: 160
            height: 30
            model: ["Текст", "Фон", "Рамка"]
            currentIndex: ["text", "background", "frame"].indexOf(Config.mopidyHoverMode)
            onItemChosen: function(index) {
                Config.mopidyHoverMode = ["text", "background", "frame"][index]
                settings.save()
            }
            Connections {
                target: Config
                function onMopidyHoverModeChanged() {
                    hoverModeComboBox.currentIndex = ["text", "background", "frame"].indexOf(Config.mopidyHoverMode)
                }
            }
        }
    }

    SettingsColorField {
        width: parent.width
        height: 30
        label: "Цвет наведения"
        value: Config.mopidyHoverColor
        targetObject: Config
        targetProperty: "mopidyHoverColor"
        settingsObject: root.settings
        saveOnEdit: true
        allowAlpha: true
        allowTransparent: true
        fieldWidth: 120
        fieldHeight: 30
    }

    Text {
        text: "Внешний вид"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    SettingsColorField {
        width: parent.width
        height: 30
        label: "Фон Mopidy"
        value: Config.mopidyBackground
        targetObject: Config
        targetProperty: "mopidyBackground"
        settingsObject: root.settings
        saveOnEdit: true
        allowAlpha: true
        allowTransparent: true
        fieldWidth: 120
        fieldHeight: 30
    }

    // Persist direct changes to this dedicated color immediately, even if the
    // settings field loses focus while its panel is being closed or switched.
    Connections {
        target: Config
        function onMopidyBackgroundChanged() {
            if (root.settings && root.settings.loaded)
                Qt.callLater(function() {
                    if (root.settings && root.settings.loaded)
                        root.settings.save()
                })
        }
    }

    Text {
        text: "Очередь"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    SettingsCheckBox {
        id: trackNumbersCheckBox
        width: parent.width
        height: 30
        text: "Показывать номера треков"
        checked: Config.mopidyShowTrackNumbers
        onClicked: {
            Config.mopidyShowTrackNumbers = checked
            settings.save()
        }
        Connections {
            target: Config
            function onMopidyShowTrackNumbersChanged() {
                trackNumbersCheckBox.checked = Config.mopidyShowTrackNumbers
            }
        }
    }

    SettingsCheckBox {
        id: groupAlbumsCheckBox
        width: parent.width
        height: 30
        text: "Группировать треки по альбомам"
        checked: Config.mopidyGroupAlbums
        onClicked: {
            Config.mopidyGroupAlbums = checked
            settings.save()
        }
        Connections {
            target: Config
            function onMopidyGroupAlbumsChanged() {
                groupAlbumsCheckBox.checked = Config.mopidyGroupAlbums
            }
        }
    }

    SettingsCheckBox {
        id: albumBoldCheckBox
        width: parent.width
        height: 30
        text: "Жирный альбом (и время)"
        checked: Config.mopidyAlbumBold
        onClicked: {
            Config.mopidyAlbumBold = checked
            settings.save()
        }
        Connections {
            target: Config
            function onMopidyAlbumBoldChanged() {
                albumBoldCheckBox.checked = Config.mopidyAlbumBold
            }
        }
    }

    Row {
        width: parent.width
        height: 30
        spacing: 8

        Text {
            width: 180
            text: "Разделитель альбома"
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(11)
            verticalAlignment: Text.AlignVCenter
        }

        SettingsComboBox {
            id: albumSeparatorComboBox
            width: 160
            height: 30
            model: ["Ничего", "Линия между названием и временем", "Линия под названием", "Рамка"]
            currentIndex: ["none", "between-line", "under-line", "frame"].indexOf(Config.mopidyAlbumSeparator)
            onItemChosen: function(index) {
                Config.mopidyAlbumSeparator = ["none", "between-line", "under-line", "frame"][index]
                settings.save()
            }
            Connections {
                target: Config
                function onMopidyAlbumSeparatorChanged() {
                    albumSeparatorComboBox.currentIndex = ["none", "between-line", "under-line", "frame"].indexOf(Config.mopidyAlbumSeparator)
                }
            }
        }
    }

    Text {
        text: "Громкость"
        color: Config.accent
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(14)
    }

    Row {
        width: parent.width
        height: 30
        spacing: 8
        Text { width: 180; text: "Шаг колеса"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
        SettingsNumberField {
            width: 72; height: 30; value: Config.mopidyVolumeStep; minimum: 1; maximum: 20; step: 1; wheelStep: 1; decimals: 0; compact: true; fieldWidth: 72; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config; targetProperty: "mopidyVolumeStep"; settingsObject: root.settings; saveOnEdit: true
        }
    }

    SettingsCheckBox {
        id: volumePercentCheckBox
        width: parent.width
        height: 30
        text: "Показывать процент громкости"
        checked: Config.mopidyShowVolumePercent
        onClicked: { Config.mopidyShowVolumePercent = checked; settings.save() }
        Connections { target: Config; function onMopidyShowVolumePercentChanged() { volumePercentCheckBox.checked = Config.mopidyShowVolumePercent } }
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
        id: animationMopidyVisibilityBox
        width: 180
        height: 30
        property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
        model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
        currentIndex: Math.max(0, values.indexOf(Config.animationMopidyVisibilityStyle))
        onItemChosen: function(index) { Config.animationMopidyVisibilityStyle = values[index]; settings.save() }
        Connections {
            target: Config
            function onAnimationMopidyVisibilityStyleChanged() { animationMopidyVisibilityBox.currentIndex = Math.max(0, animationMopidyVisibilityBox.values.indexOf(Config.animationMopidyVisibilityStyle)) }
        }
        background: Rectangle { color: Config.settingsBackground; border.color: (animationMopidyVisibilityBox.activeFocus || animationMopidyVisibilityBox.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        contentItem: Text { text: animationMopidyVisibilityBox.currentText; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
    }
}

}
