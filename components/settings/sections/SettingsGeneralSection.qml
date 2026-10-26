import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings
    property var storagePathEntries: []
    property var storagePathGroups: [
        { title: "Настройки и профили", entryIds: ["settings", "profiles", "settingsBackup", "configDir"] },
        { title: "Календарь", entryIds: ["calendarNotes", "calendarMarks", "dataDir"] },
        { title: "Данные модулей и кэши", entryIds: ["stateDir", "cacheDir", "weatherCache", "mopidyCovers", "launcherHistory"] },
        { title: "Временные данные", entryIds: ["timerRuntimeDir"] }
    ]
    property bool storagePathsLoaded: false
    property string storagePathsError: ""
    property string storagePathEditId: ""
    property string storagePathEditValue: ""
    property var storagePathDrafts: ({})
    property string storagePathApplyMessage: ""
    property bool storagePathApplyError: false

    Component.onCompleted: storagePathsProcess.running = true

    Process {
        id: storagePathsProcess
        command: [Quickshell.shellDir + "/scripts/storage_paths"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var parsed = JSON.parse(this.text)
                    root.storagePathEntries = Array.isArray(parsed.entries) ? parsed.entries : []
                    root.storagePathsLoaded = true
                    root.storagePathsError = ""
                } catch (e) {
                    root.storagePathsLoaded = true
                    root.storagePathsError = "Не удалось прочитать список путей."
                }
            }
        }
        onExited: function(exitCode) {
            if (exitCode !== 0 && !root.storagePathsLoaded) {
                root.storagePathsLoaded = true
                root.storagePathsError = "Не удалось определить пути (код " + exitCode + ")."
            }
        }
    }

    Process {
        id: storagePathApplyProcess
        command: [
            Quickshell.shellDir + "/scripts/storage_paths",
            "set",
            root.storagePathEditId,
            root.storagePathEditValue
        ]
        running: false
        stdout: StdioCollector { id: storagePathApplyCollector }
        onExited: function(exitCode) {
            var result = {}
            try { result = JSON.parse(storagePathApplyCollector.text) } catch (e) {}
            root.storagePathApplyError = exitCode !== 0 || result.ok !== true
            root.storagePathApplyMessage = String(result.message || ("Операция завершилась с кодом " + exitCode + "."))
            if (!root.storagePathApplyError) {
                var completedId = root.storagePathEditId
                root.clearStoragePathDraft(completedId)
                root.storagePathEditId = ""
                root.storagePathEditValue = ""
                storagePathsProcess.running = true
            }
        }
    }

    function updateStoragePathDraft(id, value) {
        var updated = {}
        var keys = Object.keys(root.storagePathDrafts)
        for (var i = 0; i < keys.length; i++) updated[keys[i]] = root.storagePathDrafts[keys[i]]
        var key = String(id || "")
        var valueText = String(value || "")
        if (valueText.length > 0) updated[key] = valueText
        root.storagePathDrafts = updated
    }

    function clearStoragePathDraft(id) {
        var updated = {}
        var keys = Object.keys(root.storagePathDrafts)
        for (var i = 0; i < keys.length; i++) {
            if (keys[i] !== String(id || "")) updated[keys[i]] = root.storagePathDrafts[keys[i]]
        }
        root.storagePathDrafts = updated
    }

    function requestStoragePathMove(id, path) {
        var candidate = String(path || "")
        if (storagePathApplyProcess.running) return
        if (candidate.trim().length === 0) {
            storagePathApplyError = true
            storagePathApplyMessage = "Укажи новый абсолютный путь к файлу."
            return
        }
        storagePathApplyMessage = ""
        storagePathApplyError = false
        storagePathEditId = String(id || "")
        storagePathEditValue = candidate
        storagePathApplyProcess.running = true
    }

    function copyStoragePath(path) {
        Quickshell.execDetached([Quickshell.shellDir + "/scripts/copy_text", String(path || "")])
    }

    visible: host && host.currentOtherTab === 0
    width: parent ? parent.width : 0
    spacing: 10

    SettingsGroup {
        visible: host && host.currentOtherTab === 0 && host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
            visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
            text: "Шрифты интерфейса"
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Row {
            visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 210; height: 30; text: "Основной шрифт интерфейса"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsTextField {
                id: generalFontField
                width: 160; height: 30
                text: Config.font
                color: Config.text
                selectionColor: Config.accent
                selectedTextColor: Config.black
                font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                activeFocusOnTab: true
                background: Rectangle { color: Config.settingsBackground; border.color: (generalFontField.activeFocus || generalFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                onEditingFinished: { Config.font = text.trim() || Config.font; text = Config.font; settings.save() }
                Connections { target: Config; function onFontChanged() { generalFontField.text = Config.font } }
            }
        }

        Row {
            visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 210; height: 30; text: "Размер шрифта интерфейса"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsNumberField {
            id: generalFontSizeField
            width: 100
            height: 30
            value: Config.fontSize
            minimum: 6
            maximum: 32
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "fontSize"
            settingsObject: root.settings
            saveOnEdit: true
        }
        }

        Row {
            visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
            width: parent.width
            height: 34
            spacing: 8
            Text { width: 210; height: 30; text: "LED-шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
            SettingsTextField {
                id: ledFontField
                width: 160; height: 30
                text: Config.ledFont
                color: Config.text
                selectionColor: Config.accent
                selectedTextColor: Config.black
                font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                activeFocusOnTab: true
                background: Rectangle { color: Config.settingsBackground; border.color: (ledFontField.activeFocus || ledFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                onEditingFinished: { Config.ledFont = text.trim() || Config.ledFont; text = Config.ledFont; settings.save() }
                Connections { target: Config; function onLedFontChanged() { ledFontField.text = Config.ledFont } }
            }
        }
    }
    SettingsGroup {
        visible: host && host.currentOtherTab === 0 && host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        heading: "Размытие фона"
        padding: 8
        contentSpacing: 6

        Row {
            visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
            width: parent.width
            height: 30
            spacing: 8
            Text {
                width: 210
                height: 30
                text: "Радиус области блюра (0–40)"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }
            SettingsNumberField {
                id: backgroundBlurRadiusField
                width: 72
                height: 30
                value: Config.backgroundBlurRadius
                minimum: 0
                maximum: 40
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 72
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "backgroundBlurRadius"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
        Text {
            visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
            width: parent.width
            text: "Для работы блюра требуется поддержка композитора."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: host && host.currentOtherTab === 0 && host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        padding: 8
        contentSpacing: 6

        Text {
            visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
            text: "Рамки виджетов"
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Row {
            visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: "Толщина рамки (0 = выкл.)"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
            id: frameBorderWidthField
            width: 100
            height: 30
            value: Config.frameBorderWidth
            minimum: 0
            maximum: 20
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "frameBorderWidth"
            settingsObject: root.settings
            saveOnEdit: true
        }
        }

        Row {
            visible: host.currentOtherTab === 0 && host.currentOtherSubTab === 0
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: "Радиус скругления рамки"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
            id: frameRadiusField
            width: 100
            height: 30
            value: Config.frameRadius
            minimum: 0
            maximum: 50
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "frameRadius"
            settingsObject: root.settings
            saveOnEdit: true
        }
        }
    }

    Text {
        visible: host && host.currentOtherTab === 0 && host.currentOtherSubTab === 2
        width: parent.width
        text: "Пути вычисляются автоматически. Перемещать можно settings.json, profiles.json, calendar-notes.json и calendar-marks.json. Файл переносится с проверкой JSON; старый вариант сохраняется как резервная копия. После смены расположения рекомендуется перезапустить Quickshell."
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
        wrapMode: Text.WordWrap
    }

    Text {
        visible: host && host.currentOtherTab === 0 && host.currentOtherSubTab === 2 && !root.storagePathsLoaded
        width: parent.width
        text: "Определение путей хранения…"
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
    }

    Text {
        visible: host && host.currentOtherTab === 0 && host.currentOtherSubTab === 2 && root.storagePathsError.length > 0
        width: parent.width
        text: root.storagePathsError
        color: Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
        wrapMode: Text.WordWrap
    }

    Text {
        visible: host && host.currentOtherTab === 0 && host.currentOtherSubTab === 2 && root.storagePathApplyMessage.length > 0
        width: parent.width
        text: root.storagePathApplyMessage
        color: root.storagePathApplyError ? "#e06c75" : Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(10)
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: root.storagePathGroups

        delegate: SettingsGroup {
            id: storagePathsGroup
            required property var modelData
            property var groupEntryIds: modelData.entryIds

            visible: host && host.currentOtherTab === 0 && host.currentOtherSubTab === 2
            width: parent.width
            showFrame: true
            heading: modelData.title
            padding: 8
            contentSpacing: 8

            Repeater {
                model: root.storagePathEntries.filter(function(entry) {
                    return storagePathsGroup.groupEntryIds.indexOf(entry.id) >= 0
                })

                delegate: Column {
                    required property var modelData
                    width: parent.width
                    spacing: 3

                    Row {
                        width: parent.width
                        height: 28
                        spacing: 8

                        Text {
                            width: parent.width - copyButton.width - parent.spacing
                            height: parent.height
                            text: modelData.label
                            color: Config.text
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        SettingsButton {
                            id: copyButton
                            width: 82
                            height: 26
                            text: "Копировать"
                            fontSize: 9
                            tooltip: "Копировать путь в буфер обмена"
                            onClicked: root.copyStoragePath(modelData.path)
                        }
                    }

                    TextArea {
                        width: parent.width
                        height: Math.max(20, contentHeight)
                        text: modelData.path
                        readOnly: true
                        selectByMouse: true
                        color: Config.textMuted
                        selectionColor: Config.baseColor
                        selectedTextColor: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        wrapMode: TextArea.WrapAnywhere
                        padding: 0
                        background: null
                    }

                    Column {
                        visible: modelData.editable === true
                        width: parent.width
                        spacing: 4

                        Text {
                            width: parent.width
                            text: "Новое расположение (имя файла не меняется)"
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(9)
                        }

                        Row {
                            width: parent.width
                            height: 30
                            spacing: 8

                            SettingsTextField {
                                id: storagePathTargetField
                                width: parent.width - relocatePathButton.width - parent.spacing
                                height: 30
                                text: root.storagePathDrafts[modelData.id] || ""
                                placeholderText: "Абсолютный путь к " + String(modelData.path || "").split("/").pop()
                                selectByMouse: true
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                enabled: !storagePathApplyProcess.running
                                onTextChanged: root.updateStoragePathDraft(modelData.id, text)
                                onAccepted: root.requestStoragePathMove(modelData.id, text)
                            }

                            SettingsButton {
                                id: relocatePathButton
                                width: 94
                                height: 28
                                text: "Перенести"
                                fontSize: 9
                                enabled: !storagePathApplyProcess.running
                                tooltip: "Проверить JSON, скопировать файл и переключить расположение"
                                onClicked: root.requestStoragePathMove(modelData.id, storagePathTargetField.text)
                            }
                        }
                    }

                    Text {
                        visible: String(modelData.description || "").length > 0
                        width: parent.width
                        text: String(modelData.description || "")
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(9)
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Config.baseColor
                        opacity: 0.55
                    }
                }
            }
        }
    }


}
