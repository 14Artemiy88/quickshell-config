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

        // Mopidy module queue presentation
        if (o.mopidyShowTrackNumbers !== undefined) Config.mopidyShowTrackNumbers = !!o.mopidyShowTrackNumbers
        if (o.mopidyMoveUpIcon !== undefined) Config.mopidyMoveUpIcon = String(o.mopidyMoveUpIcon)
        if (o.mopidyMoveUpIconSize !== undefined) Config.mopidyMoveUpIconSize = Math.max(6, Math.min(64, Number(o.mopidyMoveUpIconSize) || Config.mopidyMoveUpIconSize))
        if (o.mopidyMoveUpIconX !== undefined) Config.mopidyMoveUpIconX = Math.max(-20, Math.min(20, Number(o.mopidyMoveUpIconX) || 0))
        if (o.mopidyMoveUpIconY !== undefined) Config.mopidyMoveUpIconY = Math.max(-20, Math.min(20, Number(o.mopidyMoveUpIconY) || 0))
        if (o.mopidyShowMoveUpIcon !== undefined) Config.mopidyShowMoveUpIcon = !!o.mopidyShowMoveUpIcon
        if (o.mopidyMoveDownIcon !== undefined) Config.mopidyMoveDownIcon = String(o.mopidyMoveDownIcon)
        if (o.mopidyMoveDownIconSize !== undefined) Config.mopidyMoveDownIconSize = Math.max(6, Math.min(64, Number(o.mopidyMoveDownIconSize) || Config.mopidyMoveDownIconSize))
        if (o.mopidyMoveDownIconX !== undefined) Config.mopidyMoveDownIconX = Math.max(-20, Math.min(20, Number(o.mopidyMoveDownIconX) || 0))
        if (o.mopidyMoveDownIconY !== undefined) Config.mopidyMoveDownIconY = Math.max(-20, Math.min(20, Number(o.mopidyMoveDownIconY) || 0))
        if (o.mopidyShowMoveDownIcon !== undefined) Config.mopidyShowMoveDownIcon = !!o.mopidyShowMoveDownIcon
        // Backward compatibility with the old shared checkbox.
        if (o.mopidyShowMoveUpIcon === undefined && o.mopidyShowMoveDownIcon === undefined && o.mopidyShowMoveButtons !== undefined) {
            Config.mopidyShowMoveUpIcon = !!o.mopidyShowMoveButtons
            Config.mopidyShowMoveDownIcon = !!o.mopidyShowMoveButtons
        }
        Config.mopidyShowMoveButtons = Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon
        if (o.mopidyGroupAlbums !== undefined) Config.mopidyGroupAlbums = !!o.mopidyGroupAlbums
        if (o.mopidyAlbumFont !== undefined) Config.mopidyAlbumFont = String(o.mopidyAlbumFont)
        if (o.mopidyAlbumFontSize !== undefined) Config.mopidyAlbumFontSize = Math.max(6, Math.min(40, Number(o.mopidyAlbumFontSize) || Config.mopidyAlbumFontSize))
        if (o.mopidyTrackFont !== undefined) Config.mopidyTrackFont = String(o.mopidyTrackFont)
        if (o.mopidyTrackFontSize !== undefined) Config.mopidyTrackFontSize = Math.max(6, Math.min(40, Number(o.mopidyTrackFontSize) || Config.mopidyTrackFontSize))
        if (o.mopidyArtistFont !== undefined) Config.mopidyArtistFont = String(o.mopidyArtistFont)
        if (o.mopidyArtistFontSize !== undefined) Config.mopidyArtistFontSize = Math.max(6, Math.min(40, Number(o.mopidyArtistFontSize) || Config.mopidyArtistFontSize))
        if (o.mopidyDurationFont !== undefined) Config.mopidyDurationFont = String(o.mopidyDurationFont)
        if (o.mopidyDurationFontSize !== undefined) Config.mopidyDurationFontSize = Math.max(6, Math.min(40, Number(o.mopidyDurationFontSize) || Config.mopidyDurationFontSize))
        if (o.mopidyAlbumSeparator !== undefined) {
            var separator = String(o.mopidyAlbumSeparator)
            var legacySeparatorMap = {
                "line": "between-line",
                "dashes": "between-line",
                "dots": "between-line",
                "between-dashes": "between-line",
                "under-dashes": "under-line",
                "between-dots": "between-line",
                "under-dots": "under-line"
            }
            if (legacySeparatorMap[separator] !== undefined)
                separator = legacySeparatorMap[separator]
            if (["none", "between-line", "under-line", "frame"].indexOf(separator) >= 0)
                Config.mopidyAlbumSeparator = separator
        }
        if (o.mopidyAlbumBold !== undefined) Config.mopidyAlbumBold = !!o.mopidyAlbumBold
        if (o.mopidyBackground !== undefined) {
            var mopidyBackground = String(o.mopidyBackground)
            if (/^#[0-9a-fA-F]{6,8}$/.test(mopidyBackground) || mopidyBackground === "transparent")
                Config.mopidyBackground = mopidyBackground
        }
        if (o.mopidyToggleWithPlayerRightClick !== undefined) Config.mopidyToggleWithPlayerRightClick = !!o.mopidyToggleWithPlayerRightClick
        if (o.mopidyHoverMode !== undefined) {
            var mopidyHoverMode = String(o.mopidyHoverMode)
            if (mopidyHoverMode === "highlight") mopidyHoverMode = "background"
            if (mopidyHoverMode === "text" || mopidyHoverMode === "background" || mopidyHoverMode === "frame")
                Config.mopidyHoverMode = mopidyHoverMode
        }
        if (o.mopidyHoverColor !== undefined) {
            var mopidyHoverColor = String(o.mopidyHoverColor)
            if (/^#[0-9a-fA-F]{6,8}$/.test(mopidyHoverColor) || mopidyHoverColor === "transparent") Config.mopidyHoverColor = mopidyHoverColor
        }
        if (o.mopidyStopIcon !== undefined) Config.mopidyStopIcon = String(o.mopidyStopIcon)
        if (o.mopidyStopIconSize !== undefined) Config.mopidyStopIconSize = Math.max(6, Math.min(64, Number(o.mopidyStopIconSize) || Config.mopidyStopIconSize))
        if (o.mopidyStopIconX !== undefined) Config.mopidyStopIconX = Math.max(-20, Math.min(20, Number(o.mopidyStopIconX) || 0))
        if (o.mopidyStopIconY !== undefined) Config.mopidyStopIconY = Math.max(-20, Math.min(20, Number(o.mopidyStopIconY) || 0))
        if (o.mopidyRefreshIcon !== undefined) Config.mopidyRefreshIcon = String(o.mopidyRefreshIcon)
        if (o.mopidyRefreshIconSize !== undefined) Config.mopidyRefreshIconSize = Math.max(6, Math.min(64, Number(o.mopidyRefreshIconSize) || Config.mopidyRefreshIconSize))
        if (o.mopidyRefreshIconX !== undefined) Config.mopidyRefreshIconX = Math.max(-20, Math.min(20, Number(o.mopidyRefreshIconX) || 0))
        if (o.mopidyRefreshIconY !== undefined) Config.mopidyRefreshIconY = Math.max(-20, Math.min(20, Number(o.mopidyRefreshIconY) || 0))
        if (o.mopidyClearIcon !== undefined) Config.mopidyClearIcon = String(o.mopidyClearIcon)
        if (o.mopidyClearIconSize !== undefined) Config.mopidyClearIconSize = Math.max(6, Math.min(64, Number(o.mopidyClearIconSize) || Config.mopidyClearIconSize))
        if (o.mopidyClearIconX !== undefined) Config.mopidyClearIconX = Math.max(-20, Math.min(20, Number(o.mopidyClearIconX) || 0))
        if (o.mopidyClearIconY !== undefined) Config.mopidyClearIconY = Math.max(-20, Math.min(20, Number(o.mopidyClearIconY) || 0))
        if (o.mopidyControlIconColor !== undefined) {
            var mopidyControlIconColor = String(o.mopidyControlIconColor)
            if (/^#[0-9a-fA-F]{6,8}$/.test(mopidyControlIconColor) || mopidyControlIconColor === "transparent")
                Config.mopidyControlIconColor = mopidyControlIconColor
        }
        if (o.mopidyShowStopIcon !== undefined) Config.mopidyShowStopIcon = !!o.mopidyShowStopIcon
        if (o.mopidyShowRefreshIcon !== undefined) Config.mopidyShowRefreshIcon = !!o.mopidyShowRefreshIcon
        if (o.mopidyShowClearIcon !== undefined) Config.mopidyShowClearIcon = !!o.mopidyShowClearIcon
        if (o.mopidyShowQueueTotalDuration !== undefined) Config.mopidyShowQueueTotalDuration = !!o.mopidyShowQueueTotalDuration
        if (o.mopidyQueueDurationMode !== undefined) {
            var queueDurationMode = String(o.mopidyQueueDurationMode)
            if (queueDurationMode === "total" || queueDurationMode === "remaining") Config.mopidyQueueDurationMode = queueDurationMode
        }
        if (o.mopidyQueueDurationFont !== undefined) Config.mopidyQueueDurationFont = String(o.mopidyQueueDurationFont)
        if (o.mopidyQueueDurationFontSize !== undefined) Config.mopidyQueueDurationFontSize = Math.max(6, Math.min(40, Number(o.mopidyQueueDurationFontSize) || Config.mopidyQueueDurationFontSize))
        if (o.mopidyQueueDurationColor !== undefined) {
            var queueDurationColor = String(o.mopidyQueueDurationColor)
            if (/^#[0-9a-fA-F]{6,8}$/.test(queueDurationColor) || queueDurationColor === "transparent") Config.mopidyQueueDurationColor = queueDurationColor
        }
        if (o.mopidyQueueDurationX !== undefined) { var queueDurationX = Number(o.mopidyQueueDurationX); if (isFinite(queueDurationX)) Config.mopidyQueueDurationX = Math.round(queueDurationX) }
        if (o.mopidyQueueDurationY !== undefined) Config.mopidyQueueDurationY = Math.max(-20, Math.min(20, Number(o.mopidyQueueDurationY) || 0))
        if (o.mopidyShowAlbumRemaining !== undefined) Config.mopidyShowAlbumRemaining = !!o.mopidyShowAlbumRemaining
        if (o.mopidyShowTrackRemaining !== undefined) Config.mopidyShowTrackRemaining = !!o.mopidyShowTrackRemaining
        if (o.mopidyShuffleIcon !== undefined) Config.mopidyShuffleIcon = String(o.mopidyShuffleIcon)
        if (o.mopidyShuffleIconSize !== undefined) Config.mopidyShuffleIconSize = Math.max(6, Math.min(64, Number(o.mopidyShuffleIconSize) || Config.mopidyShuffleIconSize))
        if (o.mopidyShuffleIconX !== undefined) Config.mopidyShuffleIconX = Math.max(-20, Math.min(20, Number(o.mopidyShuffleIconX) || 0))
        if (o.mopidyShuffleIconY !== undefined) Config.mopidyShuffleIconY = Math.max(-20, Math.min(20, Number(o.mopidyShuffleIconY) || 0))
        if (o.mopidyShowShuffleIcon !== undefined) Config.mopidyShowShuffleIcon = !!o.mopidyShowShuffleIcon
        if (o.mopidyRepeatIcon !== undefined) Config.mopidyRepeatIcon = String(o.mopidyRepeatIcon)
        if (o.mopidyRepeatIconSize !== undefined) Config.mopidyRepeatIconSize = Math.max(6, Math.min(64, Number(o.mopidyRepeatIconSize) || Config.mopidyRepeatIconSize))
        if (o.mopidyRepeatIconX !== undefined) Config.mopidyRepeatIconX = Math.max(-20, Math.min(20, Number(o.mopidyRepeatIconX) || 0))
        if (o.mopidyRepeatIconY !== undefined) Config.mopidyRepeatIconY = Math.max(-20, Math.min(20, Number(o.mopidyRepeatIconY) || 0))
        if (o.mopidyShowRepeatIcon !== undefined) Config.mopidyShowRepeatIcon = !!o.mopidyShowRepeatIcon
        if (o.mopidyOpenAddIcon !== undefined) Config.mopidyOpenAddIcon = String(o.mopidyOpenAddIcon)
        if (o.mopidyOpenAddIconSize !== undefined) Config.mopidyOpenAddIconSize = Math.max(6, Math.min(64, Number(o.mopidyOpenAddIconSize) || Config.mopidyOpenAddIconSize))
        if (o.mopidyOpenAddIconX !== undefined) Config.mopidyOpenAddIconX = Math.max(-20, Math.min(20, Number(o.mopidyOpenAddIconX) || 0))
        if (o.mopidyOpenAddIconY !== undefined) Config.mopidyOpenAddIconY = Math.max(-20, Math.min(20, Number(o.mopidyOpenAddIconY) || 0))
        if (o.mopidyShowOpenAddIcon !== undefined) Config.mopidyShowOpenAddIcon = !!o.mopidyShowOpenAddIcon
        if (o.mopidyAddIcon !== undefined) Config.mopidyAddIcon = String(o.mopidyAddIcon)
        if (o.mopidyAddIconSize !== undefined) Config.mopidyAddIconSize = Math.max(6, Math.min(64, Number(o.mopidyAddIconSize) || Config.mopidyAddIconSize))
        if (o.mopidyAddIconX !== undefined) Config.mopidyAddIconX = Math.max(-20, Math.min(20, Number(o.mopidyAddIconX) || 0))
        if (o.mopidyAddIconY !== undefined) Config.mopidyAddIconY = Math.max(-20, Math.min(20, Number(o.mopidyAddIconY) || 0))
        if (o.mopidyShowAddIcon !== undefined) Config.mopidyShowAddIcon = !!o.mopidyShowAddIcon
        if (o.mopidySwitchPlaylistIcon !== undefined) Config.mopidySwitchPlaylistIcon = String(o.mopidySwitchPlaylistIcon)
        if (o.mopidySwitchPlaylistIconSize !== undefined) Config.mopidySwitchPlaylistIconSize = Math.max(6, Math.min(64, Number(o.mopidySwitchPlaylistIconSize) || Config.mopidySwitchPlaylistIconSize))
        if (o.mopidySwitchPlaylistIconX !== undefined) Config.mopidySwitchPlaylistIconX = Math.max(-20, Math.min(20, Number(o.mopidySwitchPlaylistIconX) || 0))
        if (o.mopidySwitchPlaylistIconY !== undefined) Config.mopidySwitchPlaylistIconY = Math.max(-20, Math.min(20, Number(o.mopidySwitchPlaylistIconY) || 0))
        if (o.mopidyShowSwitchPlaylistIcon !== undefined) Config.mopidyShowSwitchPlaylistIcon = !!o.mopidyShowSwitchPlaylistIcon
        if (o.mopidyPlaylistDeleteIcon !== undefined) Config.mopidyPlaylistDeleteIcon = String(o.mopidyPlaylistDeleteIcon)
        if (o.mopidyPlaylistDeleteIconSize !== undefined) Config.mopidyPlaylistDeleteIconSize = Math.max(6, Math.min(64, Number(o.mopidyPlaylistDeleteIconSize) || Config.mopidyPlaylistDeleteIconSize))
        if (o.mopidyPlaylistDeleteIconX !== undefined) Config.mopidyPlaylistDeleteIconX = Math.max(-20, Math.min(20, Number(o.mopidyPlaylistDeleteIconX) || 0))
        if (o.mopidyPlaylistDeleteIconY !== undefined) Config.mopidyPlaylistDeleteIconY = Math.max(-20, Math.min(20, Number(o.mopidyPlaylistDeleteIconY) || 0))
        if (o.mopidyShowPlaylistDeleteIcon !== undefined) Config.mopidyShowPlaylistDeleteIcon = !!o.mopidyShowPlaylistDeleteIcon
        if (o.mopidyVolumeIcon !== undefined) Config.mopidyVolumeIcon = String(o.mopidyVolumeIcon)
        if (o.mopidyMutedIcon !== undefined) Config.mopidyMutedIcon = String(o.mopidyMutedIcon)
        if (o.mopidyVolumeIconSize !== undefined) Config.mopidyVolumeIconSize = Math.max(6, Math.min(64, Number(o.mopidyVolumeIconSize) || Config.mopidyVolumeIconSize))
        if (o.mopidyVolumeIconX !== undefined) Config.mopidyVolumeIconX = Math.max(-20, Math.min(20, Number(o.mopidyVolumeIconX) || 0))
        if (o.mopidyVolumeIconY !== undefined) Config.mopidyVolumeIconY = Math.max(-20, Math.min(20, Number(o.mopidyVolumeIconY) || 0))
        if (o.mopidyMutedIconSize !== undefined) Config.mopidyMutedIconSize = Math.max(6, Math.min(64, Number(o.mopidyMutedIconSize) || Config.mopidyMutedIconSize))
        if (o.mopidyMutedIconX !== undefined) Config.mopidyMutedIconX = Math.max(-20, Math.min(20, Number(o.mopidyMutedIconX) || 0))
        if (o.mopidyMutedIconY !== undefined) Config.mopidyMutedIconY = Math.max(-20, Math.min(20, Number(o.mopidyMutedIconY) || 0))
        if (o.mopidyShowVolumeIcon !== undefined) Config.mopidyShowVolumeIcon = !!o.mopidyShowVolumeIcon
        if (o.mopidyShowVolumePercent !== undefined) Config.mopidyShowVolumePercent = !!o.mopidyShowVolumePercent
        if (o.mopidyVolumeStep !== undefined) Config.mopidyVolumeStep = Math.max(1, Math.min(20, Number(o.mopidyVolumeStep) || Config.mopidyVolumeStep))
        if (o.mopidyEmptyQueueText !== undefined) Config.mopidyEmptyQueueText = String(o.mopidyEmptyQueueText)
        if (o.mopidyUnavailableText !== undefined) Config.mopidyUnavailableText = String(o.mopidyUnavailableText)
        if (o.mopidyStatusFont !== undefined) Config.mopidyStatusFont = String(o.mopidyStatusFont)
        if (o.mopidyStatusFontSize !== undefined) Config.mopidyStatusFontSize = Math.max(8, Math.min(100, Number(o.mopidyStatusFontSize) || Config.mopidyStatusFontSize))
        if (o.mopidyStatusLongFontSize !== undefined) Config.mopidyStatusLongFontSize = Math.max(6, Math.min(100, Number(o.mopidyStatusLongFontSize) || Config.mopidyStatusLongFontSize))
        if (o.mopidyStatusWidth !== undefined) Config.mopidyStatusWidth = Math.max(80, Math.min(600, Number(o.mopidyStatusWidth) || Config.mopidyStatusWidth))

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
