import QtQuick
import ".."
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    property int offsetX: 0
    property int offsetY: 0
    property int contentWidth: 315
    property int contentHeight: 100
    property bool bottomLayer: true
    property bool keyboardEnabled: false
    property bool backgroundBlurEnabled: false
    property int backgroundBlurRadius: 7
    screen: {
        const match = Quickshell.screens.find(s =>
            s.name === Config.monitorName ||
            s.model === Config.monitorName ||
            s.toString() === Config.monitorName
        );
        return match || Quickshell.screens[0];
    }
    implicitWidth: contentWidth
    implicitHeight: contentHeight
    color: Config.transparent
    focusable: keyboardEnabled
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.top: true
    margins.left: offsetX
    margins.top: offsetY
    WlrLayershell.layer: bottomLayer ? WlrLayer.Bottom : WlrLayer.Top

    // Blur what is behind this layer-shell surface, not its own contents.
    // Requires compositor support for ext-background-effect-v1.
    BackgroundEffect.blurRegion: Region {
        item: root.backgroundBlurEnabled ? root.contentItem : null
        radius: Math.max(0, root.backgroundBlurRadius)
    }
}
