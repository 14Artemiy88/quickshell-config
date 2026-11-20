import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import Quickshell.Io
import "../.."
import "../../js/NotificationsGeometry.js" as NotificationsGeometry
import "../../js/notifications/NotificationAnimation.js" as NotificationAnimation

Item {
    id: root

    property bool layoutEditMode: false
    property var layoutEditor: null
    property bool layoutDragging: false
    property real dragBaseGlobalX: 0
    property real dragBaseGlobalY: 0
    property real dragPressX: 0
    property real dragPressY: 0
    // Keep the notification surface alive while a removed delegate completes its
    // explicit exit animation. ListView.delayRemove keeps the delegate in layout.
    property int activeNotificationExitCount: 0
    property real notificationListLastContentHeight: 0
    // Keep the layer-surface mapped for the lifetime of the Notifications module.
    // Mapping/unmapping PanelWindow for every toast triggers the compositor's
    // own window open/close fade, which is independent of the selected card style.
    // When idle the surface is reduced to 1x1 and its content is hidden.
    readonly property bool notificationSurfaceActive: notificationServer.trackedNotifications.values.length > 0
        || activeNotificationExitCount > 0 || layoutEditMode
    readonly property int layoutPreviewHeight: 104

    function notificationTargetScreen() {
        var wanted = String((Settings.moduleMonitors || {}).notifications || Config.monitorName || "").trim().toLowerCase()
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var screen = Quickshell.screens[i]
            if (!screen) continue
            if (wanted && (String(screen.name || "").trim().toLowerCase() === wanted
                    || String(screen.model || "").trim().toLowerCase() === wanted
                    || String(screen).trim().toLowerCase() === wanted))
                return screen
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    function notificationCoordinate(index) {
        var values = Settings.geometryForLayout
            ? Settings.geometryForLayout("notifications")
            : ((Settings.geometry || {}).notifications || [-999999, 16, Config.notificationsCardWidth, 0])
        var target = notificationTargetScreen()
        return NotificationsGeometry.resolvedCoordinate(values, index, target ? target.width : 1920, root.notificationCardWidth, 16)
    }

    function notificationTopCoordinate(targetScreen, panelHeight) {
        var screen = targetScreen || root.notificationTargetScreen()
        var verticalOffset = root.notificationCoordinate(1)
        return NotificationsGeometry.resolvedTopCoordinate(
            Config.notificationsVerticalAnchor, verticalOffset,
            Number(screen && screen.height || 1080), Number(panelHeight) || 0
        )
    }

    function finishNotificationCardExit() {
        activeNotificationExitCount = Math.max(0, activeNotificationExitCount - 1)
        if (activeNotificationExitCount === 0)
            notificationListLastContentHeight = Math.max(0, Number(notificationList.contentHeight) || 0)
    }

    function screenStorageName(screen) {
        if (!screen) return ""
        if (screen.name && String(screen.name).trim() !== "") return String(screen.name)
        if (screen.model && String(screen.model).trim() !== "") return String(screen.model)
        return ""
    }

    function findScreenForGlobalPoint(globalX, globalY) {
        var nearest = null
        var nearestDistance = Number.POSITIVE_INFINITY
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var candidate = Quickshell.screens[i]
            if (!candidate) continue
            var sx = Number(candidate.x || 0)
            var sy = Number(candidate.y || 0)
            var sw = Number(candidate.width || 0)
            var sh = Number(candidate.height || 0)
            if (globalX >= sx && globalX < sx + sw && globalY >= sy && globalY < sy + sh)
                return candidate
            var cx = Math.max(sx, Math.min(globalX, sx + sw))
            var cy = Math.max(sy, Math.min(globalY, sy + sh))
            var dx = globalX - cx
            var dy = globalY - cy
            var distance = dx * dx + dy * dy
            if (distance < nearestDistance) {
                nearestDistance = distance
                nearest = candidate
            }
        }
        return nearest || popupWindow.screen || root.notificationTargetScreen() || Quickshell.screens[0] || null
    }

    function finishLayoutDrag(mouseX, mouseY) {
        if (!root.layoutDragging) return

        var globalX = root.dragBaseGlobalX + Number(mouseX) - root.dragPressX
        var globalY = root.dragBaseGlobalY + Number(mouseY) - root.dragPressY
        var targetScreen = root.findScreenForGlobalPoint(
            globalX + popupWindow.width / 2,
            globalY + popupWindow.height / 2
        )
        var localX = globalX - Number(targetScreen && targetScreen.x || 0)
        var localTopY = globalY - Number(targetScreen && targetScreen.y || 0)
        var localY = NotificationsGeometry.storedVerticalOffset(
            Config.notificationsVerticalAnchor, localTopY,
            Number(targetScreen && targetScreen.height || 1080), popupWindow.height
        )

        if (root.layoutEditor) root.layoutEditor.endProxyDrag()
        Settings.endGeometryDrag("notifications", root.screenStorageName(targetScreen), localX, localY)
        root.layoutDragging = false
        notificationContent.opacity = 1
    }

    function cancelLayoutDrag() {
        if (!root.layoutDragging) return
        if (root.layoutEditor) root.layoutEditor.endProxyDrag()
        Settings.cancelGeometryDrag("notifications")
        root.layoutDragging = false
        notificationContent.opacity = 1
    }

    function migrateLegacyNotificationCoordinates() {
        var legacyPosition = String(Config.notificationsLegacyPosition || "")
        if (!legacyPosition) return
        var geometry = Object.assign({}, Settings.geometry || {})
        var current = NotificationsGeometry.normalizeGeometry(geometry.notifications || [-999999, 16, Config.notificationsCardWidth, 0], Config.notificationsCardWidth)
        if (Number(current[0]) < -10000 || !isFinite(Number(current[0]))) {
            var target = notificationTargetScreen()
            current = NotificationsGeometry.migrateLegacyPlacement(
                legacyPosition, Config.notificationsLegacyOffsetX, Config.notificationsLegacyOffsetY,
                target ? target.width : 1920, target ? target.height : 1080,
                Config.notificationsCardWidth, popupWindow.implicitHeight
            )
            // Keep only vertical edge anchoring from the former four-corner mode.
            // The X coordinate remains absolute from the left; Y is now an inset
            // from the selected top or bottom edge.
            Config.notificationsVerticalAnchor = legacyPosition.indexOf("bottom-") === 0 ? "bottom" : "top"
            current[1] = Math.max(0, Math.min(500, Math.round(Number(Config.notificationsLegacyOffsetY) || 16)))
            geometry.notifications = current
            Settings.geometry = geometry
        }
        Config.notificationsLegacyPosition = ""
        Config.notificationsLegacyOffsetX = 16
        Config.notificationsLegacyOffsetY = 16
        Settings.save()
    }

    Component.onCompleted: Qt.callLater(root.migrateLegacyNotificationCoordinates)

    onLayoutEditModeChanged: {
        if (!root.layoutEditMode)
            root.cancelLayoutDrag()
    }

    function escapeNotificationText(value) {
        // Notification bodies can contain both markup and ordinary text. Escape
        // literal HTML metacharacters in text nodes so comparisons such as
        // "5 < 10 and 10 > 5" remain visible when rendered as RichText. Keep
        // already-formed character references intact.
        return String(value || "")
            .replace(/&(?!(?:#\d+|#x[\da-f]+|[a-z][a-z0-9]+);)/gi, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
    }

    function escapeNotificationAttribute(value) {
        return escapeNotificationText(value).replace(/\"/g, "&quot;")
    }

    function safeNotificationColor(value) {
        // Pango's span foreground/background attributes are values, not arbitrary
        // HTML/CSS. Accept common CSS color names, hexadecimal colors, and numeric
        // rgb()/rgba() forms; reject values that could inject extra CSS properties.
        const color = String(value || "").trim()
        if (/^[a-z]{1,24}$/i.test(color)) return color.toLowerCase()
        if (/^#(?:[0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(color)) return color
        if (/^rgba?\(\s*[0-9.]+%?(?:\s*,\s*[0-9.]+%?){2}(?:\s*,\s*[0-9.]+%?)?\s*\)$/i.test(color)) return color
        return ""
    }

    function formatNotificationTag(tag, linkStyle) {
        const parsed = /^<(\/?)\s*(b|strong|i|em|u|a|br|html|tt|span)\b([^>]*)>$/i.exec(tag)
        if (!parsed) return escapeNotificationText(tag)

        const isClosing = parsed[1] === "/"
        const name = String(parsed[2] || "").toLowerCase()
        const attributes = String(parsed[3] || "")

        // KDE/Qt applications commonly wrap notification bodies in <html> and
        // use <tt> for executable paths. Strip the outer document wrapper and
        // translate <tt> to a controlled monospace span instead of exposing the
        // tags as literal text. The ordinary text path is still escaped below.
        if (name === "html") return ""
        if (name === "tt")
            return isClosing ? "</span>" : '<span style="font-family: monospace;">'

        if (name === "span") {
            if (isClosing) return "</span>"

            // Pango markup often uses <span foreground="red"> (or background,
            // weight, style, underline and strikethrough). Translate only these
            // known attributes to a controlled CSS style; never forward arbitrary
            // notification-supplied attributes or style text into RichText.
            const styles = []
            const foregroundMatch = /\bforeground\s*=\s*(["'])(.*?)\1/i.exec(attributes)
            const backgroundMatch = /\bbackground\s*=\s*(["'])(.*?)\1/i.exec(attributes)
            const weightMatch = /\bweight\s*=\s*(["'])(.*?)\1/i.exec(attributes)
            const styleMatch = /\bstyle\s*=\s*(["'])(.*?)\1/i.exec(attributes)
            const underlineMatch = /\bunderline\s*=\s*(["'])(.*?)\1/i.exec(attributes)
            const strikeMatch = /\bstrikethrough\s*=\s*(["'])(.*?)\1/i.exec(attributes)
            const familyMatch = /\bfont_family\s*=\s*(["'])(.*?)\1/i.exec(attributes)

            const foreground = foregroundMatch ? root.safeNotificationColor(foregroundMatch[2]) : ""
            const background = backgroundMatch ? root.safeNotificationColor(backgroundMatch[2]) : ""
            if (foreground) styles.push("color: " + foreground + ";")
            if (background) styles.push("background-color: " + background + ";")

            if (weightMatch) {
                const weight = String(weightMatch[2] || "").trim().toLowerCase()
                if (/^(?:normal|bold|bolder|lighter|[1-9]00)$/.test(weight))
                    styles.push("font-weight: " + weight + ";")
            }
            if (styleMatch) {
                const fontStyle = String(styleMatch[2] || "").trim().toLowerCase()
                if (/^(?:normal|italic|oblique)$/.test(fontStyle))
                    styles.push("font-style: " + fontStyle + ";")
            }
            if (familyMatch) {
                const family = String(familyMatch[2] || "").trim()
                if (/^[a-z0-9 _,-]{1,64}$/i.test(family))
                    styles.push("font-family: " + family + ";")
            }

            const decorations = []
            if (underlineMatch) {
                const underline = String(underlineMatch[2] || "").trim().toLowerCase()
                if (underline === "double") decorations.push("underline double")
                else if (/^(?:single|low|error)$/.test(underline)) decorations.push("underline")
            }
            if (strikeMatch && /^(?:true|yes|1)$/i.test(String(strikeMatch[2] || "").trim()))
                decorations.push("line-through")
            if (decorations.length > 0) styles.push("text-decoration: " + decorations.join(" ") + ";")

            return styles.length > 0
                ? '<span style="' + root.escapeNotificationAttribute(styles.join(" ")) + '">'
                : "<span>"
        }

        if (isClosing) {
            if (name === "strong") return "</b>"
            if (name === "em") return "</i>"
            if (name === "b" || name === "i" || name === "u" || name === "a")
                return "</" + name + ">"
            return ""
        }

        if (name === "br") return "<br>"
        if (name === "b" || name === "strong") return "<b>"
        if (name === "i" || name === "em") return "<i>"
        if (name === "u") return "<u>"

        // Rebuild links from a constrained set of attributes. This avoids
        // forwarding arbitrary notification-supplied HTML attributes/styles.
        const hrefMatch = /\bhref\s*=\s*(["'])(.*?)\1/i.exec(attributes)
        if (!hrefMatch) return escapeNotificationText(tag)

        const href = String(hrefMatch[2] || "")
        const safeHref = escapeNotificationAttribute(href)
        const safeStyle = escapeNotificationAttribute(linkStyle)
        return '<a href="' + safeHref + '" style="' + safeStyle + '">'
    }

    function formatNotificationBody(body) {
        // Preserve explicit line breaks as supported markup, but escape every
        // intervening text node. Only the small notification-markup subset is
        // passed through as actual rich text; literal <, > and & are displayed.
        const normalized = String(body || "").replace(/\r\n|\r|\n/g, "<br>")
        const linkStyle = "color: " + String(Config.accent) + "; text-decoration: underline;"
        const markupPattern = /<\/?(?:b|strong|i|em|u|a|br|html|tt|span)(?=\s|\/?>)[^<>]*>/gi
        let output = ""
        let lastIndex = 0
        let match

        while ((match = markupPattern.exec(normalized)) !== null) {
            output += escapeNotificationText(normalized.slice(lastIndex, match.index))
            output += root.formatNotificationTag(match[0], linkStyle)
            lastIndex = markupPattern.lastIndex
        }

        output += escapeNotificationText(normalized.slice(lastIndex))
        return output
    }

    function notificationIconSource(notification) {
        const icon = notification ? String(notification.appIcon || "").trim() : ""

        // Notifications may provide either an icon-theme name or an absolute/URL path.
        // Keep explicit paths as-is; for theme names, verify that the icon actually
        // exists before accepting it. An unknown name must not block the desktop-entry
        // fallback (Quickshell's appIcon contains the explicit name when one was sent).
        if (icon.startsWith("/") || /^(file|qrc|image|https?):/i.test(icon))
            return icon

        if (icon) {
            const resolvedExplicitIcon = Quickshell.iconPath(icon, true)
            if (String(resolvedExplicitIcon || "").length > 0)
                return resolvedExplicitIcon
        }

        // Quickshell normally resolves a desktop entry when appIcon is empty. If an
        // application supplies an invalid non-empty appIcon, resolve the associated
        // entry explicitly before falling back to the generic information icon.
        const desktopEntryId = notification ? String(notification.desktopEntry || "").trim() : ""
        if (desktopEntryId) {
            const desktopEntry = DesktopEntries.byId(desktopEntryId)
            const desktopIcon = desktopEntry && desktopEntry.icon
                ? Quickshell.iconPath(String(desktopEntry.icon), true)
                : ""
            if (String(desktopIcon || "").length > 0)
                return desktopIcon
        }

        return Quickshell.iconPath("dialog-information")
    }

    function notificationDefaultAction(notification) {
        if (!notification || !notification.actions) return null
        const actions = notification.actions
        for (let index = 0; index < actions.length; index++) {
            const action = actions[index]
            if (action && String(action.identifier || "") === "default")
                return action
        }
        return null
    }

    function notificationButtonActions(notification) {
        const visibleActions = []
        if (!notification || !notification.actions) return visibleActions

        const actions = notification.actions
        for (let index = 0; index < actions.length; index++) {
            const action = actions[index]
            // Freedesktop defines "default" as the action invoked by clicking
            // the notification itself, not as a visible action button.
            if (action && String(action.identifier || "") !== "default")
                visibleActions.push(action)
        }
        return visibleActions
    }

    function notificationBodyImageSource(notification) {
        if (!notification) return ""

        // Notification.image is normalized by Quickshell through its icon image
        // provider. That provider can return a black/magenta missing texture for
        // unknown paths, so prefer the raw image-path hint when available.
        // Local filesystem paths are validated asynchronously before being assigned
        // to Image.source, avoiding both the missing texture and Qt's Cannot open
        // warning for nonexistent files.
        const hints = notification.hints || ({})
        const rawPath = String(hints["image-path"] || hints["image_path"] || "").trim()
        if (rawPath.length > 0) {
            if (/^file:/i.test(rawPath) || /^(?:https?|qrc|image):/i.test(rawPath))
                return rawPath

            if (rawPath.startsWith("/"))
                return "file://" + rawPath

            const checkedIconSource = Quickshell.iconPath(rawPath, true)
            return String(checkedIconSource || "")
        }

        // image-data is consumed by Quickshell and exposed through Notification.image.
        return String(notification.image || "").trim()
    }

    function notificationLocalImagePath(notification) {
        if (!notification) return ""
        const hints = notification.hints || ({})
        const rawPath = String(hints["image-path"] || hints["image_path"] || "").trim()
        if (!rawPath) return ""

        if (rawPath.startsWith("/")) return rawPath

        // Accept local file URIs with an empty or localhost authority. Remote file
        // authorities are not treated as local filesystem paths.
        let match = /^file:\/\/(?:localhost)?(\/[^?#]*)$/i.exec(rawPath)
        if (!match) match = /^file:(\/[^?#]*)$/i.exec(rawPath)
        if (!match) return ""

        try {
            return decodeURIComponent(match[1])
        } catch (error) {
            return match[1]
        }
    }

    function notificationIsMessenger(notification) {
        if (!notification) return false

        // Messaging clients commonly send the sender's avatar through image-data
        // or image-path. Treat that image as a portrait beside the message instead
        // of as a wide attachment preview below the text. Keep this deliberately
        // limited to recognizable messaging clients so media notifications from
        // other applications retain their existing preview behavior.
        const identity = [notification.appName, notification.desktopEntry]
            .map(function(value) { return String(value || "").toLowerCase() })
            .join(" ")
        return /telegram|discord|signal|whatsapp|element|matrix|slack|mattermost|teams|skype|thunderbird|wechat|wire| zulip /.test(" " + identity.replace(/[^a-z0-9]+/g, " ") + " ")
    }

    function notificationHasBody(notification) {
        return notification !== null && String(notification.body || "").trim().length > 0
    }

    function notificationHasSummary(notification) {
        return notification !== null && String(notification.summary || "").trim().length > 0
    }

    function notificationProgressValue(notification) {
        // int:value is a widely used notification hint for a percentage bar.
        // Quickshell exposes the incoming hint dictionary as a JavaScript object.
        // Only show determinate values in the 0..100 range; ignore absent or
        // malformed hints so ordinary notifications keep their compact layout.
        if (notification === null || notification.hints === null || notification.hints === undefined)
            return -1

        const hints = notification.hints
        const rawValue = hints["value"]
        if (rawValue === null || rawValue === undefined || String(rawValue).trim() === "")
            return -1

        const value = Number(rawValue)
        if (!isFinite(value) || Math.floor(value) !== value || value < 0 || value > 100)
            return -1
        return value
    }

    // The freedesktop notification protocol uses -1 to ask the server to pick
    // a timeout. Use the independently configured defaults for normal and
    // critical urgency; a timeout of 0 always means no automatic expiry.
    readonly property int defaultNotificationTimeout: Math.max(0, Math.round(Number(Config.notificationsDefaultTimeout) || 0))
    readonly property int defaultCriticalNotificationTimeout: Math.max(0, Math.round(Number(Config.notificationsCriticalTimeout) || 0))

    function notificationTimeout(notification) {
        if (notification === null || notification === undefined)
            return 0

        const rawTimeout = notification.expireTimeout
        if (rawTimeout === null || rawTimeout === undefined || String(rawTimeout).trim() === "")
            return notification.urgency === NotificationUrgency.Critical
                ? root.defaultCriticalNotificationTimeout : root.defaultNotificationTimeout

        const timeout = Number(rawTimeout)
        if (!isFinite(timeout))
            return notification.urgency === NotificationUrgency.Critical
                ? root.defaultCriticalNotificationTimeout : root.defaultNotificationTimeout
        if (timeout === 0) return 0
        if (timeout > 0) return timeout

        // The spec recommends that critical notifications not auto-expire by
        // default. Their fallback timeout is independently configurable; zero
        // retains the persistent behavior.
        if (notification.urgency === NotificationUrgency.Critical)
            return root.defaultCriticalNotificationTimeout
        return root.defaultNotificationTimeout
    }

    readonly property int notificationCardWidth: Math.max(280, Math.min(600,
        Number(Settings.geometry && Settings.geometry.notifications && Settings.geometry.notifications[2])
            || Number(Config.notificationsCardWidth) || 380))
    readonly property int notificationMaxHeight: Math.max(0, Math.min(10000,
        Math.round(Number(Settings.geometry && Settings.geometry.notifications && Settings.geometry.notifications[3]) || 0)))
    readonly property int notificationImageHeight: Math.max(0, Math.min(320, Number(Config.notificationsImageHeight) || 0))
    readonly property int notificationTransitionDuration: Config.animationDurationForProfile(
        true, Config.animationNotificationsMorphProfile, Config.animationNotificationsMorphDuration, "appearance")
    // Card entrance/exit direction is independent from queue reflow. A disabled
    // shared profile always wins and makes both transitions immediate.
    readonly property string notificationCardAnimationStyle: NotificationAnimation.effectiveStyle(
        Config.animationNotificationsMorphProfile, Config.animationNotificationsVisibilityStyle)
    readonly property int notificationCardVisibilityDuration: NotificationAnimation.visibilityDuration(
        notificationCardAnimationStyle, notificationTransitionDuration)

    readonly property int notificationImageGap: 8
    readonly property int progressBarHeight: 5
    readonly property int progressBarGap: 8

    function notificationCardHeight(summaryHeight, bodyHeight, hasActions, hasBody, hasProgress, hasImage, hasAvatar) {
        // Summary/body text and the optional image preview are measured or capped
        // independently from the delegate geometry, avoiding height-binding loops.
        const measuredSummaryHeight = Math.max(0, Number(summaryHeight) || 0)
        const summaryTopOffset = 24
        const progressSpace = hasProgress ? progressBarGap + progressBarHeight : 0
        const imageSpace = hasImage ? notificationImageGap + notificationImageHeight : 0

        if (!hasBody && !hasImage) {
            // Keep a small bottom inset for a summary-only card. When action
            // buttons exist, reserve their full row below even a multi-line title.
            const summaryBottomSpace = hasActions ? 34 : 10
            const actionMinimum = hasActions ? 76 : 52
            return Math.max(hasAvatar ? 64 : actionMinimum, Math.ceil(summaryTopOffset + measuredSummaryHeight + summaryBottomSpace + progressSpace))
        }

        const measuredBodyHeight = Math.max(0, Number(bodyHeight) || 0)
        // An empty summary contributes no row or extra gap: start the body
        // directly below the app/source label instead of reserving phantom space.
        const bodyTopOffset = summaryTopOffset + measuredSummaryHeight + (measuredSummaryHeight > 0 ? 3 : 0)
        const contentBottomOffset = hasBody
            ? bodyTopOffset + measuredBodyHeight
            : (measuredSummaryHeight > 0 ? summaryTopOffset + measuredSummaryHeight : 21)
        const bottomSpace = hasActions ? 42 : 14
        // Reserve image height only when an image hint is present and successfully
        // loadable. Long bodies still grow according to their independent Text measure.
        const minimumCardHeight = hasAvatar ? 64 : (measuredSummaryHeight > 0 ? 68 : 52)
        return Math.max(minimumCardHeight, Math.ceil(contentBottomOffset + imageSpace + bottomSpace + progressSpace))
    }

    // Quickshell owns org.freedesktop.Notifications; stop Dunst before enabling
    // this component to avoid a D-Bus name ownership conflict.
    NotificationServer {
        id: notificationServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: function(notification) {
            // Keep notifications in the server's tracked model until the user
            // dismisses them or their own timeout expires.
            notification.tracked = true
        }
    }

    PanelWindow {
        id: popupWindow
        screen: root.notificationTargetScreen()
        // Do not map/unmap this layer surface for individual notifications.
        // KWin applies its window-level fade on map/unmap, which is visible even
        // when a card uses "none" or a pure directional slide animation.
        // Keep a tiny transparent surface mapped while the queue is idle.
        visible: true
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        // X remains absolute from the selected monitor's left edge. Y is an
        // inset from the configured top or bottom edge, so content can grow
        // upward when the notification stack is bottom-anchored.
        anchors.top: String(Config.notificationsVerticalAnchor || "top") !== "bottom"
        anchors.bottom: String(Config.notificationsVerticalAnchor || "top") === "bottom"
        anchors.left: true
        margins.top: String(Config.notificationsVerticalAnchor || "top") !== "bottom" ? root.notificationCoordinate(1) : 0
        margins.bottom: String(Config.notificationsVerticalAnchor || "top") === "bottom" ? root.notificationCoordinate(1) : 0
        margins.left: root.notificationCoordinate(0)
        onHeightChanged: Settings.notificationsWindowHeight = root.notificationSurfaceActive ? height : 0
        Component.onCompleted: Settings.notificationsWindowHeight = root.notificationSurfaceActive ? height : 0
        implicitWidth: root.notificationSurfaceActive ? root.notificationCardWidth : 1
        implicitHeight: {
            // Keep the mapped idle layer surface at 1x1. This avoids triggering
            // compositor open/close effects when the first/last toast arrives.
            if (!root.notificationSurfaceActive)
                return 1
            // Keep an editable preview available even when the notification queue is empty.
            if (root.layoutEditMode && notificationServer.trackedNotifications.values.length === 0)
                return root.layoutPreviewHeight
            // Zero preserves the natural content-driven height. A positive value
            // limits the notification queue and lets ListView scroll the overflow.
            const measuredContentHeight = Math.max(0, Number(notificationList.contentHeight) || 0)
            const contentHeight = root.activeNotificationExitCount > 0
                ? Math.max(measuredContentHeight, root.notificationListLastContentHeight)
                : measuredContentHeight
            const availableHeight = screen
                ? Math.max(52, screen.height - root.notificationCoordinate(1) - 16)
                : contentHeight
            const screenLimit = screen ? Math.max(180, availableHeight) : contentHeight
            const configuredLimit = root.notificationMaxHeight > 0
                ? Math.min(availableHeight, root.notificationMaxHeight) : screenLimit
            return Math.min(contentHeight, configuredLimit)
        }
        WlrLayershell.layer: WlrLayer.Overlay

        // Apply the shared per-module blur only behind the notification queue.
        // The transparent PanelWindow surface lets the compositor blur the area
        // behind the cards without changing their own text or imagery.
        BackgroundEffect.blurRegion: Region {
            item: Settings.moduleBlurEnabled.notifications === true
                ? (notificationServer.trackedNotifications.values.length > 0 || root.activeNotificationExitCount > 0 ? notificationList : layoutEditPreview)
                : null
            radius: Math.max(0, Config.backgroundBlurRadius)
        }

        Item {
            id: notificationContent
            anchors.fill: parent
            visible: root.notificationSurfaceActive
            opacity: root.layoutDragging ? 0 : 1

            ListView {
                id: notificationList
                anchors.fill: parent
                visible: notificationServer.trackedNotifications.values.length > 0 || root.activeNotificationExitCount > 0
                onContentHeightChanged: {
                    const currentHeight = Math.max(0, Number(contentHeight) || 0)
                    if (currentHeight > 0) {
                        root.notificationListLastContentHeight = root.activeNotificationExitCount > 0
                            ? Math.max(root.notificationListLastContentHeight, currentHeight)
                            : currentHeight
                    }
                }
                spacing: Config.notificationsCardSpacing
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                model: notificationServer.trackedNotifications

                // The card owns its entrance animation. ListView's add/populate
                // transitions only animate view-managed x/y and were not reliably
                // applied to every ObjectModel insertion/reload path. The delegate
                // now initializes its own opacity/translation on completion and on
                // the attached add signal, guarded against double starts.
                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: root.notificationTransitionDuration
                        easing.type: Config.animationEasingType(Config.animationNotificationsMorphProfile, "enter")
                    }
                }

                // Make overflow discoverable and easy to browse with either a mouse
                // wheel or a touchpad. The scrollbar is shown only when the queue is
                // taller than the usable screen area.
                ScrollBar.vertical: ScrollBar {
                    policy: notificationList.contentHeight > notificationList.height
                        ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    width: 6
                    background: Rectangle {
                        color: Config.baseColor
                        radius: width / 2
                        opacity: 0.45
                    }
                    contentItem: Rectangle {
                        radius: width / 2
                        color: Config.accent
                        opacity: 0.95
                    }
                }

                WheelHandler {
                    target: null
                    enabled: notificationList.contentHeight > notificationList.height
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        const maxContentY = Math.max(0, notificationList.contentHeight - notificationList.height)
                        const pixelDelta = Number(event.pixelDelta.y) || 0
                        const angleDelta = Number(event.angleDelta.y) || 0
                        const delta = pixelDelta !== 0 ? pixelDelta : angleDelta / 120 * 64
                        if (delta === 0) return

                        notificationList.contentY = Math.max(0, Math.min(
                            maxContentY,
                            notificationList.contentY - delta
                        ))
                        event.accepted = true
                    }
                }
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    property var notification: modelData || null
                    // Notification is Quickshell.Retainable. The server emits
                    // Notification.closed before removing it from trackedNotifications,
                    // then destroys it after signal handlers return. Keep it alive
                    // for the full lifetime of this delegate so ListView can process
                    // removal and finish a delayed exit transition safely.
                    RetainableLock {
                        object: card.notification
                        locked: card.notification !== null
                    }
                    // A single normalized transition drives opacity and translation.
                    // Style/profile/duration are snapshotted per transition so editing
                    // settings cannot mutate a card while it is already animating.
                    property string activeTransitionStyle: "none"
                    property string activeTransitionProfile: "expressive"
                    property string activeTransitionPhase: "enter"
                    property int activeTransitionDuration: 0
                    property real transitionProgress: 1
                    readonly property real animatedOpacity: NotificationAnimation.opacityForProgress(
                        activeTransitionStyle, activeTransitionPhase, transitionProgress)
                    readonly property real motionOffsetX: NotificationAnimation.motionOffsetXForProgress(
                        activeTransitionStyle, width, activeTransitionPhase, transitionProgress)
                    readonly property real motionOffsetY: NotificationAnimation.motionOffsetYForProgress(
                        activeTransitionStyle, height, activeTransitionPhase, transitionProgress)
                    property bool entryAnimationStarted: false
                    property bool exitKeepsWindowAlive: false
                    property var defaultAction: root.notificationDefaultAction(notification)
                    property var buttonActions: root.notificationButtonActions(notification)
                    property string formattedBody: notification ? root.formatNotificationBody(notification.body) : ""
                    // Keep imageSource empty until a local path is confirmed readable.
                    // Assigning a missing file directly would make QQuickImage emit a
                    // Cannot open warning before its Image.Error handler can hide it.
                    property string imageSource: ""
                    property string pendingImageSource: ""
                    property string pendingImagePath: ""
                    property int imageValidationRevision: 0
                    property int activeImageValidationRevision: 0
                    property bool imageSourceInitialized: false
                    // Preserve reactivity when Notify replaces a notification in place:
                    // the notification object can stay the same while its hint map/image
                    // payload changes, so source resolution must follow this snapshot.
                    property string imageHintsSnapshot: {
                        if (!notification) return ""
                        const hints = notification.hints || ({})
                        return String(hints["image-path"] || hints["image_path"] || "")
                            + "\u001f" + String(notification.image || "")
                    }
                    property bool imageLoadFailed: false
                    readonly property bool hasMessengerAvatar: root.notificationIsMessenger(notification) && imageSource.length > 0 && !imageLoadFailed
                    readonly property bool hasNotificationImage: Config.notificationsShowBodyImages && root.notificationImageHeight > 0 && imageSource.length > 0 && !imageLoadFailed && !hasMessengerAvatar

                    function startNotificationEntry() {
                        if (entryAnimationStarted || removalPending || notification === null)
                            return

                        entryAnimationStarted = true
                        activeTransitionStyle = root.notificationCardAnimationStyle
                        activeTransitionProfile = String(Config.animationNotificationsMorphProfile || "standard")
                        activeTransitionDuration = root.notificationCardVisibilityDuration
                        activeTransitionPhase = "enter"
                        // Starting from zero lets a single progress animation drive
                        // slide position and fade opacity without independent fallbacks.
                        transitionProgress = 0

                        if (!NotificationAnimation.shouldAnimate(activeTransitionStyle, activeTransitionDuration)) {
                            transitionProgress = 1
                            return
                        }
                        entryAnimation.start()
                    }

                    function startNotificationExit(trigger) {
                        if (removalPending) {
                            return
                        }
                        removalPending = true
                        expirationTimer.stop()
                        entryAnimation.stop()
                        exitAnimation.stop()

                        activeTransitionStyle = root.notificationCardAnimationStyle
                        activeTransitionProfile = String(Config.animationNotificationsMorphProfile || "standard")
                        activeTransitionDuration = root.notificationCardVisibilityDuration
                        activeTransitionPhase = "exit"
                        transitionProgress = 0
                        if (!NotificationAnimation.shouldAnimate(activeTransitionStyle, activeTransitionDuration)) {
                            transitionProgress = 1
                            return
                        }

                        // Defer destruction until the explicit exit animation finishes.
                        // The parent window remains visible through activeExitCount.
                        ListView.delayRemove = true
                        exitKeepsWindowAlive = true
                        root.activeNotificationExitCount += 1
                        exitAnimation.start()
                    }

                    function finishNotificationExit() {
                        if (exitKeepsWindowAlive) {
                            exitKeepsWindowAlive = false
                            root.finishNotificationCardExit()
                        }
                        ListView.delayRemove = false
                    }

                    function resolveNotificationImageSource() {
                        imageSourceInitialized = true
                        imageValidationRevision += 1
                        if (imagePathValidationProcess.running)
                            imagePathValidationProcess.running = false

                        pendingImageSource = ""
                        pendingImagePath = ""
                        imageSource = ""
                        imageLoadFailed = false

                        if (!notification) return
                        const candidateSource = root.notificationBodyImageSource(notification)
                        if (!candidateSource) return

                        const localPath = root.notificationLocalImagePath(notification)
                        if (!localPath) {
                            imageSource = candidateSource
                            return
                        }

                        pendingImageSource = candidateSource
                        pendingImagePath = localPath
                        activeImageValidationRevision = imageValidationRevision
                        imagePathValidationProcess.running = true
                    }

                    Process {
                        id: imagePathValidationProcess
                        running: false
                        // Pass the path as an argv item, not interpolated shell text.
                        // Only assign it to Image.source after this check succeeds.
                        command: ["bash", "-c", "test -f \"$1\" && test -r \"$1\"", "notification-image-path-check", card.pendingImagePath]
                        onExited: function(exitCode) {
                            if (card.activeImageValidationRevision !== card.imageValidationRevision)
                                return

                            const candidateSource = card.pendingImageSource
                            card.pendingImageSource = ""
                            card.pendingImagePath = ""
                            if (exitCode === 0 && candidateSource.length > 0) {
                                card.imageSource = candidateSource
                            } else {
                                card.imageSource = ""
                                card.imageLoadFailed = true
                            }
                        }
                    }
                    property int progressValue: root.notificationProgressValue(notification)
                    visible: notification !== null
                    opacity: animatedOpacity
                    // Start a timeout only while the notification is actually in the
                    // visible viewport. Off-screen queue entries must not expire unseen.
                    property bool inViewport: {
                        if (notification === null || notificationList.height <= 0 || card.height <= 0)
                            return false

                        // Read both properties explicitly so this binding is reevaluated when
                        // the list scrolls or relays out its delegates. mapToItem() returns
                        // the card's actual position in viewport coordinates, avoiding the
                        // parent/contentItem coordinate ambiguity of comparing card.y to
                        // contentY manually.
                        const scrollPosition = notificationList.contentY
                        const delegatePosition = card.y
                        const viewportPosition = card.mapToItem(notificationList, 0, 0)
                        return viewportPosition.y + card.height > 0 && viewportPosition.y < notificationList.height
                    }
                    property real visibleTimeoutElapsed: 0
                    property bool removalPending: false
                    property bool timeoutExpirationRequested: false
                    property real effectiveTimeout: root.notificationTimeout(notification)
                    property real measuredSummaryHeight: root.notificationHasSummary(notification) ? summaryMeasure.implicitHeight : 0
                    readonly property int textColumnWidth: Math.max(0, root.notificationCardWidth - (hasMessengerAvatar ? 84 : 24))
                    onNotificationChanged: {
                        visibleTimeoutElapsed = 0
                        removalPending = false
                        timeoutExpirationRequested = false
                    }
                    ListView.onAdd: card.startNotificationEntry()
                    // Quickshell emits Notification.closed(reason) before removing
                    // the object from NotificationServer.trackedNotifications.
                    // Start the exit while this delegate is still in the model so
                    // delayRemove is already true when ListView processes removal.
                    Connections {
                        target: card.notification
                        ignoreUnknownSignals: true
                        function onClosed(reason) {
                            card.startNotificationExit("notification-closed")
                        }
                    }
                    ListView.onRemove: card.startNotificationExit("listview-remove")
                    onImageHintsSnapshotChanged: resolveNotificationImageSource()
                    Component.onCompleted: {
                        // Existing tracked notifications can be created by the
                        // ListView populate path instead of its add signal.
                        card.startNotificationEntry()
                        // Initial bound values can be set either side of completion;
                        // avoid restarting an existing check if the snapshot handler
                        // already began resolving this notification.
                        if (!imageSourceInitialized)
                            resolveNotificationImageSource()
                    }
                    onImageSourceChanged: imageLoadFailed = false
                    width: notificationList.width
                    // Measure body text in a separate, unconstrained Text item. Measuring
                    // bodyText itself while the card height is derived from that measurement
                    // can form a QML height-binding cycle with RichText layout.
                    height: notification !== null ? root.notificationCardHeight(card.measuredSummaryHeight, bodyMeasure.implicitHeight, card.buttonActions.length > 0, root.notificationHasBody(notification), Config.notificationsShowProgress && card.progressValue >= 0, card.hasNotificationImage, card.hasMessengerAvatar) : 0
                    radius: Config.frameRadius
                    color: Settings.moduleBackgrounds.notifications !== false ? Config.background : Config.transparent
                    border.width: Settings.moduleFrames.notifications !== false ? Math.max(1, Config.frameBorderWidth) : 0
                    border.color: card.notification && card.notification.urgency === NotificationUrgency.Critical ? "#e05b64" : Config.baseColor
                    transform: Translate {
                        x: card.motionOffsetX
                        y: card.motionOffsetY
                    }
                    NumberAnimation {
                        id: entryAnimation
                        target: card
                        property: "transitionProgress"
                        to: 1
                        duration: card.activeTransitionDuration
                        easing.type: Config.animationEasingType(card.activeTransitionProfile, "enter")
                        easing.bezierCurve: Config.animationBezierCurve(card.activeTransitionProfile, "enter")
                    }
                    NumberAnimation {
                        id: exitAnimation
                        target: card
                        property: "transitionProgress"
                        to: 1
                        duration: card.activeTransitionDuration
                        easing.type: Config.animationEasingType(card.activeTransitionProfile, "exit")
                        easing.bezierCurve: Config.animationBezierCurve(card.activeTransitionProfile, "exit")
                        onFinished: card.finishNotificationExit()
                    }

                    // The freedesktop "default" action is activated by clicking the
                    // notification body. Keep this MouseArea behind the content so
                    // links, the close control, and explicit action buttons retain
                    // their own click behavior.
                    MouseArea {
                        id: cardBodyMouseArea
                        anchors.fill: parent
                        enabled: card.defaultAction !== null && !card.removalPending
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            if (card.defaultAction && typeof card.defaultAction.invoke === "function")
                                card.defaultAction.invoke()
                        }
                    }

                    Timer {
                        id: expirationTimer
                        // Count only time spent inside the visible viewport. Stopping this
                        // repeating timer pauses the accumulated visible time instead of
                        // restarting a full timeout or allowing off-screen cards to expire.
                        interval: 100
                        running: card.notification !== null && !card.removalPending && !card.timeoutExpirationRequested && card.inViewport && card.effectiveTimeout > 0
                        repeat: true
                        onTriggered: {
                            if (!card.notification) return
                            const timeout = card.effectiveTimeout
                            if (timeout <= 0) return
                            card.visibleTimeoutElapsed += interval
                            if (card.visibleTimeoutElapsed >= timeout && !card.timeoutExpirationRequested) {
                                card.timeoutExpirationRequested = true
                                card.notification.expire()
                            }
                        }
                    }

                    Image {
                        id: appIconImage
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        width: 22
                        height: 22
                        source: card.notification ? root.notificationIconSource(card.notification) : ""
                        visible: Config.notificationsShowAppIcon && String(source).length > 0 && !card.hasMessengerAvatar
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(44, 44)
                        smooth: true
                        // Avoid Qt's background pixmap reader for theme SVG icons. Some
                        // SVG handlers create GUI-owned QObjects during async decoding,
                        // causing cross-thread QObject/event-filter warnings.
                        asynchronous: false
                    }

                    Rectangle {
                        id: messengerAvatarFrame
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        width: 48
                        height: 48
                        radius: 10
                        color: Config.baseColor
                        clip: true
                        visible: card.hasMessengerAvatar

                        Image {
                            anchors.fill: parent
                            source: card.imageSource
                            sourceSize: Qt.size(96, 96)
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: false
                        }
                    }

                    Text {
                        id: appLabel
                        anchors.left: parent.left
                        anchors.leftMargin: card.hasMessengerAvatar ? 72 : (appIconImage.visible ? 38 : 12)
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.right: closeButton.left
                        text: card.notification ? String(card.notification.appName || "Уведомление") : ""
                        color: Config.text
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Text {
                        id: closeButton
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        width: 24
                        height: 24
                        text: "×"
                        color: Config.text
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            enabled: !card.removalPending
                            onClicked: {
                                if (card.notification && !card.removalPending) card.notification.dismiss()
                            }
                        }
                    }

                    Text {
                        id: summaryMeasure
                        visible: false
                        // Use the same width, font and plain-text semantics as the
                        // displayed summary, independently of card/delegate geometry.
                        width: card.textColumnWidth
                        text: card.notification ? String(card.notification.summary || "") : ""
                        font.pixelSize: 14
                        font.bold: true
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                    }

                    Text {
                        id: summaryText
                        anchors.left: parent.left
                        anchors.leftMargin: card.hasMessengerAvatar ? 72 : 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: appLabel.bottom
                        anchors.topMargin: 3
                        text: card.notification ? String(card.notification.summary || "") : ""
                        visible: root.notificationHasSummary(card.notification)
                        color: Config.text
                        font.pixelSize: 14
                        font.bold: true
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                    }

                    Text {
                        id: bodyMeasure
                        visible: false
                        // Match the card's text column without referencing delegate
                        // geometry, so implicitHeight cannot form a card-height loop.
                        width: card.textColumnWidth
                        text: card.formattedBody
                        color: Config.text
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        textFormat: Text.RichText
                    }

                    Text {
                        id: bodyText
                        anchors.left: parent.left
                        anchors.leftMargin: card.hasMessengerAvatar ? 72 : 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: root.notificationHasSummary(card.notification) ? summaryText.bottom : appLabel.bottom
                        anchors.topMargin: 3
                        text: card.formattedBody
                        visible: root.notificationHasBody(card.notification)
                        color: Config.text
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        // Its implicit height is measured from the wrapped rich text;
                        // the card grows to fit instead of constraining and clipping it.
                        textFormat: Text.RichText
                        onLinkActivated: function(link) {
                            const url = String(link || "")
                            if (/^(https?:|mailto:)/i.test(url))
                                Qt.openUrlExternally(url)
                        }
                    }

                    Image {
                        id: bodyImage
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: root.notificationHasBody(card.notification)
                            ? bodyText.bottom
                            : (root.notificationHasSummary(card.notification) ? summaryText.bottom : appLabel.bottom)
                        anchors.topMargin: root.notificationHasBody(card.notification) || root.notificationHasSummary(card.notification)
                            ? root.notificationImageGap : 8
                        height: root.notificationImageHeight
                        source: card.imageSource
                        sourceSize: Qt.size(root.notificationCardWidth - 24, root.notificationImageHeight)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: false
                        visible: card.hasNotificationImage && status === Image.Ready
                        onStatusChanged: {
                            if (status === Image.Error)
                                card.imageLoadFailed = true
                        }
                    }

                    Rectangle {
                        id: progressTrack
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: card.hasNotificationImage
                            ? bodyImage.bottom
                            : (root.notificationHasBody(card.notification)
                                ? bodyText.bottom
                                : (root.notificationHasSummary(card.notification) ? summaryText.bottom : appLabel.bottom))
                        anchors.topMargin: root.progressBarGap
                        height: root.progressBarHeight
                        radius: height / 2
                        color: Config.baseColor
                        visible: Config.notificationsShowProgress && card.progressValue >= 0
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * card.progressValue / 100
                            radius: parent.radius
                            color: Config.accent
                        }
                    }

                    Row {
                        id: actionRow
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        height: 24
                        spacing: 6
                        visible: card.buttonActions.length > 0

                        Repeater {
                            model: card.buttonActions
                            delegate: Rectangle {
                                required property var modelData
                                width: Math.min(150, actionText.implicitWidth + 18)
                                height: 24
                                radius: 4
                                color: actionMouse.containsMouse ? Config.accent : "transparent"
                                border.width: 1
                                border.color: Config.baseColor
                                Text {
                                    id: actionText
                                    anchors.centerIn: parent
                                    text: modelData ? String(modelData.text || "") : ""
                                    color: Config.text
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !card.removalPending
                                    onClicked: {
                                        if (!card.removalPending && modelData && typeof modelData.invoke === "function") modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: layoutEditPreview
                anchors.fill: parent
                visible: root.layoutEditMode && notificationServer.trackedNotifications.values.length === 0
                radius: Config.frameRadius
                color: Settings.moduleBackgrounds.notifications !== false ? Config.background : Config.transparent
                border.width: Settings.moduleFrames.notifications !== false ? Math.max(1, Config.frameBorderWidth) : 0
                border.color: Config.baseColor

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    spacing: 5

                    Text {
                        width: parent.width
                        text: "Предварительный просмотр уведомления"
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(12)
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: "Здесь будут отображаться входящие уведомления"
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        Item {
            id: layoutEditOverlay
            anchors.fill: parent
            visible: root.layoutEditMode
            z: 10000

            Rectangle {
                anchors.fill: parent
                visible: !root.layoutDragging
                color: "transparent"
                border.color: Config.accent
                border.width: Math.max(2, Config.frameBorderWidth + 1)
                radius: Config.frameRadius
                antialiasing: true
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 5
                visible: !root.layoutDragging
                width: layoutEditLabel.implicitWidth + 14
                height: layoutEditLabel.implicitHeight + 8
                radius: 4
                color: Config.accent
                border.color: Config.accent
                border.width: 1

                Text {
                    id: layoutEditLabel
                    anchors.centerIn: parent
                    text: "notifications"
                    color: Config.black
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    font.bold: true
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                preventStealing: true
                hoverEnabled: true
                cursorShape: Qt.OpenHandCursor

                onPressed: function(mouse) {
                    if (!root.layoutEditMode || root.layoutDragging || !root.layoutEditor)
                        return

                    root.dragPressX = Number(mouse.x)
                    root.dragPressY = Number(mouse.y)
                    root.dragBaseGlobalX = Number(popupWindow.screen && popupWindow.screen.x || 0) + root.notificationCoordinate(0)
                    root.dragBaseGlobalY = Number(popupWindow.screen && popupWindow.screen.y || 0)
                        + root.notificationTopCoordinate(popupWindow.screen, popupWindow.height)
                    root.layoutDragging = true
                    Settings.beginGeometryDrag("notifications")
                    root.layoutEditor.beginProxyDrag(
                        "notifications",
                        root.dragBaseGlobalX,
                        root.dragBaseGlobalY,
                        popupWindow.width,
                        popupWindow.height
                    )

                    notificationContent.grabToImage(function(result) {
                        if (!root.layoutDragging) return
                        notificationContent.opacity = 0
                        if (root.layoutEditor) root.layoutEditor.setProxySource(result.url)
                    }, Qt.size(Math.max(1, Math.round(popupWindow.width)), Math.max(1, Math.round(popupWindow.height))))
                }

                onPositionChanged: function(mouse) {
                    if (!pressed || !root.layoutDragging || !root.layoutEditor)
                        return
                    var globalX = root.dragBaseGlobalX + Number(mouse.x) - root.dragPressX
                    var globalY = root.dragBaseGlobalY + Number(mouse.y) - root.dragPressY
                    root.layoutEditor.updateProxyDrag(globalX, globalY, popupWindow.width, popupWindow.height)
                }

                onReleased: function(mouse) { root.finishLayoutDrag(mouse.x, mouse.y) }
                onCanceled: root.cancelLayoutDrag()
            }
        }
    }
}
