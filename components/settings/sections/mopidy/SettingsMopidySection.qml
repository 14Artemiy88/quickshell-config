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

    visible: host && host.currentPageId === "mopidy" && host.currentPageSubTabIndex === 0

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyHoverColor", "mopidyHoverMode", "mopidyToggleWithPlayerRightClick"] })
        heading: "Поведение"
        padding: 8
        contentSpacing: 6



            SettingsCheckBox {
                id: toggleWithPlayerCheckBox
                width: parent.width
                height: 30
                text: "Переключать Mopidy по ПКМ на Player"
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

            SettingsRow {
                label: "Наведение"
                controlSpacing: 8
                width: parent.width
                height: 30
                spacing: 8



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
    }

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyBackground"] })
        heading: "Внешний вид"
        padding: 8
        contentSpacing: 6



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

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyAlbumBold", "mopidyAlbumSeparator", "mopidyGroupAlbums", "mopidyShowTrackNumbers"] })
        heading: "Очередь"
        padding: 8
        contentSpacing: 6



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

            SettingsRow {
                label: "Разделитель альбома"
                controlSpacing: 8
                width: parent.width
                height: 30
                spacing: 8



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
    }

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyBrowseCoverMode", "mopidyBrowseCoverKeepSelectedVisible"] })
        heading: "Обложки библиотеки"
        padding: 8
        contentSpacing: 6

        SettingsRow {
            label: "Обложки в списке папок"
            controlSpacing: 8
            width: parent.width
            height: 30
            spacing: 8

            SettingsComboBox {
                id: browseCoverModeCombo
                width: 190
                height: 30
                model: ["Выключено", "Только выбранная", "Все видимые"]
                currentIndex: ["off", "selected", "all-visible"].indexOf(Config.mopidyBrowseCoverMode)
                onItemChosen: function(index) {
                    Config.mopidyBrowseCoverMode = ["off", "selected", "all-visible"][index] || "selected"
                    settings.save()
                }
                Connections {
                    target: Config
                    function onMopidyBrowseCoverModeChanged() {
                        browseCoverModeCombo.currentIndex = ["off", "selected", "all-visible"].indexOf(Config.mopidyBrowseCoverMode)
                    }
                }
            }
        }

        SettingsCheckBox {
            id: browseCoverKeepSelectedCheckBox
            width: parent.width
            height: 30
            visible: Config.mopidyBrowseCoverMode === "selected"
            text: "Оставлять обложку после снятия курсора"
            checked: Config.mopidyBrowseCoverKeepSelectedVisible
            onClicked: {
                Config.mopidyBrowseCoverKeepSelectedVisible = checked
                settings.save()
            }
            Connections {
                target: Config
                function onMopidyBrowseCoverKeepSelectedVisibleChanged() {
                    browseCoverKeepSelectedCheckBox.checked = Config.mopidyBrowseCoverKeepSelectedVisible
                }
            }
        }

        Text {
            width: parent.width
            text: Config.mopidyBrowseCoverMode === "selected"
                ? "В режиме «Только выбранная» обложка показывается при наведении. Можно оставить её видимой после ухода курсора. «Все видимые» загружает только папки в текущей области прокрутки. Обложка уже открытой папки в заголовке не зависит от этого параметра."
                : "«Все видимые» загружает только папки в текущей области прокрутки. Обложка уже открытой папки в заголовке не зависит от этого параметра."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: host && host.currentPageId === "mopidy"
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["mopidyShowVolumePercent", "mopidyVolumeStep"] })
        heading: "Громкость"
        padding: 8
        contentSpacing: 6



            SettingsRow {
                label: "Шаг колеса"
                controlSpacing: 8
                width: parent.width
                height: 30
                spacing: 8

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
    }



}
