import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "primitives" as Primitives
import ".."

Primitives.ModuleFrame {
    id: root
    moduleName: "calendar"
    moduleBackgroundColor: Config.calendarBackground
    width: 315
    height: 285
    property date date: new Date()
    property int year: date.getFullYear()
    property int month: date.getMonth()
    property bool open: true
    property var names: ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]
    property var calendarNotes: ({})
    property bool notesLoaded: false
    property string noteOverlayMode: "" // "edit", "view", or empty
    property string noteDialogDate: ""
    property string noteDraft: ""
    clip: true

    function dateKeyForDay(day) {
        if (day < 1 || day > root.daysInMonth()) return ""
        const mm = String(root.month + 1).padStart(2, "0")
        const dd = String(day).padStart(2, "0")
        return String(root.year) + "-" + mm + "-" + dd
    }

    // Show complete weeks only. Cells before day 1 and after the month's final day
    // are represented by offsets that JavaScript Date normalizes into adjacent months.
    function gridCellCount() {
        return Math.ceil((root.firstDay() + root.daysInMonth()) / 7) * 7
    }

    function calendarGridDayNumber(day) {
        return new Date(root.year, root.month, day).getDate()
    }

    function hasNoteForDate(key) {
        return !!key && !!root.calendarNotes && String(root.calendarNotes[key] || "").trim().length > 0
    }

    function currentDateKey() {
        const today = new Date()
        return String(today.getFullYear()) + "-" + String(today.getMonth() + 1).padStart(2, "0") + "-" + String(today.getDate()).padStart(2, "0")
    }

    function isPastDateKey(key) {
        const value = String(key || "")
        return /^\d{4}-\d{2}-\d{2}$/.test(value) && value < root.currentDateKey()
    }

    function calendarDayColor(key, day) {
        if (day < 1 || day > root.daysInMonth()) return Config.calendarAdjacentDaysColor
        if (String(key || "") === root.currentDateKey()) return Config.accent
        if (Config.calendarPastDaysColorEnabled && root.isPastDateKey(key))
            return Config.calendarPastDaysColor
        return Config.text
    }

    function noteMarkerColor(key, fallbackColor) {
        if (Config.calendarPastDaysColorEnabled && root.isPastDateKey(key))
            return Config.calendarPastDaysColor
        return fallbackColor
    }

    function setCalendarNotesFromJson(raw) {
        try {
            const parsed = JSON.parse(String(raw || "{}").trim() || "{}")
            root.calendarNotes = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : ({})
        } catch (e) {
            root.calendarNotes = ({})
        }
        root.notesLoaded = true
    }

    function openNoteEditor(key) {
        if (!key) return
        root.noteDialogDate = key
        root.noteDraft = String(root.calendarNotes[key] || "")
        root.noteOverlayMode = "edit"
        // Let the owning PanelWindow enable keyboard focus first, then focus the editor.
        Qt.callLater(function() {
            Qt.callLater(function() {
                if (root.noteOverlayMode !== "edit") return
                noteArea.text = root.noteDraft
                noteArea.forceActiveFocus(Qt.OtherFocusReason)
                noteArea.cursorPosition = noteArea.length
            })
        })
    }

    function openNoteViewer(key) {
        if (!root.hasNoteForDate(key)) return
        root.noteDialogDate = key
        root.noteDraft = String(root.calendarNotes[key] || "")
        root.noteOverlayMode = "view"
        Qt.callLater(function() { noteArea.text = root.noteDraft })
    }

    onNoteOverlayModeChanged: {
        if (root.noteOverlayMode === "edit") {
            Qt.callLater(function() {
                Qt.callLater(function() {
                    if (root.noteOverlayMode === "edit")
                        noteArea.forceActiveFocus(Qt.OtherFocusReason)
                })
            })
        }
    }

    function closeNoteOverlay() {
        root.noteOverlayMode = ""
        root.noteDialogDate = ""
        root.noteDraft = ""
        noteArea.text = ""
    }

    function saveCalendarNote() {
        const key = root.noteDialogDate
        if (!key) return
        const text = String(root.noteDraft || "")
        const next = Object.assign({}, root.calendarNotes || ({}))
        if (text.trim().length > 0)
            next[key] = text
        else
            delete next[key]
        root.calendarNotes = next
        Quickshell.execDetached([
            Quickshell.shellDir + "/scripts/calendar_notes",
            "set",
            key,
            text.trim().length > 0 ? text : ""
        ])
        root.closeNoteOverlay()
    }

    Process {
        id: calendarNotesRead
        command: [Quickshell.shellDir + "/scripts/calendar_notes", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.setCalendarNotesFromJson(this.text)
        }
        onExited: function(exitCode) {
            if (exitCode !== 0 && !root.notesLoaded)
                root.setCalendarNotesFromJson("{}")
        }
    }

    Item {
        id: reveal
        anchors.fill: parent
        anchors.margins: 5
        transformOrigin: Item.Bottom

        Column {
            anchors.fill: parent
            Row {
                width: parent.width
                height: 25
                spacing: 4

                Primitives.HoverIconButton {
                    width: 28
                    height: parent.height
                    iconText: Config.calendarPreviousIcon
                    iconSize: Config.calendarPreviousSize
                    iconX: Config.calendarPreviousX
                    iconY: Config.calendarArrowY
                    baseColor: Config.text
                    iconFontFamily: Config.font
                    hoverMode: "text"
                    hoverColor: Config.accent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(-1)
                }

                Text {
                    width: parent.width - 64
                    height: parent.height
                    y: Config.calendarTitleY
                    text: root.monthName(root.month) + " " + root.year
                    color: Config.text
                    font.family: Config.calendarTitleFont
                    font.pixelSize: Config.calendarTitleFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Primitives.HoverIconButton {
                    width: 28
                    height: parent.height
                    iconText: Config.calendarNextIcon
                    iconSize: Config.calendarNextSize
                    iconX: Config.calendarNextX
                    iconY: Config.calendarArrowY
                    baseColor: Config.text
                    iconFontFamily: Config.font
                    hoverMode: "text"
                    hoverColor: Config.accent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(1)
                }
            }
            Row {
                width: parent.width
                height: 25
                Repeater {
                    model: root.names
                    delegate: Text {
                        x: 0
                        width: parent.width / 7
                        height: parent.height
                        y: Config.calendarWeekdayY
                        text: modelData
                        color: Config.textDim
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: Config.calendarWeekdayFontSize
                        font.family: Config.calendarWeekdayFont
                    }
                }
            }
            Grid {
                width: parent.width
                columns: 7
                rowSpacing: 3
                Repeater {
                    model: root.gridCellCount()
                    delegate: Rectangle {
                        width: parent.width / 7
                        height: 30
                        color: dayMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Config.transparent
                        property int day: index - root.firstDay() + 1
                        property string dateKey: root.dateKeyForDay(day)
                        property bool hasNote: root.hasNoteForDate(dateKey)

                        Text {
                            id: dayNumberText
                            x: 0
                            width: parent.width
                            height: parent.height
                            y: Config.calendarDayY
                            text: root.calendarGridDayNumber(parent.day)
                            color: dayMouse.containsMouse
                                ? Config.accent
                                : root.calendarDayColor(parent.dateKey, parent.day)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: Config.calendarDayFontSize
                            font.family: Config.calendarDayFont
                        }

                        TextMetrics {
                            id: noteDayMetrics
                            font: dayNumberText.font
                            text: dayNumberText.text
                        }

                        // A frame surrounds the number; all other marker styles can be
                        // placed at any of the eight positions around the glyph.
                        Rectangle {
                            visible: parent.hasNote && Config.calendarNoteMarkerStyle === "frame"
                            // Extra right-side breathing room helps fonts such as LED,
                            // whose glyphs can look visually cramped against a centered frame.
                            width: Math.max(8, noteDayMetrics.advanceWidth + 12)
                            height: Config.calendarDayFontSize + 6
                            x: (parent.width - width) / 2 + 2
                            y: Config.calendarDayY + (parent.height - Config.calendarDayFontSize) / 2 - 3
                            color: "transparent"
                            border.color: root.noteMarkerColor(parent.dateKey, Config.calendarNoteFrameColor)
                            border.width: 1
                            radius: 3
                        }

                        Item {
                            id: noteMarker
                            property string markerStyle: Config.calendarNoteMarkerStyle
                            property string markerPosition: Config.calendarNoteMarkerPosition
                            property string dateKey: parent.dateKey
                            property color markerColor: root.noteMarkerColor(dateKey, Config.accent)
                            property real glyphWidth: Math.max(1, noteDayMetrics.advanceWidth)
                            property real glyphLeft: (parent.width - glyphWidth) / 2
                            property real glyphRight: glyphLeft + glyphWidth
                            property real glyphTop: Config.calendarDayY + (parent.height - Config.calendarDayFontSize) / 2
                            property real glyphBottom: glyphTop + Config.calendarDayFontSize
                            property bool sideCenter: markerPosition === "leftCenter" || markerPosition === "rightCenter"
                            visible: parent.hasNote && markerStyle !== "frame"
                            width: markerStyle === "note" ? 12
                                 : markerStyle === "ring" ? 7
                                 : markerStyle === "line" ? (sideCenter ? 2 : glyphWidth + 12)
                                 : 5
                            height: markerStyle === "note" ? 12
                                  : markerStyle === "ring" ? 7
                                  : markerStyle === "line" ? (sideCenter ? Math.max(8, Config.calendarDayFontSize - 2) : 2)
                                  : 5
                            x: {
                                if (markerPosition === "leftCenter") return glyphLeft - width - 1
                                if (markerPosition === "rightCenter") return glyphRight + 1
                                if (markerPosition === "topLeft" || markerPosition === "bottomLeft")
                                    return glyphLeft - (markerStyle === "line" ? 0 : width / 2)
                                if (markerPosition === "topRight" || markerPosition === "bottomRight")
                                    return glyphRight - (markerStyle === "line" ? width : width / 2)
                                // Match the frame's extra right-side breathing room for horizontal lines.
                                return (parent.width - width) / 2 + (markerStyle === "line" && !sideCenter ? 2 : 0)
                            }
                            y: {
                                if (markerPosition.indexOf("top") === 0) return glyphTop - height - 1
                                if (markerPosition.indexOf("bottom") === 0) return glyphBottom + 1
                                return glyphTop + (Config.calendarDayFontSize - height) / 2
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: noteMarker.markerStyle !== "note"
                                radius: noteMarker.markerStyle === "dot" ? width / 2
                                      : noteMarker.markerStyle === "ring" ? width / 2
                                      : noteMarker.markerStyle === "line" && !noteMarker.sideCenter ? 1
                                      : 0
                                color: noteMarker.markerStyle === "ring" ? Config.transparent : noteMarker.markerColor
                                border.color: noteMarker.markerStyle === "ring" ? noteMarker.markerColor : Config.transparent
                                border.width: noteMarker.markerStyle === "ring" ? 1 : 0
                            }

                            Text {
                                anchors.fill: parent
                                visible: noteMarker.markerStyle === "note"
                                text: "✎"
                                color: noteMarker.markerColor
                                font.family: "Sans Serif"
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                // Adjacent-month dates navigate to that month; note actions
                                // remain reserved for dates belonging to the visible month.
                                if (parent.day < 1) {
                                    root.shiftMonth(-1)
                                    return
                                }
                                if (parent.day > root.daysInMonth()) {
                                    root.shiftMonth(1)
                                    return
                                }
                                if (!parent.dateKey) return
                                if (mouse.button === Qt.RightButton)
                                    root.openNoteEditor(parent.dateKey)
                                else if (mouse.button === Qt.LeftButton)
                                    root.openNoteViewer(parent.dateKey)
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            if (root.noteOverlayMode !== "") return
            if (wheel.angleDelta.y > 0)
                root.shiftMonth(1)
            else if (wheel.angleDelta.y < 0)
                root.shiftMonth(-1)
            wheel.accepted = true
        }
    }

    // Compact in-widget editor/viewer. Right-click opens editing; left-click
    // opens this viewer only for dates that already have a note.
    Rectangle {
        id: noteOverlay
        anchors.fill: parent
        z: 100
        visible: root.noteOverlayMode !== ""
        color: "#e6000000"
        border.color: Config.baseColor
        border.width: Config.frameBorderWidth
        radius: Config.frameRadius

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: function(mouse) { mouse.accepted = true }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 7

            Row {
                width: parent.width
                height: 24
                Text {
                    width: parent.width - 30
                    height: parent.height
                    text: "Заметка · " + root.noteDialogDate
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(12)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                Primitives.HoverIconButton {
                    width: 30
                    height: parent.height
                    iconText: "×"
                    iconSize: 20
                    baseColor: Config.text
                    iconFontFamily: "Sans Serif"
                    hoverMode: "none"
                    cursorShape: Qt.ArrowCursor
                    onClicked: root.closeNoteOverlay()
                }
            }

            TextArea {
                id: noteArea
                width: parent.width
                height: parent.height - 69
                text: ""
                focus: root.noteOverlayMode === "edit"
                activeFocusOnPress: true
                readOnly: root.noteOverlayMode === "view"
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                color: Config.text
                selectedTextColor: Config.text
                selectionColor: Config.baseColor
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(12)
                background: Rectangle {
                    color: Config.settingsBackground
                    border.color: Config.baseColor
                    border.width: 1
                    radius: 4
                }
                onTextChanged: {
                    if (root.noteOverlayMode === "edit")
                        root.noteDraft = text
                }
            }

            Row {
                width: parent.width
                height: 28
                spacing: 6
                visible: root.noteOverlayMode === "edit"
                Primitives.StyledTextButton {
                    id: noteSaveButton
                    width: 100
                    height: parent.height
                    text: "Сохранить"
                    onClicked: root.saveCalendarNote()
                }
                Primitives.StyledTextButton {
                    id: noteDeleteButton
                    width: 82
                    height: parent.height
                    text: "Удалить"
                    onClicked: { root.noteDraft = ""; root.saveCalendarNote() }
                }
                Item { width: Math.max(0, parent.width - 100 - 82 - 64 - 18); height: 1 }
                Primitives.StyledTextButton {
                    id: noteCancelButton
                    width: 64
                    height: parent.height
                    text: "Отмена"
                    onClicked: root.closeNoteOverlay()
                }
            }

            Row {
                width: parent.width
                height: 28
                spacing: 6
                visible: root.noteOverlayMode === "view"
                Primitives.StyledTextButton {
                    id: noteEditButton
                    width: 90
                    height: parent.height
                    text: "Изменить"
                    onClicked: root.openNoteEditor(root.noteDialogDate)
                }
                Item { width: Math.max(0, parent.width - 90 - 70 - 12); height: 1 }
                Primitives.StyledTextButton {
                    id: noteCloseButton
                    width: 70
                    height: parent.height
                    text: "Закрыть"
                    onClicked: root.closeNoteOverlay()
                }
            }
        }
    }

    function shiftMonth(delta) {
        const d = new Date(root.year, root.month + delta, 1)
        root.year = d.getFullYear()
        root.month = d.getMonth()
    }

    function firstDay() { let d = new Date(year, month, 1).getDay(); return d === 0 ? 6 : d - 1 }
    function daysInMonth() { return new Date(year, month + 1, 0).getDate() }
    function monthName(m) { return ["Январь","Февраль","Март","Апрель","Май","Июнь","Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь"][m] }
}
