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
    // Forward the host context through this wrapper so the nested ModuleFrame
    // and the row layout see the same logical width and presentation mode.
    readonly property real widthBudget: parent && parent.widthBudget !== undefined
        ? Number(parent.widthBudget) : Number(root.width)
    readonly property string presentationMode: parent && parent.presentationMode !== undefined
        ? String(parent.presentationMode) : "regular"
    readonly property string displayFontFamily: Config.resolveFontFamily(Config.topAppsFont)
    readonly property int displayFontSize: Config.uiFontSize(Config.topAppsFontSize)
    readonly property int effectiveDisplayFontSize: Math.max(6, Math.min(root.displayFontSize,
        Math.floor(root.displayFontSize * Math.max(0.5, Math.min(1, root.layoutRowWidth / 260)))))
    readonly property int displayRowHeight: Math.max(1, root.effectiveDisplayFontSize + 2)
    // The contents now follow the actual host width. Bars and values are
    // compressed together when the module is narrower than the saved default.
    readonly property int layoutContentWidth: Math.max(1, Math.round(root.widthBudget))
    readonly property int layoutRowWidth: Math.max(1, root.layoutContentWidth - 20)
    readonly property int effectiveHorizontalGap: Math.max(2, Math.min(5, Math.round(root.layoutRowWidth * 0.02)))
    readonly property int effectiveValueColumnWidth: Math.max(1, Math.min(root.sectionValueColumnWidth,
        root.layoutRowWidth, Math.max(28, Math.floor(root.layoutRowWidth * 0.34))))
    readonly property int effectiveBarMinimumWidth: Math.max(1, Math.min(18, Math.floor(root.layoutRowWidth * 0.10)))
    readonly property int effectiveBarStartX: Math.max(0, Math.min(Math.max(0, Number(Config.topAppsBarX)),
        Math.max(0, root.layoutRowWidth - root.effectiveValueColumnWidth - root.effectiveHorizontalGap - root.effectiveBarMinimumWidth)))
    readonly property int effectiveBarWidth: Math.max(0, Math.min(Number(Config.topAppsBarWidth),
        root.layoutRowWidth - root.effectiveValueColumnWidth - root.effectiveHorizontalGap - root.effectiveBarStartX))
    // Calculate the widest value once per data/font update, not once per row.
    // The old per-delegate scan made each refresh O(rows²) for no visual benefit.
    readonly property int sectionValueColumnWidth: root.valueColumnWidth(root.sectionEntries)

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
                            property int horizontalGap: root.effectiveHorizontalGap
                            property int valueWidth: root.effectiveValueColumnWidth
                            property int barStartX: root.effectiveBarStartX
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
                                       : Math.max(0, root.layoutRowWidth - appRow.valueWidth - 2 * appRow.horizontalGap)
                                height: parent.height
                                text: modelData.name ?? ""
                                color: Config.text
                                font.family: root.displayFontFamily
                                font.pixelSize: root.effectiveDisplayFontSize
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Item {
                                id: usageBar
                                visible: Config.topAppsShowBars && root.effectiveBarWidth > 0
                                x: appRow.barStartX
                                y: Math.round((appRow.height - height) / 2) + Number(Config.topAppsBarY)
                                width: root.effectiveBarWidth
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
                                // Keep the numeric column anchored to the live module width.
                                x: root.layoutRowWidth - width
                                y: 0
                                width: appRow.valueWidth
                                height: parent.height
                                text: modelData.value ?? ""
                                color: Config.text
                                font.family: root.displayFontFamily
                                font.pixelSize: root.effectiveDisplayFontSize
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                // Keep values right-aligned; the column and font contract
                                // shrink together before they can collide with the bar.
                                elide: Text.ElideNone
                            }
                        }
                    }
                }
            }
        }
    }
}
