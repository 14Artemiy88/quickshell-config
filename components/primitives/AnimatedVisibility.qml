import QtQuick
import "../.."

Item {
    id: root
    property bool shown: true
    property string animationStyle: "fade"
    // Profiles control motion curves, not module-specific durations. Standard
    // preserves the historical OutCubic behavior. Spatial also applies a
    // restrained scale morph; Effects changes easing without geometry.
    property string animationProfile: "standard"
    property int duration: Config.animationDuration(250, "appearance")
    // Freeze all transition parameters for each in-flight transition. Settings
    // changes must not alter the path halfway through an animation.
    property string activeAnimationStyle: "fade"
    property string activeAnimationProfile: "standard"
    // Spatial transitions add a restrained scale morph to the same normalized
    // progress value. The value is frozen for each in-flight transition.
    property real spatialScale: 0.97
    property real activeSpatialScale: 0.97
    property int activeDuration: 250
    // Reversing a transition only animates the remaining normalized distance.
    // This keeps quick toggles responsive instead of replaying a full duration.
    property int activeTransitionDuration: 250
    // One normalized progress value drives position and opacity together:
    // 0 = fully shown, 1 = fully hidden. This keeps multi-property transitions
    // synchronized and lets the blur region follow the actual content geometry.
    property real transitionProgress: 0
    // Freeze slide distance at transition start. Resizing a panel while it is
    // moving must not change its trajectory or cause a visible jump.
    property real activeHiddenX: 0
    property real activeHiddenY: 0
    // Cache large, text-heavy panels as a texture while they move. This avoids
    // repeatedly rasterizing every child at fractional slide coordinates.
    property bool cacheContent: false
    readonly property bool running: showTransition.running || hideTransition.running
    readonly property Item blurRegionItem: contentHost

    default property alias contentData: contentHost.data

    Item {
        id: exitHost
        anchors.fill: parent
        x: 0
        y: 0

        Item {
            id: contentHost
            width: parent.width
            height: parent.height
            x: root.transitionProgress * root.activeHiddenX
            y: root.transitionProgress * root.activeHiddenY
            opacity: root.usesOpacity() ? 1 - root.transitionProgress : 1
            scale: root.activeAnimationProfile === "spatial" ? 1 - root.transitionProgress * (1 - root.activeSpatialScale) : 1
            transformOrigin: Item.Center
            layer.enabled: root.cacheContent
            layer.smooth: root.cacheContent
            visible: true
            enabled: true
        }
    }

    function hiddenX() {
        if (root.activeAnimationStyle === "slideLeft") return -root.width
        if (root.activeAnimationStyle === "slideRight") return root.width
        return 0
    }

    function hiddenY() {
        if (root.activeAnimationStyle === "slideUp") return -root.height
        if (root.activeAnimationStyle === "slideDown") return root.height
        return 0
    }

    function captureTransitionGeometry() {
        activeHiddenX = hiddenX()
        activeHiddenY = hiddenY()
    }

    function usesOpacity() {
        return root.activeAnimationStyle === "fade"
    }

    function usesHorizontalSlide() {
        return root.activeAnimationStyle === "slideLeft" || root.activeAnimationStyle === "slideRight"
    }

    function usesVerticalSlide() {
        return root.activeAnimationStyle === "slideUp" || root.activeAnimationStyle === "slideDown"
    }

    function animationAllowed() {
        return root.activeAnimationStyle !== "none" && root.activeDuration > 0
    }

    function transitionDurationFor(targetProgress) {
        var remaining = Math.abs(Number(targetProgress) - Number(root.transitionProgress))
        remaining = Math.max(0, Math.min(1, remaining))
        return Math.max(1, Math.round(root.activeDuration * remaining))
    }

    function applyImmediate(visible) {
        showTransition.stop()
        hideTransition.stop()
        contentHost.visible = visible
        contentHost.enabled = visible
        transitionProgress = visible ? 0 : 1
    }

    function handleAnimationStyleChange() {
        if (root.animationStyle === "none") {
            activeAnimationStyle = "none"
            captureTransitionGeometry()
            activeDuration = 0
            applyImmediate(root.shown)
            return
        }
        if (root.running) return
        activeAnimationStyle = root.animationStyle
        captureTransitionGeometry()
        activeDuration = root.duration
        applyImmediate(root.shown)
    }

    function normalizedSpatialScale() {
        return Math.max(0.9, Math.min(1, Number(root.spatialScale) || 0.97))
    }

    function handleAnimationProfileChange() {
        if (root.running) return
        activeAnimationProfile = root.animationProfile
        activeSpatialScale = root.normalizedSpatialScale()
    }

    function handleSpatialScaleChange() {
        if (root.running) return
        activeSpatialScale = root.normalizedSpatialScale()
    }

    function handleDurationChange() {
        if (root.running) {
            if (root.duration <= 0)
                applyImmediate(root.shown)
            return
        }
        activeDuration = root.duration
    }

    function startTransition() {
        if (root.animationStyle === "none") {
            activeAnimationStyle = "none"
            activeAnimationProfile = root.animationProfile
            captureTransitionGeometry()
            activeSpatialScale = root.normalizedSpatialScale()
            activeDuration = 0
            applyImmediate(root.shown)
            return
        }

        var wasRunning = root.running
        var wasVisible = contentHost.visible
        if (!wasRunning) {
            activeAnimationStyle = root.animationStyle
            activeAnimationProfile = root.animationProfile
            activeSpatialScale = root.normalizedSpatialScale()
            captureTransitionGeometry()
            activeDuration = root.duration
        }
        showTransition.stop()
        hideTransition.stop()

        // A fully hidden item must not be resurrected for another exit.
        if (!root.shown && !wasVisible) {
            applyImmediate(false)
            return
        }

        if (!animationAllowed()) {
            applyImmediate(root.shown)
            return
        }

        if (root.shown) {
            contentHost.visible = true
            contentHost.enabled = true
            if (!wasVisible)
                transitionProgress = 1
            activeTransitionDuration = transitionDurationFor(0)
            showTransition.start()
        } else {
            contentHost.visible = true
            contentHost.enabled = false
            activeTransitionDuration = transitionDurationFor(1)
            hideTransition.start()
        }
    }

    NumberAnimation {
        id: showTransition
        target: root
        property: "transitionProgress"
        to: 0
        duration: root.activeTransitionDuration
        easing.type: Config.animationEasingType(root.activeAnimationProfile, "enter")
        onFinished: {
            if (root.shown) {
                contentHost.visible = true
                contentHost.enabled = true
                root.transitionProgress = 0
            }
        }
    }

    NumberAnimation {
        id: hideTransition
        target: root
        property: "transitionProgress"
        to: 1
        duration: root.activeTransitionDuration
        easing.type: Config.animationEasingType(root.activeAnimationProfile, "exit")
        onFinished: {
            if (!root.shown) {
                contentHost.visible = false
                contentHost.enabled = false
                root.transitionProgress = 1
            }
        }
    }

    onShownChanged: startTransition()
    onAnimationStyleChanged: handleAnimationStyleChange()
    onAnimationProfileChanged: handleAnimationProfileChange()
    onSpatialScaleChanged: handleSpatialScaleChange()
    onDurationChanged: handleDurationChange()
    onWidthChanged: {
        if (!root.shown && !root.running) {
            activeAnimationStyle = root.animationStyle
            activeAnimationProfile = root.animationProfile
            activeSpatialScale = root.normalizedSpatialScale()
            captureTransitionGeometry()
            activeDuration = root.duration
            applyImmediate(false)
        }
    }
    onHeightChanged: {
        if (!root.shown && !root.running) {
            activeAnimationStyle = root.animationStyle
            activeAnimationProfile = root.animationProfile
            activeSpatialScale = root.normalizedSpatialScale()
            captureTransitionGeometry()
            activeDuration = root.duration
            applyImmediate(false)
        }
    }
    Component.onCompleted: {
        activeAnimationStyle = root.animationStyle
        activeAnimationProfile = root.animationProfile
        activeSpatialScale = root.normalizedSpatialScale()
        captureTransitionGeometry()
        activeDuration = root.duration
        applyImmediate(root.shown)
    }
}
