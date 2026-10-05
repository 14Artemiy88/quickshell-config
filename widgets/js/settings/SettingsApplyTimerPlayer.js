.pragma library

function apply(Config, o, legacyTimerIconOrder) {
        // Timer tuning
        var timerNumberFields = [
            ["timerWheelStep", 1, 60], ["timerCommentWidth", 40, 300],
            ["timerCommentMaxLength", 1, 30], ["timerCommentGap", 0, 40], ["timerRowSpacing", 0, 50],
            ["timerIconSize", 8, 64], ["timerIconX", -100, 100], ["timerIconY", -100, 100],
            ["timerAlarmIconSize", 8, 64], ["timerAlarmIconX", -100, 100], ["timerAlarmIconY", -100, 100],
            ["timerRowTopMargin", 0, 50], ["timerRowRightMargin", 0, 50],
            ["timerButtonFadeDuration", 0, 5000], ["timerButtonSlideDuration", 0, 5000],
            ["timerButtonIconFadeDuration", 0, 5000]
        ]
        for (var tf = 0; tf < timerNumberFields.length; ++tf) {
            var tname = timerNumberFields[tf][0]
            if (o[tname] !== undefined) {
                var tv = Number(o[tname])
                if (isFinite(tv)) Config[tname] = Math.max(timerNumberFields[tf][1], Math.min(timerNumberFields[tf][2], Math.round(tv)))
            }
        }
        if (legacyTimerIconOrder && o.timerIconX !== undefined && o.timerAlarmIconX !== undefined) {
            var legacyTimerX = Number(o.timerIconX)
            var legacyAlarmX = Number(o.timerAlarmIconX)
            if (isFinite(legacyTimerX) && isFinite(legacyAlarmX)) {
                Config.timerIconX = legacyAlarmX
                Config.timerAlarmIconX = legacyTimerX
            }
        }

        // Player tuning
        var playerNumberFields = [
            ["playerSilenceFontSize", 8, 100], ["playerSilenceLongFontSize", 8, 100],
            ["playerMetaFontSize", 8, 48], ["playerMetaSecondaryFontSize", 8, 48],
            ["playerMetaLineSpacing", 0, 100], ["playerControlIconSize", 8, 64],
            ["playerPlayingIconSize", 8, 64], ["playerPausedIconSize", 8, 64], ["playerNextIconSize", 8, 64],
            ["playerPlayingIconY", -100, 100], ["playerPausedIconY", -100, 100], ["playerNextIconY", -100, 100],
            ["playerMetadataXPadding", 0, 100], ["playerMetadataY", 0, 100], ["playerProgressY", 0, 100],
            ["playerProgressTrackHeight", 1, 20], ["playerControlTopMargin", 0, 100],
            ["playerControlGap", 0, 100], ["playerTimeFontSize", 8, 48],
            ["playerTimeRightPadding", 0, 100], ["playerSilenceWidth", 100, 600],
            ["playerProgressTrackOffsetY", -10, 20]
        ]
        for (var pf = 0; pf < playerNumberFields.length; ++pf) {
            var pname = playerNumberFields[pf][0]
            if (o[pname] !== undefined) {
                var pv = Number(o[pname])
                if (isFinite(pv)) Config[pname] = Math.max(playerNumberFields[pf][1], Math.min(playerNumberFields[pf][2], Math.round(pv)))
            }
        }
        if (o.playerBoldArtist !== undefined) Config.playerBoldArtist = !!o.playerBoldArtist
        if (o.playerShowProgress !== undefined) Config.playerShowProgress = !!o.playerShowProgress
        if (o.playerBlurEnabled !== undefined) Config.playerBlurEnabled = !!o.playerBlurEnabled
        if (o.playerBlurRadius !== undefined) {
            var pbr = Number(o.playerBlurRadius)
            if (isFinite(pbr)) Config.playerBlurRadius = Math.max(0, Math.min(40, Math.round(pbr)))
        }
        if (o.playerCoverOpacity !== undefined) {
            var pco = Number(o.playerCoverOpacity)
            if (isFinite(pco)) Config.playerCoverOpacity = Math.max(0, Math.min(1, pco))
        }

        // Player backend priority. Keep the list ordered, unique, and
        // limited to known backend IDs. Missing entries are appended so
        // older settings files migrate cleanly.
        var defaultPlayerPriority = [
            "deadbeef",
            "mopidy",
            "mpv",
            "spotify",
            "plasma-browser-integration",
            "org.telegram.desktop"
        ]
        if (o.playerPriority instanceof Array) {
            var normalizedPriority = []
            for (var pi = 0; pi < o.playerPriority.length; ++pi) {
                var item = o.playerPriority[pi]
                var backendId = ""
                var enabled = true
                if (typeof item === "string") {
                    backendId = item
                } else if (item && typeof item === "object") {
                    backendId = String(item.id || "")
                    enabled = item.enabled !== false
                }
                if (!backendId || defaultPlayerPriority.indexOf(backendId) < 0)
                    continue
                var duplicate = false
                for (var pj = 0; pj < normalizedPriority.length; ++pj) {
                    if (normalizedPriority[pj].id === backendId) { duplicate = true; break }
                }
                if (!duplicate)
                    normalizedPriority.push({ id: backendId, enabled: enabled })
            }
            for (var pk = 0; pk < defaultPlayerPriority.length; ++pk) {
                var missing = true
                for (var pl = 0; pl < normalizedPriority.length; ++pl) {
                    if (normalizedPriority[pl].id === defaultPlayerPriority[pk]) { missing = false; break }
                }
                if (missing)
                    normalizedPriority.push({ id: defaultPlayerPriority[pk], enabled: true })
            }
            Config.playerPriority = normalizedPriority
        }

}
