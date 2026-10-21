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
    readonly property color sectionTrackColor: sectionType === "ram" ? Config.topAppsRamBarTrackColor : Config.topAppsCpuBarTrackColor
    readonly property string sectionModuleName: sectionType === "ram" ? "topAppsRam" : "topAppsCpu"
    readonly property string displayFontFamily: String(Config.topAppsFont || "").trim() !== ""
                                                  ? String(Config.topAppsFont).trim()
                                                  : Qt.application.font.family
    readonly property int displayFontSize: Math.max(1, Math.round(Number(Config.topAppsFontSize) * (Number(Config.fontSize) > 0 ? Number(Config.fontSize) : 12) / 12))
    readonly property int displayRowHeight: Math.max(1, displayFontSize + 2)
    // The host window may extend to show the entire bar, but the logical row
    // width stays tied to the configured module width. This keeps the value
    // column fixed while a longer or right-shifted bar is drawn underneath it.
    readonly property int layoutContentWidth: Math.max(1, Number(
        sectionType === "ram" ? Settings.geometry.topAppsRam[2] : Settings.geometry.topAppsCpu[2]) || 315)
    readonly property int layoutRowWidth: Math.max(1, root.layoutContentWidth - 20)
    readonly property int requiredContentWidth: Config.topAppsShowBars ? Math.ceil(
        Number(Config.topAppsBarX) + Number(Config.topAppsBarWidth) + 20) : 0

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
            x: 10
            y: Math.min(Math.max(0, Config.topAppsTopOffset), Math.max(0, root.height - 6))
            width: Math.max(1, root.width - 20)
            height: Math.max(0, root.height - y - 3)
            clip: false

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

                        delegate: Item {
                            id: appRow
                            property real relativeUsage: Math.max(0, Math.min(1, Number(modelData.ratio ?? 0)))
                            property int horizontalGap: 5
                            property int valueWidth: root.valueColumnWidth(root.sectionEntries)
                            // X and length only affect bar placement; the value column
                            // stays anchored to the logical module width and is painted above it.
                            property int barStartX: Math.max(45, Number(Config.topAppsBarX))
                            property int effectiveBarHeight: Math.max(1, Math.min(root.displayRowHeight, Number(Config.topAppsBarHeight)))
                            width: parent.width
                            height: root.displayRowHeight
                            clip: true

                            Text {
                                x: 0
                                y: 0
                                width: Config.topAppsShowBars
                                       ? Math.max(0, Math.min(appRow.barStartX - appRow.horizontalGap,
                                                              parent.width - appRow.valueWidth - 2 * appRow.horizontalGap))
                                       : Math.max(40, root.layoutRowWidth - appRow.valueWidth - 2 * appRow.horizontalGap)
                                height: parent.height
                                text: modelData.name ?? ""
                                color: Config.text
                                font.family: root.displayFontFamily
                                font.pixelSize: root.displayFontSize
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Item {
                                id: usageBar
                                visible: Config.topAppsShowBars
                                x: appRow.barStartX
                                y: Math.round((appRow.height - height) / 2) + Number(Config.topAppsBarY)
                                width: Math.max(1, Number(Config.topAppsBarWidth))
                                height: appRow.effectiveBarHeight
                                clip: true

                                Primitives.ProgressTrack {
                                    anchors.fill: parent
                                    value: appRow.relativeUsage * 100
                                    radius: Math.min(3, parent.height / 2)
                                    fillColor: root.sectionFillColor
                                    trackColor: root.sectionTrackColor
                                }
                            }

                            Text {
                                // Keep the numeric column anchored to the original
                                // module width even if the transparent host window grows.
                                x: root.layoutRowWidth - width
                                y: 0
                                width: appRow.valueWidth
                                height: parent.height
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
