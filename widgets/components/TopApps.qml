import QtQuick
import ".."
import "primitives" as Primitives

Item {
    id: root
    width: 315
    height: 198
    property var monitor
    readonly property var cpuEntries: root.monitor?.data?.top_apps?.cpu ?? []
    readonly property var memoryEntries: root.monitor?.data?.top_apps?.mem ?? []
    readonly property string displayFontFamily: String(Config.topAppsFont || "").trim() !== ""
                                                  ? String(Config.topAppsFont).trim()
                                                  : Qt.application.font.family
    readonly property int displayFontSize: Math.max(1, Math.round(Number(Config.topAppsFontSize) * (Number(Config.fontSize) > 0 ? Number(Config.fontSize) : 12) / 12))
    readonly property int displayRowHeight: Math.max(1, displayFontSize + 2)
    readonly property int sectionGap: 5

    // Reserve enough width for the longest value in each section so larger RAM
    // values (for example "1001.1 Mb") remain fully readable. Values contain
    // digits, decimal punctuation and a short unit, so this deliberately uses
    // a conservative per-character estimate based on the configured font size.
    function valueColumnWidth(entries) {
        let maxLength = 1
        if (entries) {
            for (let i = 0; i < entries.length; ++i) {
                const length = String(entries[i]?.value ?? "").length
                if (length > maxLength)
                    maxLength = length
            }
        }
        return Math.max(72, Math.ceil(maxLength * root.displayFontSize * 0.68 + 8))
    }

    Column {
        anchors.fill: parent
        spacing: root.sectionGap

        Repeater {
            model: [
                { title: "CPU", entries: root.cpuEntries, fillColor: Config.accent, trackColor: Config.metricTrack },
                { title: "ПАМЯТЬ", entries: root.memoryEntries, fillColor: Config.ram, trackColor: Config.ramTrack }
            ]

            delegate: Primitives.ModuleFrame {
                id: sectionFrame
                property var section: modelData
                moduleName: "topApps"
                width: parent.width
                height: Math.max(0, (root.height - root.sectionGap) / 2)

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: Math.min(Math.max(0, Config.topAppsTopOffset), Math.max(0, parent.height - 6))
                    anchors.bottomMargin: 3
                    clip: true

                    Column {
                        anchors.fill: parent
                        spacing: 0

                        // Keep the header row completely collapsed and clipped when disabled,
                        // so hidden text cannot paint outside a zero-height row or shift the list.
                        Item {
                            width: parent.width
                            height: Config.topAppsShowHeaders ? 12 : 0
                            clip: true

                            Row {
                                anchors.fill: parent
                                spacing: 5

                                Text {
                                    text: sectionFrame.section.title
                                    color: sectionFrame.section.fillColor
                                    font.family: root.displayFontFamily
                                    font.pixelSize: Config.uiFontSize(10)
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: "ТОП ПРОЦЕССОВ"
                                    color: Config.textMuted
                                    font.family: root.displayFontFamily
                                    font.pixelSize: Config.uiFontSize(9)
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: Config.topAppsRowSpacing

                            Repeater {
                                model: sectionFrame.section.entries

                                delegate: Row {
                                    id: appRow
                                    property real relativeUsage: Math.max(0, Math.min(1, Number(modelData.ratio ?? 0)))
                                    width: parent.width
                                    height: root.displayRowHeight
                                    spacing: 5

                                    Text {
                                        width: Config.topAppsShowBars ? 98 : Math.max(40, parent.width - root.valueColumnWidth(sectionFrame.section.entries) - 2 * appRow.spacing)
                                        text: modelData.name ?? ""
                                        color: Config.text
                                        font.family: root.displayFontFamily
                                        font.pixelSize: root.displayFontSize
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    Item {
                                        visible: Config.topAppsShowBars
                                        width: Config.topAppsShowBars ? Math.max(0, parent.width - 98 - 5 - root.valueColumnWidth(sectionFrame.section.entries) - 5) : 0
                                        height: 6
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 3
                                            color: sectionFrame.section.trackColor
                                        }

                                        Rectangle {
                                            width: parent.width * appRow.relativeUsage
                                            height: parent.height
                                            radius: 3
                                            color: sectionFrame.section.fillColor
                                        }
                                    }

                                    Text {
                                        width: root.valueColumnWidth(sectionFrame.section.entries)
                                        text: modelData.value ?? ""
                                        color: Config.text
                                        font.family: root.displayFontFamily
                                        font.pixelSize: root.displayFontSize
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignVCenter
                                        // The column above is sized for all values in this section;
                                        // don't replace leading digits with an ellipsis.
                                        elide: Text.ElideNone
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
