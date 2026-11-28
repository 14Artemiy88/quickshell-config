import QtQuick
import "../.."
import "../../js/ModulePresentation.js" as ModulePresentation

Rectangle {
    id: root
    // `compact` remains as a legacy explicit hint for existing components.
    // New responsive layouts should use presentationMode / compactPresentation.
    property bool compact: false
    property string presentationModeOverride: "auto"
    readonly property string hostPresentationMode: {
        var host = parent
        return host && host.presentationMode !== undefined ? String(host.presentationMode) : ""
    }
    readonly property string presentationMode: {
        if (root.presentationModeOverride !== "auto")
            return ModulePresentation.normalizeMode(root.presentationModeOverride, "regular")
        if (root.hostPresentationMode !== "")
            return ModulePresentation.normalizeMode(root.hostPresentationMode, "regular")
        return ModulePresentation.resolveMode(root.width, "auto", 260, 420)
    }
    readonly property real widthBudget: {
        var host = parent
        return host && host.widthBudget !== undefined ? Number(host.widthBudget) : Number(root.width)
    }
    readonly property bool compactPresentation: root.compact || root.presentationMode === "compact"
    readonly property bool regularPresentation: root.presentationMode === "regular"
    readonly property bool widePresentation: root.presentationMode === "wide"
    readonly property bool presentationActive: {
        var host = parent
        return host && host.active !== undefined ? Boolean(host.active) : true
    }
    property string moduleName: ""
    property color moduleBackgroundColor: Config.background
    readonly property bool moduleFrameVisible: !moduleName || !Settings.loaded || Settings.moduleFrames[moduleName] !== false
    readonly property bool moduleBackgroundVisible: !moduleName || !Settings.loaded || Settings.moduleBackgrounds[moduleName] !== false

    color: moduleBackgroundVisible ? moduleBackgroundColor : Config.transparent
    border.color: moduleFrameVisible ? Config.baseColor : Config.transparent
    border.width: moduleFrameVisible && Config.cardBordersEnabled ? Config.frameBorderWidth : 0
    radius: Config.scaledCornerRadius(Config.frameRadius)
    antialiasing: true
    clip: false
}
