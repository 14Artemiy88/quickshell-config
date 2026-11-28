import QtQuick
import ".."
import Quickshell
import Quickshell.Wayland
import "../js/ModulePresentation.js" as ModulePresentation
import "../js/AnimationCurves.js" as AnimationCurves

PanelWindow {
    id: root
    property int offsetX: 0
    property int offsetY: 0
    property int contentWidth: 315
    property int contentHeight: 100
    // Directional entry/exit animations may legitimately overshoot their
    // nominal geometry. Expand the transparent layer-shell surface only by
    // the curve's measured overflow, while keeping visible content at the
    // configured coordinates and preserving the original input geometry.
    property string visibilityAnimationStyle: "none"
    property string visibilityAnimationProfile: "ease-out"
    readonly property real visibilityOvershootFactor: AnimationCurves.overshootFactor(root.visibilityAnimationProfile)
    readonly property real visibilityOverscanX: (root.visibilityAnimationStyle === "slideLeft" || root.visibilityAnimationStyle === "slideRight")
        ? Math.ceil(Math.max(0, Number(root.contentWidth) || 0) * root.visibilityOvershootFactor) : 0
    readonly property real visibilityOverscanY: (root.visibilityAnimationStyle === "slideUp" || root.visibilityAnimationStyle === "slideDown")
        ? Math.ceil(Math.max(0, Number(root.contentHeight) || 0) * root.visibilityOvershootFactor) : 0
    readonly property real visualContentWidth: Math.max(1, Math.round(root.contentWidth * root.surfaceScale))
    readonly property real visualContentHeight: Math.max(1, Math.round(root.contentHeight * root.surfaceScale))
    readonly property real visibilityOverscanPhysicalX: Math.round(root.visibilityOverscanX * root.surfaceScale)
    readonly property real visibilityOverscanPhysicalY: Math.round(root.visibilityOverscanY * root.surfaceScale)
    property bool bottomLayer: true
    property bool keyboardEnabled: false
    property bool backgroundBlurEnabled: root.moduleName !== "" && Settings.moduleBlurEnabled[root.moduleName] === true
    property int backgroundBlurRadius: Config.backgroundBlurRadius
    // Animated module windows keep their transparent layer-shell surface alive
    // to avoid compositor-level open/close fades overriding the module's
    // explicit "none" animation style. An empty input region makes a hidden
    // surface click-through, while blur follows the actually moving content.
    property bool manageInputMask: false
    property bool inputMaskEnabled: true
    property Item backgroundBlurItem: contentHost
    property bool backgroundBlurVisible: true
    property string moduleName: ""
    property bool layoutEditMode: false
    property bool settingsDragMode: false
    property int normalWlrLayer: bottomLayer ? WlrLayer.Bottom : WlrLayer.Top
    readonly property real surfaceScale: root.moduleName === "settings"
        ? Config.settingsUiScaleFactor() : Config.moduleUiScale()
    // Built-in modules share one width-to-presentation contract. The default
    // breakpoints use logical pixels, before surfaceScale is applied; modules
    // may opt into a fixed mode when their content requires it.
    property string presentationModeOverride: "auto"
    property int compactWidthBreakpoint: 260
    property int wideWidthBreakpoint: 420
    readonly property string presentationMode: ModulePresentation.resolveMode(
        root.contentWidth,
        root.presentationModeOverride,
        root.compactWidthBreakpoint,
        root.wideWidthBreakpoint
    )
    property int editWlrLayer: WlrLayer.Top
    property bool liveDragging: false
    signal layoutDragFinished()
    signal layoutDragCanceled()
    property var layoutEditor: null
    property real dragBaseGlobalX: 0
    property real dragBaseGlobalY: 0
    property real dragPressX: 0
    property real dragPressY: 0
    property string screenName: {
        if (root.settingsDragMode)
            return String(Settings.settingsMonitorName || Config.monitorName)
        var configured = root.moduleName && Settings.moduleMonitors ? Settings.moduleMonitors[root.moduleName] : ""
        return String(configured || Config.monitorName)
    }

    function screenMatchesName(screen, name) {
        if (!screen || !name) return false
        var wanted = String(name).trim().toLowerCase()
        return String(screen.name || "").trim().toLowerCase() === wanted
            || String(screen.model || "").trim().toLowerCase() === wanted
            || String(screen).trim().toLowerCase() === wanted
    }

    function screenStorageName(screen) {
        if (!screen) return ""
        if (screen.name && String(screen.name).trim() !== "")
            return String(screen.name)
        if (screen.model && String(screen.model).trim() !== "")
            return String(screen.model)
        return ""
    }

    function findScreenForGlobalPoint(globalX, globalY) {
        var nearest = null
        var nearestDistance = Number.POSITIVE_INFINITY
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var s = Quickshell.screens[i]
            if (!s) continue
            var sx = Number(s.x || 0)
            var sy = Number(s.y || 0)
            var sw = Number(s.width || 0)
            var sh = Number(s.height || 0)
            if (globalX >= sx && globalX < sx + sw && globalY >= sy && globalY < sy + sh)
                return s
            var cx = Math.max(sx, Math.min(globalX, sx + sw))
            var cy = Math.max(sy, Math.min(globalY, sy + sh))
            var dx = globalX - cx
            var dy = globalY - cy
            var distance = dx * dx + dy * dy
            if (distance < nearestDistance) {
                nearestDistance = distance
                nearest = s
            }
        }
        return nearest || root.screen || Quickshell.screens[0] || null
    }

    function resolveScreen(name) {
        var wanted = String(name || "").trim()
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            if (screenMatchesName(Quickshell.screens[i], wanted))
                return Quickshell.screens[i]
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    screen: root.resolveScreen(root.screenName || Config.monitorName)
    implicitWidth: Math.max(1, root.visualContentWidth + root.visibilityOverscanPhysicalX * 2)
    implicitHeight: Math.max(1, root.visualContentHeight + root.visibilityOverscanPhysicalY * 2)
    color: Config.transparent
    focusable: keyboardEnabled
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.top: true
    margins.left: root.offsetX - root.visibilityOverscanPhysicalX
    margins.top: root.offsetY - root.visibilityOverscanPhysicalY
    WlrLayershell.layer: root.layoutEditMode ? root.editWlrLayer : root.normalWlrLayer
    mask: root.manageInputMask ? managedInputMask : null

    Region {
        id: managedInputMask
        item: root.inputMaskEnabled ? contentHost : null
        // Null item + empty geometry is an explicitly empty click-through mask.
        width: 0
        height: 0
    }

    default property alias contentData: contentHost.data

    Item {
        id: contentHost
        // Read-only host context consumed by the root item of a built-in module.
        // `active` follows the owning layer-shell surface; hidden modules can
        // pause view-only work without destroying their persistent state.
        readonly property string presentationMode: root.presentationMode
        readonly property real widthBudget: root.contentWidth
        readonly property bool active: root.visible
        x: root.visibilityOverscanPhysicalX
        y: root.visibilityOverscanPhysicalY
        // Children keep their stored/logical dimensions; only the rendered
        // subtree and its input coordinates are scaled as one surface.
        width: root.contentWidth
        height: root.contentHeight
        scale: root.surfaceScale
        transformOrigin: Item.TopLeft
        z: 0
    }

    Item {
        id: editOverlay
        x: root.visibilityOverscanPhysicalX
        y: root.visibilityOverscanPhysicalY
        width: root.visualContentWidth
        height: root.visualContentHeight
        visible: root.layoutEditMode && root.moduleName !== "" && !root.settingsDragMode
        z: 10000

        Rectangle {
            id: editBorder
            anchors.fill: parent
            visible: !root.liveDragging
            color: "transparent"
            border.color: Config.accent
            border.width: Math.max(2, Math.round((Config.frameBorderWidth + 1) * root.surfaceScale))
            radius: Math.round(Config.scaledCornerRadius(Config.frameRadius) * root.surfaceScale)
            antialiasing: true
        }

        Rectangle {
            id: editLabelBox
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Math.round(5 * root.surfaceScale)
            visible: !root.liveDragging
            width: editLabel.implicitWidth + Math.round(14 * root.surfaceScale)
            height: editLabel.implicitHeight + Math.round(8 * root.surfaceScale)
            radius: Math.round(4 * root.surfaceScale)
            color: Config.accent
            border.color: Config.accent
            border.width: Math.max(1, Math.round(root.surfaceScale))

            Text {
                id: editLabel
                anchors.centerIn: parent
                text: root.moduleName
                color: Config.black
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(11)
                font.bold: true
            }
        }

        MouseArea {
            id: editDragArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            hoverEnabled: true

            function finishDrag(mouseX, mouseY) {
                if (!root.liveDragging)
                    return

                var currentGlobalX = root.dragBaseGlobalX + (Number(mouseX) - root.dragPressX)
                var currentGlobalY = root.dragBaseGlobalY + (Number(mouseY) - root.dragPressY)
                var currentScreen = root.findScreenForGlobalPoint(
                    currentGlobalX + root.visualContentWidth / 2,
                    currentGlobalY + root.visualContentHeight / 2
                )
                var targetName = root.screenStorageName(currentScreen)
                var localX = currentGlobalX - Number(currentScreen && currentScreen.x || 0)
                var localY = currentGlobalY - Number(currentScreen && currentScreen.y || 0)

                if (root.layoutEditor)
                    root.layoutEditor.endProxyDrag()

                Settings.endGeometryDrag(root.moduleName, targetName, localX, localY)

                root.liveDragging = false
                Qt.callLater(function() {
                    contentHost.opacity = 1
                })
            }

            onPressed: function(mouse) {
                if (!root.layoutEditMode || root.liveDragging)
                    return

                root.dragPressX = Number(mouse.x)
                root.dragPressY = Number(mouse.y)
                root.dragBaseGlobalX = Number(root.screen && root.screen.x || 0) + Number(root.offsetX)
                root.dragBaseGlobalY = Number(root.screen && root.screen.y || 0) + Number(root.offsetY)
                root.liveDragging = true
                if (root.settingsDragMode)
                    Settings.beginSettingsGeometryDrag()
                else
                    Settings.beginGeometryDrag(root.moduleName)

                var startGlobalX = root.dragBaseGlobalX
                var startGlobalY = root.dragBaseGlobalY
                if (root.layoutEditor) {
                    root.layoutEditor.beginProxyDrag(
                        root.moduleName,
                        startGlobalX,
                        startGlobalY,
                        root.visualContentWidth,
                        root.visualContentHeight
                    )
                }

                contentHost.grabToImage(function(result) {
                    if (!root.liveDragging) {
                        contentHost.opacity = 1
                        return
                    }
                    contentHost.opacity = 0
                    if (root.layoutEditor)
                        root.layoutEditor.setProxySource(result.url)
                }, Qt.size(Math.max(1, Math.round(root.visualContentWidth)), Math.max(1, Math.round(root.visualContentHeight))))
            }

            onPositionChanged: function(mouse) {
                if (!pressed || !root.liveDragging)
                    return

                var currentGlobalX = root.dragBaseGlobalX + (Number(mouse.x) - root.dragPressX)
                var currentGlobalY = root.dragBaseGlobalY + (Number(mouse.y) - root.dragPressY)
                if (root.layoutEditor)
                    root.layoutEditor.updateProxyDrag(
                        currentGlobalX,
                        currentGlobalY,
                        root.visualContentWidth,
                        root.visualContentHeight
                    )
            }

            onReleased: function(mouse) {
                finishDrag(mouse.x, mouse.y)
            }

            onCanceled: function() {
                if (!root.liveDragging)
                    return
                if (root.layoutEditor)
                    root.layoutEditor.endProxyDrag()
                if (!root.settingsDragMode)
                    Settings.cancelGeometryDrag(root.moduleName)
                root.layoutDragCanceled()
                root.liveDragging = false
                contentHost.opacity = 1
            }
        }
    }

    // Blur what is behind this layer-shell surface, not its own contents.
    // Requires compositor support for ext-background-effect-v1.
    BackgroundEffect.blurRegion: Region {
        item: root.backgroundBlurEnabled && root.backgroundBlurVisible ? root.backgroundBlurItem : null
        radius: Math.max(0, root.backgroundBlurRadius)
    }
}
