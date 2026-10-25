import QtQuick
import "../.."

Item {
    id: root
    property bool shown: true
    property string animationStyle: "fade"
    property int duration: Config.animationDuration(250, "appearance")
    // Freeze style/duration for each in-flight transition. Settings can change
    // while a window is moving; applying new animation types mid-flight would
    // otherwise switch opacity/translation targets halfway through.
    property string activeAnimationStyle: "fade"
    property int activeDuration: 250
    readonly property bool running: showTransition.running || hideTransition.running
    // Expose the actual animated item so a parent layer-shell window can tie
    // its compositor blur region to the content instead of the stationary
    // window rectangle. Using x/y (rather than a Translate transform) makes
    // Region observe geometry changes during slide transitions.
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
            x: 0
            y: 0
            visible: true
            enabled: root.shown
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
        // Each module's own style is authoritative: "none" means immediate
        // visibility changes, with no fallback to fade or other transitions.
        return root.activeAnimationStyle !== "none" && root.activeDuration > 0
    }

    function applyImmediate(visible) {
        showTransition.stop()
        hideTransition.stop()
        contentHost.visible = visible
        contentHost.enabled = visible
        contentHost.x = visible ? 0 : hiddenX()
        contentHost.y = visible ? 0 : hiddenY()
        contentHost.opacity = (visible || !usesOpacity()) ? 1 : 0
    }

    function handleAnimationStyleChange() {
        // Selecting "none" is an explicit request to stop all current motion too.
        // Do not let an already-running fade/slide finish after the user disables it.
        if (root.animationStyle === "none") {
            activeAnimationStyle = "none"
            // Zero is an explicit second guard: even if a visibility change
            // races with the style binding, no transition can run.
            activeDuration = 0
            applyImmediate(root.shown)
            return
        }
        // Keep other style changes stable during an in-flight transition.
        if (root.running) return
        activeAnimationStyle = root.animationStyle
        activeDuration = root.duration
        applyImmediate(root.shown)
    }

    function handleDurationChange() {
        // Positive duration changes apply to the next transition. If animation
        // was disabled (or set to zero) while moving, settle immediately so the
        // window does not keep animating against the user's new preference.
        if (root.running) {
            if (root.duration <= 0)
                applyImmediate(root.shown)
            return
        }
        activeDuration = root.duration
    }

    function startTransition() {
        // Handle `none` before capturing the current transition state. This
        // removes any ordering dependency between Config changes and `shown`.
        if (root.animationStyle === "none") {
            activeAnimationStyle = "none"
            activeDuration = 0
            applyImmediate(root.shown)
            return
        }

        var wasRunning = root.running
        var wasVisible = contentHost.visible
        if (!wasRunning) {
            activeAnimationStyle = root.animationStyle
            activeDuration = root.duration
        }
        showTransition.stop()
        hideTransition.stop()

        // Style or duration settings can change while the component is fully
        // hidden. Do not resurrect its content just to animate another exit.
        // This also refreshes the hidden endpoint after size/direction changes.
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
            if (!wasVisible) {
                contentHost.x = hiddenX()
                contentHost.y = hiddenY()
                contentHost.opacity = usesOpacity() ? 0 : 1
            }
            showTransition.start()
        } else {
            contentHost.visible = true
            contentHost.enabled = false
            hideTransition.start()
        }
    }

    ParallelAnimation {
        id: showTransition
        NumberAnimation {
            target: contentHost
            property: "opacity"
            to: 1
            duration: root.usesOpacity() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentHost
            property: "x"
            to: 0
            duration: root.usesHorizontalSlide() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentHost
            property: "y"
            to: 0
            duration: root.usesVerticalSlide() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        onFinished: {
            if (root.shown) {
                contentHost.visible = true
                contentHost.enabled = true
                contentHost.x = 0
                contentHost.y = 0
                if (root.usesOpacity()) contentHost.opacity = 1
            }
        }
    }

    ParallelAnimation {
        id: hideTransition
        // Slide transitions must keep the content opaque. A zero-duration
        // opacity animation to 0 used to make slide-out disappear instantly,
        // even though the host's position was meant to animate. Fade alone
        // owns opacity; slides animate the same content x/y geometry on entry
        // and exit so window blur/input regions can track the moving content.
        NumberAnimation {
            target: contentHost
            property: "opacity"
            to: root.usesOpacity() ? 0 : 1
            duration: root.usesOpacity() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentHost
            property: "x"
            to: root.hiddenX()
            duration: root.usesHorizontalSlide() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentHost
            property: "y"
            to: root.hiddenY()
            duration: root.usesVerticalSlide() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        onFinished: {
            if (!root.shown) {
                contentHost.visible = false
                contentHost.enabled = false
                // Keep the content item at the hidden endpoint so the next
                // show starts from the same off-screen position. The actual
                // x/y geometry also keeps the compositor blur region in sync.
                contentHost.x = root.hiddenX()
                contentHost.y = root.hiddenY()
                contentHost.opacity = root.usesOpacity() ? 0 : 1
            }
        }
    }

    onShownChanged: startTransition()
    onAnimationStyleChanged: handleAnimationStyleChange()
    onDurationChanged: handleDurationChange()
    onWidthChanged: {
        if (!root.shown && !root.running) {
            activeAnimationStyle = root.animationStyle
            activeDuration = root.duration
            applyImmediate(false)
        }
    }
    onHeightChanged: {
        if (!root.shown && !root.running) {
            activeAnimationStyle = root.animationStyle
            activeDuration = root.duration
            applyImmediate(false)
        }
    }
    Component.onCompleted: {
        activeAnimationStyle = root.animationStyle
        activeDuration = root.duration
        applyImmediate(root.shown)
    }
}
