import QtQuick
import ".."
import "primitives" as Primitives

Item {
    id: root
    width: 315
    height: 96
    property var monitor
    // One UI instance now represents one independently positionable section.
    // The System Monitor service remains shared and publishes both data sets.
    property string sectionType: "cpu" // "cpu" or "ram"
    readonly property var cpuEntries: root.monitor?.data?.top_apps?.cpu ?? []
    readonly property var memoryEntries: root.monitor?.data?.top_apps?.mem ?? []
    readonly property var sectionEntries: sectionType === "ram" ? memoryEntries : cpuEntries
    readonly property string sectionTitle: sectionType === "ram" ? Config.topAppsRamHeaderTitle : Config.topAppsCpuHeaderTitle
    readonly property string sectionSubtitle: sectionType === "ram" ? Config.topAppsRamHeaderSubtitle : Config.topAppsCpuHeaderSubtitle
    readonly property color sectionFillColor: sectionType === "ram" ? Config.topAppsRamBarColor : Config.topAppsCpuBarColor
    readonly property color sectionTrackColor: sectionType === "ram" ? Config.ramTrack : Config.metricTrack
    readonly property string sectionModuleName: sectionType === "ram" ? "topAppsRam" : "topAppsCpu"
    readonly property string displayFontFamily: String(Config.topAppsFont || "").trim() !== ""
                                                  ? String(Config.topAppsFont).trim()
                                                  : Qt.application.font.family
    readonly property int displayFontSize: Math.max(1, Math.round(Number(Config.topAppsFontSize) * (Number(Config.fontSize) > 0 ? Number(Config.fontSize) : 12) / 12))
    readonly property int displayRowHeight: Math.max(1, displayFontSize + 2)

    // Reserve enough width for the longest value so larger RAM values
    // (for example "1001.1 Mb") remain fully readable.
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

    Primitives.ModuleFrame {
        id: moduleFrame
        anchors.fill: parent
        moduleName: root.sectionModuleName

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
                            text: root.sectionTitle
                            color: root.sectionFillColor
                            font.family: root.displayFontFamily
                            font.pixelSize: Config.uiFontSize(Config.topAppsHeaderTitleFontSize)
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: root.sectionSubtitle
                            color: Config.textMuted
                            font.family: root.displayFontFamily
                            font.pixelSize: Config.uiFontSize(Config.topAppsHeaderSubtitleFontSize)
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Config.topAppsRowSpacing

                    Repeater {
                        model: root.sectionEntries

                        delegate: Row {
                            id: appRow
                            property real relativeUsage: Math.max(0, Math.min(1, Number(modelData.ratio ?? 0)))
                            width: parent.width
                            height: root.displayRowHeight
                            spacing: 5

                            Text {
                                width: Config.topAppsShowBars ? 98 : Math.max(40, parent.width - root.valueColumnWidth(root.sectionEntries) - 2 * appRow.spacing)
                                text: modelData.name ?? ""
                                color: Config.text
                                font.family: root.displayFontFamily
                                font.pixelSize: root.displayFontSize
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Item {
                                visible: Config.topAppsShowBars
                                width: Config.topAppsShowBars ? Math.max(0, parent.width - 98 - 5 - root.valueColumnWidth(root.sectionEntries) - 5) : 0
                                height: 6
                                anchors.verticalCenter: parent.verticalCenter

                                Primitives.ProgressTrack {
                                    anchors.fill: parent
                                    value: appRow.relativeUsage * 100
                                    radius: 3
                                    fillColor: root.sectionFillColor
                                    trackColor: root.sectionTrackColor
                                }
                            }

                            Text {
                                width: root.valueColumnWidth(root.sectionEntries)
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
