import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "." as MopidyWidgets
import "../primitives" as Primitives
import "../.."
import "../../js/mopidy/QueueReorderGeometry.js" as QueueReorderGeometry
import "../../js/mopidy/MopidyPresentation.js" as MopidyPresentation

Primitives.ModuleFrame {
    id: root
    moduleName: "mopidy"
    moduleBackgroundColor: Config.mopidyBackground

    readonly property int effectiveTrackRowHeight: MopidyPresentation.trackRowHeight(root.presentationMode, Config.mopidyTrackRowHeight)
    readonly property int effectiveAlbumHeaderHeight: MopidyPresentation.albumHeaderHeight(root.presentationMode, Config.mopidyAlbumFontSize)
    readonly property int effectiveQueueRowSpacing: MopidyPresentation.queueSpacing(root.presentationMode)

    function mopidyFontSize(configuredSize) {
        return MopidyPresentation.fontSize(root.presentationMode, configuredSize)
    }

    property bool externalTopPanelHover: false
    signal topPanelHideRequested()

    property bool queueAvailable: false
    property bool mopidyLaunchCooldown: false
    property int currentTlid: -1
    property int currentPositionMs: 0
    property int tracklistVersion: -1
    property int mopidyVolume: -1
    property int mopidyRestoreVolume: -1
    property bool mopidyMuted: false
    property bool mixerAvailable: false
    property bool mixerCommandPending: false
    property int pendingMixerTargetVolume: -1
    property bool pendingMixerTargetMuted: false
    property bool pendingMixerMatchVolume: true
    property bool mixerSoftMuteMigrationAttempted: false
    property bool mixerSoftMuteMigrationPending: false
    property bool playbackPrefsAvailable: false
    property bool mopidyRandom: false
    property bool mopidyRepeat: false
    property bool mopidySingle: false
    property var tracks: []
    property bool queueBusy: false
    property bool queueMovePending: false
    property bool queueReorderDragging: false
    property real queueDragPointerY: -1
    property var queueActiveDragHandle: null
    property bool queueRefreshPending: false
    readonly property int queueTotalDuration: root.tracks.reduce(function(sum, track) {
        var duration = Number(track && track.duration)
        return sum + (isFinite(duration) && duration > 0 ? duration : 0)
    }, 0)
    readonly property int currentQueueIndex: {
        for (var i = 0; i < root.tracks.length; ++i) {
            if (Number(root.tracks[i] && root.tracks[i].tlid) === Number(root.currentTlid))
                return i
        }
        return -1
    }
    readonly property int queueRemainingDuration: {
        var index = root.currentQueueIndex
        if (index < 0)
            return root.queueTotalDuration
        var total = 0
        for (var i = index; i < root.tracks.length; ++i) {
            var duration = Number(root.tracks[i] && root.tracks[i].duration)
            if (!isFinite(duration) || duration < 0) duration = 0
            if (i === index)
                duration = Math.max(0, duration - Math.max(0, Number(root.currentPositionMs) || 0))
            total += duration
        }
        return Math.max(0, total)
    }
    property bool searchOpen: false
    property bool addingToPlaylist: false
    property string libraryMode: "browse"
    property bool searchBusy: false
    property string searchQuery: ""
    property var searchResults: []
    property bool browseBusy: false
    property string browseUri: ""
    property string browseTitle: "Музыка"
    property string browseFolderCover: ""
    // Album-folder previews are requested lazily by visible delegates through one serialized worker.
    property var browseEntryCoverStates: ({})
    property var browseEntryCoverQueue: []
    property string browseEntryCoverActiveUri: ""
    property int browseEntryCoverGeneration: 0
    property int browseEntryCoverActiveGeneration: -1
    property var browseStack: []
    property var browseEntries: []
    property bool playlistsBusy: false
    property bool playlistContentReorderDragging: false
    property real playlistContentDragY: -1
    property var playlistContentActiveDragHandle: null
    property var playlists: []
    property string playlistUri: ""
    property string playlistContentMoveUri: ""
    property string playlistTitle: ""
    property var playlistItems: []
    property string playlistEditNotice: ""
    property string playlistContentActionNotice: "трек"
    readonly property var browseDisplayEntries: {
        if (root.browseStack.length === 0)
            return root.browseEntries
        return [{type: "parent", uri: "", name: ".."}].concat(root.browseEntries)
    }
    property bool fileFilterOpen: false
    property string fileFilterQuery: ""
    readonly property var filteredBrowseDisplayEntries: {
        var entries = root.browseDisplayEntries
        var query = String(root.fileFilterQuery || "").trim().toLowerCase()
        if (!query)
            return entries
        return entries.filter(function(entry) {
            if (entry && entry.type === "parent") return true
            return String(entry && entry.name || "").toLowerCase().indexOf(query) >= 0
        })
    }
    property real preservedQueueContentY: 0
    property int stickyAlbumIndex: -1
    property var stickyAlbumData: null
    property real stickyAlbumY: 0
    property alias queueReorderAdapter: queueReorderAdapterObject
    property alias queueReorderHost: queueReorderOverlay
    readonly property bool queueReorderEnabled: root.queueAvailable && root.tracks.length > 1
        && root.tracklistVersion >= 0 && !root.queueBusy && !root.queueMovePending
        && !queueProcess.running && !queuePositionProcess.running

    readonly property var queueLayout: {
        var items = root.queueItems
        var tops = []
        var heights = []
        var albumIndices = []
        var trackDisplayIndices = []
        var y = 0
        var spacing = root.effectiveQueueRowSpacing
        var albumHeight = root.effectiveAlbumHeaderHeight
        var trackHeight = root.effectiveTrackRowHeight

        for (var i = 0; i < items.length; ++i) {
            tops.push(y)
            if (items[i] && items[i].kind === "album") {
                albumIndices.push(i)
                heights.push(albumHeight)
                y += albumHeight
            } else {
                trackDisplayIndices.push(i)
                heights.push(trackHeight)
                y += trackHeight
            }
            if (i < items.length - 1)
                y += spacing
        }

        return {
            tops: tops,
            heights: heights,
            albumIndices: albumIndices,
            trackDisplayIndices: trackDisplayIndices,
            contentHeight: y,
            spacing: spacing
        }
    }
    property string addNoticeText: ""
    property bool addNoticeVisible: false
    property bool addNoticeError: false
    property string addTrackNotice: "трек"
    property string addFolderNotice: "папка"
    property string playlistActionNotice: "плейлист"
    property string playlistSwitchNotice: "плейлист"
    property bool playlistDialogVisible: false
    property string playlistDialogMode: "create"
    property string playlistDialogInput: ""
    property string playlistDialogError: ""
    property string playlistManageUri: ""
    property string playlistManageTitle: ""
    property var playlistManageResult: null
    readonly property bool playlistManageBusy: playlistManageProcess.running
    readonly property bool queueReorderPending: queueReorderProcess.running || root.queueMovePending
    readonly property bool playlistContentMoveBusy: playlistContentMoveProcess.running
    readonly property bool playlistContentActionBusy: playlistContentActionProcess.running
    // Keep the view context stable while either backend-aware reorder is active.
    readonly property bool reorderInteractionLocked: root.queueReorderPending || root.queueReorderDragging
        || root.playlistContentMoveBusy || root.playlistContentMoveUri.length > 0
        || root.playlistContentReorderDragging

    function updateStickyAlbum() {
        if (!Config.mopidyGroupAlbums || !queueView || root.queueItems.length === 0) {
            root.stickyAlbumIndex = -1
            root.stickyAlbumData = null
            root.stickyAlbumY = 0
            return
        }

        var metrics = root.queueLayout
        var albumIndices = metrics.albumIndices
        if (!albumIndices || albumIndices.length === 0) {
            root.stickyAlbumIndex = -1
            root.stickyAlbumData = null
            root.stickyAlbumY = 0
            return
        }

        var contentY = Math.max(0, queueView.contentY)
        var lo = 0
        var hi = albumIndices.length

        while (lo < hi) {
            var mid = Math.floor((lo + hi) / 2)
            var candidateIndex = albumIndices[mid]
            if (metrics.tops[candidateIndex] <= contentY)
                lo = mid + 1
            else
                hi = mid
        }

        var albumPosition = Math.max(0, lo - 1)
        var albumIndex = albumIndices[albumPosition]
        var headerHeight = root.effectiveAlbumHeaderHeight

        root.stickyAlbumIndex = albumIndex
        root.stickyAlbumData = root.queueItems[albumIndex]

        if (albumPosition + 1 < albumIndices.length) {
            var nextAlbumIndex = albumIndices[albumPosition + 1]
            var nextY = metrics.tops[nextAlbumIndex] - contentY
            root.stickyAlbumY = Math.max(-headerHeight, Math.min(0, nextY - headerHeight))
        } else {
            root.stickyAlbumY = 0
        }
    }

    function hoverTextColor(hovered, normalColor) {
        return hovered && Config.mopidyHoverMode === "text" ? Config.mopidyHoverColor : normalColor
    }

    function hoverBackgroundColor(hovered) {
        return hovered && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : Config.transparent
    }

    function hoverBorderWidth(hovered) {
        return hovered && Config.buttonBordersEnabled && Config.mopidyHoverMode === "frame" ? 1 : 0
    }

    function hoverBorderColor(hovered) {
        return hovered && Config.buttonBordersEnabled && Config.mopidyHoverMode === "frame" ? Config.mopidyHoverColor : Config.transparent
    }

    function escapeRichText(value) {
        return String(value === undefined || value === null ? "" : value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/\"/g, "&quot;")
            .replace(/'/g, "&#39;")
    }

    function formatOneLineTrack(artist, title) {
        var artistName = String(artist || "")
        var trackName = String(title || "Без названия")
        if (!artistName)
            return root.escapeRichText(trackName)

        var artistMarkup = root.escapeRichText(artistName)
        if (Config.mopidyArtistBold)
            artistMarkup = "<b>" + artistMarkup + "</b>"
        if (Config.mopidyArtistItalic)
            artistMarkup = "<i>" + artistMarkup + "</i>"

        return artistMarkup + root.escapeRichText(Config.mopidyTrackArtistSeparator) + root.escapeRichText(trackName)
    }

    function playlistDeleteIconColor(hovered) {
        if (hovered) return "#ff5555"
        return Config.mopidyControlIconColor
    }

    function showAddNotice(label) {
        var text = String(label || "").trim()
        if (!text)
            text = "трек"
        root.addNoticeError = false
        root.addNoticeText = "Добавлено: " + text
        root.addNoticeVisible = true
        addNoticeTimer.restart()
    }

    function showErrorNotice(label) {
        var text = String(label || "").trim()
        if (!text)
            text = "операция не выполнена"
        root.addNoticeError = true
        root.addNoticeText = "Ошибка: " + text
        root.addNoticeVisible = true
        addNoticeTimer.restart()
    }

    function normalizedTopIconOrder() {
        var allowed = ["stop", "shuffle", "repeat", "volume", "refresh", "openAdd", "clear"]
        var raw = String(Config.mopidyTopIconOrder || "").split(",")
        var out = []
        for (var i = 0; i < raw.length; ++i) {
            var id = String(raw[i] || "")
            if (allowed.indexOf(id) >= 0 && out.indexOf(id) < 0) out.push(id)
        }
        for (var j = 0; j < allowed.length; ++j)
            if (out.indexOf(allowed[j]) < 0) out.push(allowed[j])
        return out
    }

    readonly property var queueItems: {
        var source = root.tracks || []
        var items = []
        var segments = []
        var segmentIndexByTrack = []
        var lastKey = ""
        var hasSegment = false
        var currentSegment = null

        for (var i = 0; i < source.length; ++i) {
            var track = source[i] || {}
            var album = String(track.album || "").trim()
            if (!album) album = "Без альбома"
            var albumDate = String(track.albumDate || "").trim()
            var yearMatch = albumDate.match(/\d{4}/)
            var albumYear = yearMatch ? yearMatch[0] : ""
            var albumKey = albumYear + "\u001f" + album

            if (!hasSegment || albumKey !== lastKey) {
                currentSegment = {
                    key: albumKey,
                    album: album,
                    albumYear: albumYear,
                    start: i,
                    end: i - 1,
                    duration: 0,
                    tlids: []
                }
                segments.push(currentSegment)
                hasSegment = true
                lastKey = albumKey
            }

            currentSegment.end = i
            var duration = Number(track.duration)
            if (isFinite(duration) && duration > 0)
                currentSegment.duration += duration
            var tlid = Number(track.tlid)
            if (isFinite(tlid) && tlid >= 0)
                currentSegment.tlids.push(tlid)
            segmentIndexByTrack.push(segments.length - 1)
        }

        for (var si = 0; si < segments.length; ++si) {
            var segment = segments[si]
            segment.remainingDuration = segment.duration
        }

        for (var j = 0; j < source.length; ++j) {
            var trackData = source[j] || {}
            var segmentData = segments[segmentIndexByTrack[j]] || null
            if (Config.mopidyGroupAlbums && segmentData && j === segmentData.start) {
                items.push({
                    kind: "album",
                    album: segmentData.album,
                    albumYear: segmentData.albumYear,
                    duration: segmentData.duration,
                    startIndex: segmentData.start,
                    endIndex: segmentData.end,
                    tlids: segmentData.tlids.slice(0)
                })
            }
            items.push({
                kind: "track",
                track: trackData,
                queueIndex: j
            })
        }

        return items
    }

    function queueTrackGeometry(trackIndex) {
        var index = Number(trackIndex)
        var layout = root.queueLayout
        if (!isFinite(index) || Math.floor(index) !== index || index < 0
                || index >= layout.trackDisplayIndices.length || !queueView)
            return null
        var displayIndex = layout.trackDisplayIndices[index]
        return {
            x: 0,
            y: layout.tops[displayIndex] - queueView.contentY,
            width: queueView.width,
            height: layout.heights[displayIndex]
        }
    }

    function queueTrackInsertionSlotGeometry(sourceIndex, destination, host, anchorInfo) {
        var layout = root.queueLayout
        var count = layout.trackDisplayIndices.length
        if (!queueView || destination < 0 || destination >= count || anchorInfo.index < 0)
            return null

        var centerY
        if (anchorInfo.afterLast) {
            var lastDisplay = layout.trackDisplayIndices[anchorInfo.index]
            var lastBottom = layout.tops[lastDisplay] + layout.heights[lastDisplay]
            centerY = QueueReorderGeometry.gapCenterAfter(lastBottom, layout.spacing) - queueView.contentY
        } else {
            // A visual album header belongs to the first track in its segment.
            // Insert before that header, not between the header and its first track.
            var candidateDisplay = QueueReorderGeometry.insertionAnchorDisplayIndex(
                        root.queueItems, layout.trackDisplayIndices, anchorInfo.index, sourceIndex)
            if (candidateDisplay < 0)
                return null
            var candidateTop = layout.tops[candidateDisplay]
            var previousDisplay = candidateDisplay - 1
            if (previousDisplay >= 0) {
                var previousBottom = layout.tops[previousDisplay] + layout.heights[previousDisplay]
                centerY = QueueReorderGeometry.gapCenterBetween(previousBottom, candidateTop) - queueView.contentY
            } else {
                centerY = QueueReorderGeometry.gapCenterBefore(candidateTop, layout.spacing) - queueView.contentY
            }
        }

        return {
            destination: destination,
            x: 4,
            y: centerY - 1,
            width: Math.max(0, queueView.width - 8),
            centerY: centerY
        }
    }

    function queueTrackSourceAdjacentGapGeometry(sourceIndex, edge, host) {
        var layout = root.queueLayout
        var index = Number(sourceIndex)
        if (!queueView || index < 0 || index >= layout.trackDisplayIndices.length)
            return null
        var displayIndex = layout.trackDisplayIndices[index]
        var sourceTop = layout.tops[displayIndex]
        var sourceBottom = sourceTop + layout.heights[displayIndex]
        var centerY

        if (edge === "before") {
            // This is the physical gap immediately before the track row. If
            // the row begins an album segment, that gap is after its header;
            // the header stays attached to the whole segment.
            var previousDisplay = displayIndex - 1
            if (previousDisplay >= 0) {
                var previousBottom = layout.tops[previousDisplay] + layout.heights[previousDisplay]
                centerY = QueueReorderGeometry.gapCenterBetween(previousBottom, sourceTop) - queueView.contentY
            } else {
                centerY = QueueReorderGeometry.gapCenterBefore(sourceTop, layout.spacing) - queueView.contentY
            }
        } else {
            var nextDisplay = displayIndex + 1
            if (nextDisplay < layout.tops.length) {
                centerY = (sourceBottom + layout.tops[nextDisplay]) / 2 - queueView.contentY
            } else {
                centerY = sourceBottom + layout.spacing / 2 - queueView.contentY
            }
        }

        return {
            destination: index,
            kind: "source",
            x: 4,
            y: centerY - 1,
            width: Math.max(0, queueView.width - 8),
            centerY: centerY
        }
    }

    function setQueueReorderDragging(active, handle) {
        root.queueReorderDragging = !!active
        root.queueActiveDragHandle = active ? handle : null
        if (!root.queueReorderDragging) root.queueDragPointerY = -1
        if (!root.queueReorderDragging && root.queueRefreshPending && !root.queueMovePending) {
            root.queueRefreshPending = false
            Qt.callLater(function() { root.refreshQueue() })
        }
    }

    function updateQueueDragPosition(sceneX, sceneY) {
        var point = queueView.mapFromItem(null, sceneX, sceneY)
        root.queueDragPointerY = isFinite(point.y) ? point.y : -1
    }

    function rememberQueueScroll() {
        if (queueView)
            root.preservedQueueContentY = queueView.contentY
    }

    function restoreQueueScroll() {
        if (!queueView) return
        Qt.callLater(function() {
            if (!queueView) return
            var maxY = Math.max(0, queueView.contentHeight - queueView.height)
            queueView.contentY = Math.max(0, Math.min(root.preservedQueueContentY, maxY))
            root.updateStickyAlbum()
        })
    }

    function refreshQueue() {
        if (!Settings.mopidy) return
        if (root.queueMovePending || root.queueReorderDragging) {
            root.queueRefreshPending = true
            return
        }
        if (queueProcess.running) return
        root.queueRefreshPending = false
        root.rememberQueueScroll()
        queueProcess.running = true
    }

    function refreshPlaybackPosition() {
        if (!Settings.mopidy || queuePositionProcess.running || root.queueMovePending || root.queueReorderDragging) return
        queuePositionProcess.running = true
    }

    function applyPlaybackPositionSnapshot(data) {
        if (!data || data.ok !== true) return false

        var nextTlid = data.current_tlid === null || data.current_tlid === undefined
            ? -1 : Number(data.current_tlid)
        if (!isFinite(nextTlid)) nextTlid = -1
        var nextPosition = Math.max(0, Number(data.position_ms ?? 0) || 0)
        var version = data.tracklist_version === null || data.tracklist_version === undefined
            ? -1 : Number(data.tracklist_version)
        if (!isFinite(version) || version < 0) version = -1

        var currentChanged = nextTlid !== Number(root.currentTlid)
        var versionChanged = version >= 0 && version !== Number(root.tracklistVersion)
        var refreshFullQueue = !root.queueAvailable || currentChanged || versionChanged

        root.currentTlid = nextTlid
        root.currentPositionMs = nextPosition
        if (version >= 0 && !(versionChanged && root.queueReorderDragging))
            root.tracklistVersion = version
        if (versionChanged && root.queueReorderDragging) {
            root.queueRefreshPending = true
            return false
        }
        return refreshFullQueue
    }

    function requestMopidyStart() {
        if (root.queueAvailable || root.mopidyLaunchCooldown || mopidyLaunchProcess.running)
            return
        root.mopidyLaunchCooldown = true
        mopidyLaunchCooldownTimer.restart()
        mopidyLaunchProcess.running = true
    }

    function runQueueCommand(args) {
        if (!Settings.mopidy || queueBusy) return
        queueBusy = true
        queueActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/tracklist.sh"].concat(args)
        queueActionProcess.running = true
    }

    function playTrack(tlid) { runQueueCommand(["play", String(tlid)]) }
    function removeTrack(tlid) { runQueueCommand(["remove", String(tlid)]) }
    function removeAlbum(tlids) {
        if (!tlids || tlids.length === 0) return
        var args = ["remove_album"]
        for (var i = 0; i < tlids.length; ++i)
            args.push(String(tlids[i]))
        runQueueCommand(args)
    }
    function moveTrack(tlid, position) {
        var target = Number(position)
        var trackId = Number(tlid)
        if (!Settings.mopidy || !root.queueReorderEnabled || !isFinite(trackId)
                || Math.floor(trackId) !== trackId || trackId < 0 || !isFinite(target) || Math.floor(target) !== target
                || target < 0 || target >= root.tracks.length)
            return
        root.queueBusy = true
        root.queueMovePending = true
        queueReorderProcess.result = null
        queueReorderProcess.command = [Quickshell.shellDir + "/scripts/mopidy/tracklist.sh",
            "move", String(trackId), String(target), String(root.tracklistVersion)]
        queueReorderProcess.running = true
    }
    function clearQueue() { runQueueCommand(["clear"]) }
    function stopPlayback() { runQueueCommand(["stop"]) }
    function refreshMopidyStatus() {
        if (!Settings.mopidy || mopidyStatusProcess.running || mixerActionProcess.running ||
                mixerSoftMuteMigrationProcess.running || playbackPrefsActionProcess.running) return
        mopidyStatusProcess.running = true
    }
    function refreshMopidyStatusAfterPending() {
        root.refreshMopidyStatus()
    }

    function markMixerCommandPending(targetVolume, targetMuted, matchVolume) {
        root.mixerCommandPending = true
        root.pendingMixerTargetVolume = targetVolume
        root.pendingMixerTargetMuted = !!targetMuted
        root.pendingMixerMatchVolume = matchVolume !== false
        mixerPendingFallbackTimer.restart()
    }

    function setMixerVolume(value) {
        var next = Math.max(0, Math.min(100, Math.round(Number(value))))
        if (!isFinite(next) || mixerActionProcess.running) return
        var wasMuted = root.mopidyMuted
        if (next > 0) {
            root.mopidyRestoreVolume = next
            root.mopidyMuted = false
        } else {
            root.mopidyMuted = true
        }
        root.mopidyVolume = next
        root.markMixerCommandPending(next, next === 0, true)
        // A positive wheel/volume change while muted must also clear a legacy
        // native mute; otherwise use the fast volume path directly.
        mixerActionProcess.command = wasMuted && next > 0
            ? [Quickshell.shellDir + "/scripts/mopidy/mixer.sh", "mute", "false", String(next)]
            : [Quickshell.shellDir + "/scripts/mopidy/mixer.sh", "set", String(next), String(root.mopidyRestoreVolume)]
        mixerActionProcess.running = true
    }
    function adjustMixerVolume(delta) {
        var base = root.mopidyMuted && root.mopidyRestoreVolume > 0
            ? Number(root.mopidyRestoreVolume) : Number(root.mopidyVolume)
        if (!isFinite(base) || base < 0) return
        setMixerVolume(base + delta)
    }
    function toggleRandom() {
        if (!root.playbackPrefsAvailable || playbackPrefsActionProcess.running) return
        playbackPrefsActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playback.sh", "random", String(!root.mopidyRandom)]
        playbackPrefsActionProcess.running = true
    }
    function cycleRepeat() {
        if (!root.playbackPrefsAvailable || playbackPrefsActionProcess.running) return
        var nextMode = root.mopidySingle ? 0 : (root.mopidyRepeat ? 2 : 1)
        playbackPrefsActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playback.sh", "repeat", String(nextMode)]
        playbackPrefsActionProcess.running = true
    }

    function toggleMixerMute() {
        if (mixerActionProcess.running || root.mixerSoftMuteMigrationPending || !root.mixerAvailable) return
        if (!root.mopidyMuted) {
            var current = Number(root.mopidyVolume)
            if (isFinite(current) && current > 0)
                root.mopidyRestoreVolume = current
            if (!(root.mopidyRestoreVolume > 0))
                root.mopidyRestoreVolume = 50
            root.mopidyMuted = true
            // The fast PulseAudio path mutes the sink input without forcing
            // Mopidy's own volume to zero. Leave the last mixer level intact.
            root.markMixerCommandPending(current, true, false)
            mixerActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/mixer.sh", "mute", "true", String(root.mopidyRestoreVolume)]
        } else {
            var restore = Number(root.mopidyRestoreVolume)
            if (!isFinite(restore) || restore < 1 || restore > 100)
                restore = 50
            root.mopidyRestoreVolume = restore
            root.mopidyMuted = false
            root.mopidyVolume = restore
            root.markMixerCommandPending(restore, false, false)
            mixerActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/mixer.sh", "mute", "false", String(restore)]
        }
        mixerActionProcess.running = true
    }

    function toggleSearch() {
        if (root.reorderInteractionLocked) return
        if (root.searchOpen) {
            root.searchOpen = false
            root.fileFilterOpen = false
            root.fileFilterQuery = ""
            root.searchQuery = ""
            root.searchResults = []
            root.browseEntries = []
            root.browseStack = []
            root.playlists = []
            root.playlistItems = []
            if (root.addingToPlaylist && root.playlistUri) {
                root.addingToPlaylist = false
                root.libraryMode = "playlistItems"
                return
            }
            root.addingToPlaylist = false
            root.playlistUri = ""
            root.playlistTitle = ""
        } else {
            root.addingToPlaylist = false
            root.libraryMode = "browse"
            root.openBrowseRoot()
            root.searchOpen = true
            root.focusBrowsePanel()
        }
    }

    function openPlaylistAddMode() {
        if (root.reorderInteractionLocked || !root.playlistUri || root.playlistsBusy) return
        root.addingToPlaylist = true
        root.searchOpen = true
        root.searchQuery = ""
        root.searchResults = []
        root.libraryMode = "browse"
        root.openBrowseRoot()
        root.focusBrowsePanel()
    }

    function focusBrowsePanel() {
        Qt.callLater(function() {
            if (root.searchOpen && root.libraryMode === "browse" && !root.fileFilterOpen)
                libraryView.focusBrowsePanel()
        })
    }

    function openFileFilter() {
        if (!root.searchOpen || root.libraryMode !== "browse") return
        root.fileFilterQuery = ""
        root.fileFilterOpen = true
        Qt.callLater(function() {
            if (root.fileFilterOpen)
                libraryView.focusFileFilter()
        })
    }

    function closeFileFilter(clearQuery) {
        root.fileFilterOpen = false
        if (clearQuery) {
            root.fileFilterQuery = ""
            libraryView.clearFileFilterField()
        }
        Qt.callLater(function() {
            if (root.searchOpen && root.libraryMode === "browse")
                libraryView.focusBrowsePanel()
        })
    }

    function browseEntryCoverPath(uri) {
        var entry = root.browseEntryCoverStates[String(uri || "")]
        return entry && entry.status === "ready" ? String(entry.path || "") : ""
    }

    function requestBrowseEntryCover(uri) {
        var key = String(uri || "")
        if (!key || Config.mopidyBrowseCoverMode === "off" || root.browseBusy) return
        var current = root.browseEntryCoverStates[key]
        if (current && ["queued", "loading", "ready", "missing"].indexOf(current.status) >= 0) return
        var states = Object.assign({}, root.browseEntryCoverStates)
        states[key] = { status: "queued", path: "" }
        root.browseEntryCoverStates = states
        root.browseEntryCoverQueue = root.browseEntryCoverQueue.concat([{ uri: key, generation: root.browseEntryCoverGeneration }])
        root.pumpBrowseEntryCoverQueue()
    }

    function releaseBrowseEntryCover(uri) {
        var key = String(uri || "")
        if (!key) return
        var state = root.browseEntryCoverStates[key]
        if (!state || state.status !== "queued") return
        var remaining = []
        for (var i = 0; i < root.browseEntryCoverQueue.length; ++i) {
            var item = root.browseEntryCoverQueue[i]
            if (item.uri !== key || item.generation !== root.browseEntryCoverGeneration)
                remaining.push(item)
        }
        root.browseEntryCoverQueue = remaining
        var states = Object.assign({}, root.browseEntryCoverStates)
        delete states[key]
        root.browseEntryCoverStates = states
    }

    function resetBrowseEntryCoverQueue() {
        root.browseEntryCoverGeneration += 1
        root.browseEntryCoverQueue = []
        root.browseEntryCoverStates = ({})
        // An already running request is allowed to finish into the shared disk cache.
        // Its old generation prevents the result from being attached to the new folder.
    }

    function pumpBrowseEntryCoverQueue() {
        if (browseEntryCoverProcess.running || root.browseEntryCoverActiveUri) return
        while (root.browseEntryCoverQueue.length > 0) {
            var queue = root.browseEntryCoverQueue.slice(0)
            var next = queue.shift()
            root.browseEntryCoverQueue = queue
            if (!next || next.generation !== root.browseEntryCoverGeneration) continue
            var state = root.browseEntryCoverStates[next.uri]
            if (!state || state.status !== "queued") continue
            var states = Object.assign({}, root.browseEntryCoverStates)
            states[next.uri] = { status: "loading", path: "" }
            root.browseEntryCoverStates = states
            root.browseEntryCoverActiveUri = next.uri
            root.browseEntryCoverActiveGeneration = next.generation
            browseEntryCoverProcess.command = [Quickshell.shellDir + "/scripts/mopidy/library.sh", "folder_cover", next.uri]
            browseEntryCoverProcess.running = true
            return
        }
    }

    function finishBrowseEntryCover(uri, generation, exitCode, output) {
        var key = String(uri || "")
        var resultPath = String(output || "").trim()
        if (generation === root.browseEntryCoverGeneration && key) {
            var states = Object.assign({}, root.browseEntryCoverStates)
            states[key] = exitCode === 0 && resultPath
                ? { status: "ready", path: resultPath }
                : { status: "missing", path: "" }
            root.browseEntryCoverStates = states
        }
        root.browseEntryCoverActiveUri = ""
        root.browseEntryCoverActiveGeneration = -1
        Qt.callLater(function() { root.pumpBrowseEntryCoverQueue() })
    }

    function openBrowseRoot() {
        if (root.reorderInteractionLocked) return
        root.resetBrowseEntryCoverQueue()
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
        root.libraryMode = "browse"
        root.browseStack = []
        root.browseUri = ""
        root.browseTitle = "Музыка"
        root.browseFolderCover = ""
        root.browseEntries = []
        root.browseBusy = true
        browseProcess.command = [Quickshell.shellDir + "/scripts/mopidy/library.sh", "browse"]
        browseProcess.running = true
    }

    function browseUriAt(uri, title) {
        if (root.reorderInteractionLocked || root.browseBusy) return
        root.resetBrowseEntryCoverQueue()
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
        root.browseStack = root.browseStack.concat([{uri: root.browseUri, title: root.browseTitle}])
        root.browseUri = String(uri || "")
        root.browseTitle = String(title || "Музыка")
        root.browseFolderCover = ""
        root.browseBusy = true
        browseProcess.command = [Quickshell.shellDir + "/scripts/mopidy/library.sh", "browse", root.browseUri]
        browseProcess.running = true
    }

    function browseBack() {
        if (root.reorderInteractionLocked || root.browseBusy || root.browseStack.length === 0) return
        root.resetBrowseEntryCoverQueue()
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
        var stack = root.browseStack.slice(0)
        var previous = stack.pop()
        root.browseStack = stack
        root.browseUri = String(previous.uri || "")
        root.browseTitle = String(previous.title || "Музыка")
        root.browseFolderCover = ""
        root.browseBusy = true
        browseProcess.command = root.browseUri
            ? [Quickshell.shellDir + "/scripts/mopidy/library.sh", "browse", root.browseUri]
            : [Quickshell.shellDir + "/scripts/mopidy/library.sh", "browse"]
        browseProcess.running = true
    }

    function closeLibraryBrowserToQueue() {
        if (root.reorderInteractionLocked) return
        root.resetBrowseEntryCoverQueue()
        root.searchOpen = false
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
        root.searchQuery = ""
        root.searchResults = []
        root.browseEntries = []
        root.browseStack = []
        root.browseUri = ""
        root.browseTitle = "Музыка"
        root.browseFolderCover = ""
        root.playlists = []
        root.playlistItems = []
        root.playlistUri = ""
        root.playlistTitle = ""
        root.addingToPlaylist = false
        root.libraryMode = "browse"
    }

    function showSearch() {
        if (root.reorderInteractionLocked) return
        if (root.searchOpen && root.libraryMode === "search") {
            root.closeLibraryBrowserToQueue()
            return
        }
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
        root.libraryMode = "search"
        root.searchResults = []
        Qt.callLater(function() { libraryView.focusSearchField() })
    }

    function showBrowse() {
        if (root.reorderInteractionLocked) return
        if (root.searchOpen && root.libraryMode === "browse" && root.browseStack.length === 0) {
            root.closeLibraryBrowserToQueue()
            return
        }
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
        root.libraryMode = "browse"
        root.searchQuery = ""
        root.searchResults = []
        root.openBrowseRoot()
        root.focusBrowsePanel()
    }

    function showPlaylists() {
        if (root.reorderInteractionLocked) return
        if (root.searchOpen && root.libraryMode === "playlists") {
            root.closeLibraryBrowserToQueue()
            return
        }
        if (root.searchOpen && root.libraryMode === "playlistItems") {
            root.backToPlaylists()
            return
        }
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
        root.addingToPlaylist = false
        root.libraryMode = "playlists"
        root.searchQuery = ""
        root.searchResults = []
        root.playlistUri = ""
        root.playlistTitle = ""
        root.playlistItems = []
        root.loadPlaylists()
    }

    function loadPlaylists() {
        if (root.reorderInteractionLocked || root.playlistsBusy) return
        root.playlistsBusy = true
        playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "list"]
        playlistsProcess.running = true
    }

    function openPlaylist(uri, title) {
        if (root.reorderInteractionLocked || !uri || root.playlistsBusy) return
        root.libraryMode = "playlistItems"
        root.playlistUri = String(uri)
        root.playlistTitle = String(title || "Плейлист")
        root.playlistItems = []
        root.playlistsBusy = true
        playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "items", root.playlistUri]
        playlistsProcess.running = true
    }

    function backToPlaylists() {
        if (root.reorderInteractionLocked) return
        root.libraryMode = "playlists"
        root.playlistUri = ""
        root.playlistTitle = ""
        root.playlistItems = []
        root.loadPlaylists()
    }

    function resetToInitialScreen() {
        if (root.reorderInteractionLocked) return
        root.searchOpen = false
        root.addingToPlaylist = false
        root.searchQuery = ""
        root.searchResults = []
        root.playlistDialogVisible = false
        root.playlistDialogMode = "create"
        root.playlistDialogInput = ""
        root.playlistDialogError = ""
        root.playlistManageUri = ""
        root.playlistManageTitle = ""
        root.playlistItems = []
        root.playlistUri = ""
        root.playlistTitle = ""
        root.libraryMode = "browse"
        root.browseStack = []
        root.browseUri = ""
        root.browseTitle = "Музыка"
        root.openBrowseRoot()
    }

    function switchPlaylist(uri, label) {
        if (root.reorderInteractionLocked || !uri || playlistSwitchProcess.running) return
        root.playlistSwitchNotice = String(label || "плейлист")
        playlistSwitchProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "switch_playlist", uri]
        playlistSwitchProcess.running = true
    }

    function addPlaylist(uri, label) {
        if (root.reorderInteractionLocked || !uri || playlistActionProcess.running) return
        root.playlistActionNotice = String(label || "плейлист")
        playlistActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "add_playlist", uri]
        playlistActionProcess.running = true
    }

    function addPlaylistItem(uri, label) {
        if (root.reorderInteractionLocked || !uri || playlistActionProcess.running) return
        root.playlistActionNotice = String(label || "трек")
        playlistActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "add_track", uri]
        playlistActionProcess.running = true
    }

    function setPlaylistContentReorderDragging(active, handle) {
        root.playlistContentReorderDragging = !!active
        root.playlistContentActiveDragHandle = active ? handle : null
        if (!root.playlistContentReorderDragging)
            root.playlistContentDragY = -1
    }

    function updatePlaylistContentDragPosition(y) {
        var nextY = Number(y)
        root.playlistContentDragY = isFinite(nextY) ? nextY : -1
    }

    function removePlaylistItem(index, label) {
        if (!root.playlistUri || playlistContentActionProcess.running
                || playlistContentMoveProcess.running || root.playlistContentReorderDragging) return
        root.playlistContentActionNotice = String(label || "трек")
        playlistContentActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "remove_item", root.playlistUri, String(index)]
        playlistContentActionProcess.running = true
    }

    function movePlaylistItem(index, newIndex, label, expectedUri) {
        // This callback is invoked by the active drag handle before its
        // draggingChanged(false) notification. Allow that one gesture to
        // commit, while rejecting any already-running backend mutation.
        if (!root.playlistUri || playlistContentMoveProcess.running || root.queueReorderPending
                || root.queueReorderDragging || playlistContentActionProcess.running || playlistEditProcess.running
                || playlistsProcess.running || root.playlistsBusy)
            return
        var from = Number(index)
        var to = Number(newIndex)
        var moveUri = String(root.playlistUri)
        if (!isFinite(from) || Math.floor(from) !== from || !isFinite(to) || Math.floor(to) !== to
                || from < 0 || to < 0 || from >= root.playlistItems.length || to >= root.playlistItems.length
                || from === to)
            return
        var expectedOrder = root.playlistItems.map(function(item) { return String(item && item.uri || "") })
        if (!expectedUri || expectedOrder[from] !== String(expectedUri))
            return
        root.playlistContentMoveUri = moveUri
        root.playlistContentActionNotice = String(label || "трек")
        playlistContentMoveProcess.result = null
        playlistContentMoveProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh",
            "move_item", moveUri, String(from), String(to),
            String(expectedUri), JSON.stringify(expectedOrder)]
        playlistContentMoveProcess.running = true
    }

    function openCreatePlaylistDialog() {
        if (root.reorderInteractionLocked || playlistManageProcess.running) return
        root.playlistDialogMode = "create"
        root.playlistDialogInput = ""
        root.playlistDialogError = ""
        root.playlistManageUri = ""
        root.playlistManageTitle = ""
        root.playlistDialogVisible = true
    }

    function openRenamePlaylistDialog() {
        if (root.reorderInteractionLocked || !root.playlistUri || playlistManageProcess.running) return
        root.playlistDialogMode = "rename"
        root.playlistDialogInput = String(root.playlistTitle || "")
        root.playlistDialogError = ""
        root.playlistManageUri = String(root.playlistUri)
        root.playlistManageTitle = String(root.playlistTitle || "Плейлист")
        root.playlistDialogVisible = true
    }

    function openDeletePlaylistDialog() {
        if (root.reorderInteractionLocked || !root.playlistUri || playlistManageProcess.running) return
        root.playlistDialogMode = "delete"
        root.playlistDialogInput = ""
        root.playlistDialogError = ""
        root.playlistManageUri = String(root.playlistUri)
        root.playlistManageTitle = String(root.playlistTitle || "Плейлист")
        root.playlistDialogVisible = true
    }

    function openDeletePlaylistFromListDialog(uri, title) {
        if (root.reorderInteractionLocked || !uri || playlistManageProcess.running) return
        root.playlistDialogMode = "delete"
        root.playlistDialogInput = ""
        root.playlistDialogError = ""
        root.playlistManageUri = String(uri)
        root.playlistManageTitle = String(title || "Плейлист")
        root.playlistDialogVisible = true
    }

    function closePlaylistDialog() {
        root.playlistDialogVisible = false
        root.playlistDialogError = ""
    }

    function submitPlaylistDialog() {
        if (root.reorderInteractionLocked || playlistManageProcess.running) return
        var name = String(root.playlistDialogInput || "").trim()
        if (root.playlistDialogMode !== "delete" && !name) {
            root.playlistDialogError = "Введите название"
            return
        }

        root.playlistManageResult = null
        if (root.playlistDialogMode === "create") {
            playlistManageProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "create", name]
        } else if (root.playlistDialogMode === "rename") {
            playlistManageProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "rename", root.playlistManageUri, name]
        } else {
            playlistManageProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "delete", root.playlistManageUri]
        }
        playlistManageProcess.running = true
    }

    function searchLibrary() {
        var query = String(root.searchQuery || "").trim()
        if (!query || searchBusy) {
            if (!query) root.searchResults = []
            return
        }
        searchBusy = true
        searchProcess.command = [Quickshell.shellDir + "/scripts/mopidy/library.sh", "search", query]
        searchProcess.running = true
    }

    function addBrowseFolder(uri, label) {
        if (root.reorderInteractionLocked || !uri) return
        if (root.addingToPlaylist) {
            if (!root.playlistUri || playlistEditProcess.running) return
            root.playlistEditNotice = String(label || "папка")
            playlistEditProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "add_folder_to_playlist", root.playlistUri, uri]
            playlistEditProcess.running = true
            return
        }
        if (addFolderProcess.running) return
        addFolderNotice = String(label || "папка")
        addFolderProcess.command = [Quickshell.shellDir + "/scripts/mopidy/library.sh", "add_folder", uri]
        addFolderProcess.running = true
    }

    function addSearchResult(uri, label) {
        if (root.reorderInteractionLocked || !uri) return
        if (root.addingToPlaylist) {
            if (!root.playlistUri || playlistEditProcess.running) return
            root.playlistEditNotice = String(label || "трек")
            playlistEditProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "add_to_playlist", root.playlistUri, uri]
            playlistEditProcess.running = true
            return
        }
        if (addTrackProcess.running) return
        addTrackNotice = String(label || "трек")
        addTrackProcess.command = [Quickshell.shellDir + "/scripts/mopidy/library.sh", "add", uri]
        addTrackProcess.running = true
    }

    function trackShowsRemainingTime(track) {
        return !!Config.mopidyShowTrackRemaining && Number(track && track.tlid) === Number(root.currentTlid)
    }

    function trackDisplayDuration(track) {
        var duration = Number(track && track.duration)
        if (!isFinite(duration) || duration < 0) duration = 0
        if (!root.trackShowsRemainingTime(track))
            return duration
        return Math.max(0, duration - Math.max(0, Number(root.currentPositionMs) || 0))
    }

    function albumShowsRemainingTime(itemData) {
        if (!Config.mopidyShowAlbumRemaining || !itemData || itemData.startIndex === undefined || itemData.endIndex === undefined)
            return false
        var current = root.currentQueueIndex
        return current >= itemData.startIndex && current <= itemData.endIndex
    }

    function albumDisplayDuration(itemData) {
        var duration = Number(itemData && itemData.duration)
        if (!isFinite(duration) || duration < 0) duration = 0
        if (!root.albumShowsRemainingTime(itemData))
            return duration

        var current = root.currentQueueIndex
        var remaining = 0
        for (var i = current; i <= itemData.endIndex; ++i) {
            var rd = Number(root.tracks[i] && root.tracks[i].duration)
            if (!isFinite(rd) || rd < 0) rd = 0
            if (i === current)
                rd = Math.max(0, rd - Math.max(0, Number(root.currentPositionMs) || 0))
            remaining += rd
        }
        return Math.max(0, remaining)
    }

    function formatDuration(value, remaining) {
        var ms = Number(value)
        if (!isFinite(ms) || ms < 0)
            return "--:--"

        var totalSeconds = Math.floor(ms / 1000)
        var seconds = totalSeconds % 60
        var minutes = Math.floor(totalSeconds / 60)
        var hours = Math.floor(minutes / 60)
        minutes %= 60

        function twoDigits(number) {
            return number < 10 ? "0" + number : String(number)
        }

        var formatted = hours > 0
            ? hours + ":" + twoDigits(minutes) + ":" + twoDigits(seconds)
            : minutes + ":" + twoDigits(seconds)
        return remaining ? "-" + formatted : formatted
    }

    QtObject {
        id: queueReorderAdapterObject
        readonly property int count: root.tracks.length
        readonly property int spacing: root.effectiveQueueRowSpacing
        function geometryAt(index, host) { return root.queueTrackGeometry(index) }
        function insertionSlotGeometry(sourceIndex, destination, host, anchorInfo) {
            return root.queueTrackInsertionSlotGeometry(sourceIndex, destination, host, anchorInfo)
        }
        function sourceAdjacentGapGeometry(sourceIndex, edge, host) {
            return root.queueTrackSourceAdjacentGapGeometry(sourceIndex, edge, host)
        }
    }

    Process {
        id: mopidyLaunchProcess
        command: [Quickshell.shellDir + "/scripts/mopidy/start.sh"]
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.showErrorNotice("Не удалось запустить Mopidy")
            // The queue poller will detect when the RPC service becomes ready.
            // Keep the click area gated briefly even if the launcher exited early.
        }
    }

    Timer {
        id: mopidyLaunchCooldownTimer
        interval: 5000
        repeat: false
        onTriggered: root.mopidyLaunchCooldown = false
    }

    Timer {
        interval: 16
        repeat: true
        running: root.queueReorderDragging
        onTriggered: {
            var pointerY = Number(root.queueDragPointerY)
            if (!isFinite(pointerY) || pointerY < 0 || !queueView)
                return
            var edge = 36
            var maxY = Math.max(0, queueView.contentHeight - queueView.height)
            var previousContentY = queueView.contentY
            if (pointerY < edge && queueView.contentY > 0) {
                var strengthUp = Math.max(0.15, (edge - pointerY) / edge)
                queueView.contentY = Math.max(0, queueView.contentY - 12 * strengthUp)
            } else if (pointerY > queueView.height - edge && queueView.contentY < maxY) {
                var strengthDown = Math.max(0.15, (pointerY - (queueView.height - edge)) / edge)
                queueView.contentY = Math.min(maxY, queueView.contentY + 12 * strengthDown)
            }
            if (queueView.contentY !== previousContentY && root.queueActiveDragHandle
                    && typeof root.queueActiveDragHandle.refreshDropTargetForLayoutChange === "function")
                root.queueActiveDragHandle.refreshDropTargetForLayoutChange()
        }
    }

    Process {
        id: queuePositionProcess
        command: [Quickshell.shellDir + "/scripts/mopidy/tracklist.sh", "position"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var refreshFullQueue = false
                try {
                    var data = JSON.parse(this.text.trim() || "{}")
                    refreshFullQueue = root.applyPlaybackPositionSnapshot(data)
                } catch (e) {
                    // A failed lightweight poll must not clear a usable queue;
                    // the next tick will retry and detect version/current-track changes.
                }
                queuePositionProcess.running = false
                if (refreshFullQueue) root.refreshQueue()
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: queueProcess
        command: [Quickshell.shellDir + "/scripts/mopidy/tracklist.sh", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text.trim() || "{}")
                    root.queueAvailable = data.ok !== false
                    root.currentTlid = Number(data.current_tlid ?? -1)
                    root.currentPositionMs = Math.max(0, Number(data.position_ms ?? 0) || 0)
                    var version = data.tracklist_version === null || data.tracklist_version === undefined
                        ? -1 : Number(data.tracklist_version)
                    root.tracklistVersion = isFinite(version) && version >= 0 ? version : -1
                    root.tracks = Array.isArray(data.tracks) ? data.tracks : []
                    root.restoreQueueScroll()
                    root.updateStickyAlbum()
                } catch (e) {
                    root.queueAvailable = false
                    root.currentTlid = -1
                    root.currentPositionMs = 0
                    root.tracklistVersion = -1
                    root.tracks = []
                    root.restoreQueueScroll()
                }
                queueProcess.running = false
            }
        }
    }

    Process {
        id: queueReorderProcess
        command: []
        running: false
        property var result: null
        stdout: StdioCollector {
            onStreamFinished: {
                try { queueReorderProcess.result = JSON.parse(this.text.trim() || "{}") }
                catch (e) { queueReorderProcess.result = {ok: false, error: "invalid_response"} }
            }
        }
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            var data = queueReorderProcess.result || {}
            queueReorderProcess.result = null
            queueReorderProcess.running = false
            root.queueMovePending = false
            root.queueBusy = false
            if (Settings.mopidy && (exitCode !== 0 || data.ok !== true)) {
                var error = String(data.error || "move_failed")
                var message = "Не удалось изменить порядок очереди"
                if (error === "queue_changed")
                    message = "Очередь изменилась. Порядок обновлён — повтори перетаскивание."
                else if (error === "offline")
                    message = "Mopidy недоступен"
                else if (error === "move_unconfirmed")
                    message = "Mopidy не подтвердил новый порядок очереди"
                else if (error === "queue_version_unavailable")
                    message = "Не удалось проверить актуальность очереди"
                else if (error === "track_not_found")
                    message = "Трек уже отсутствует в очереди"
                root.showErrorNotice(message)
            }
            if (Settings.mopidy) root.refreshQueue()
            else root.queueRefreshPending = false
        }
    }

    Process {
        id: queueActionProcess
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            queueBusy = false
            root.refreshQueue()
        }
    }

    Process {
        id: mopidyStatusProcess
        command: [Quickshell.shellDir + "/scripts/mopidy/status.sh", "state"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim() || "{}")
                    var mixer = data.mixer || ({})
                    var playback = data.playback || ({})

                    root.mixerAvailable = mixer.ok === true && (mixer.volume !== null || mixer.mute !== null)
                    var hasVolume = mixer.volume !== null && isFinite(Number(mixer.volume))
                    var actualVolume = hasVolume ? Math.max(0, Math.min(100, Number(mixer.volume))) : -1
                    var actualMute = mixer.mute === true || (hasVolume && actualVolume === 0)
                    var pendingMatches = !root.mixerCommandPending ||
                        (root.pendingMixerTargetMuted
                            ? actualMute
                            : (!actualMute && (!root.pendingMixerMatchVolume ||
                                (hasVolume && actualVolume === root.pendingMixerTargetVolume))))
                    if (!root.mixerCommandPending || pendingMatches) {
                        if (hasVolume)
                            root.mopidyVolume = actualVolume
                        else if (!root.mixerAvailable)
                            root.mopidyVolume = -1
                        var savedRestore = Number(mixer.restore_volume)
                        if (isFinite(savedRestore) && savedRestore >= 1 && savedRestore <= 100)
                            root.mopidyRestoreVolume = savedRestore
                        else if (hasVolume && actualVolume > 0)
                            root.mopidyRestoreVolume = actualVolume
                        else if (hasVolume && actualVolume === 0 && !(root.mopidyRestoreVolume > 0))
                            root.mopidyRestoreVolume = 50
                        if (mixer.mute !== null || hasVolume)
                            root.mopidyMuted = actualMute
                        else if (!root.mixerAvailable)
                            root.mopidyMuted = false
                        if (root.mixerCommandPending && pendingMatches) {
                            root.mixerCommandPending = false
                            root.pendingMixerTargetVolume = -1
                            root.pendingMixerTargetMuted = false
                            root.pendingMixerMatchVolume = true
                            mixerPendingFallbackTimer.stop()
                        }

                        // v782 used Mopidy's software mixer volume=0 for mute.
                        // On the first v783 status poll after upgrade, migrate
                        // that legacy state while the Pulse stream is muted;
                        // restore the internal mixer level before the next user
                        // unmute click, so regular toggles are immediate.
                        var migrationRestore = Number(mixer.restore_volume)
                        var needsSoftMuteMigration = !root.mixerSoftMuteMigrationAttempted &&
                            !root.mixerCommandPending && mixer.pulse_mute_available === true &&
                            hasVolume && actualVolume === 0 && isFinite(migrationRestore) &&
                            migrationRestore >= 1 && migrationRestore <= 100
                        if (needsSoftMuteMigration) {
                            root.mixerSoftMuteMigrationAttempted = true
                            root.mixerSoftMuteMigrationPending = true
                            root.mopidyRestoreVolume = migrationRestore
                            root.mopidyMuted = true
                            mixerSoftMuteMigrationProcess.command = [Quickshell.shellDir + "/scripts/mopidy/mixer.sh", "migrate-soft-mute", String(migrationRestore)]
                            mixerSoftMuteMigrationProcess.running = true
                        } else if (hasVolume && actualVolume === 0 && root.mixerCommandPending) {
                            // A just-issued user command may deliberately set
                            // volume to zero; don't reinterpret it as legacy state.
                            root.mixerSoftMuteMigrationAttempted = true
                        }
                    } else {
                        // An already-running poll may contain the state from
                        // before the user's click. Ignore that stale snapshot
                        // until a poll confirms the requested target volume.
                        mixerPendingRefreshTimer.restart()
                    }

                    root.playbackPrefsAvailable = playback.ok === true
                    root.mopidyRandom = !!playback.random
                    root.mopidyRepeat = !!playback.repeat
                    root.mopidySingle = !!playback.single
                } catch (e) {
                    root.mixerAvailable = false
                    if (!root.mixerCommandPending) {
                        root.mopidyVolume = -1
                        root.mopidyMuted = false
                    } else {
                        mixerPendingRefreshTimer.restart()
                    }
                    root.playbackPrefsAvailable = false
                    root.mopidyRandom = false
                    root.mopidyRepeat = false
                    root.mopidySingle = false
                }
                mopidyStatusProcess.running = false
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: mixerSoftMuteMigrationProcess
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            mixerSoftMuteMigrationProcess.running = false
            root.mixerSoftMuteMigrationPending = false
            root.refreshMopidyStatus()
        }
    }

    Process {
        id: mixerActionProcess
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            mixerActionProcess.running = false
            root.refreshMopidyStatus()
        }
    }

    Process {
        id: playbackPrefsActionProcess
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            playbackPrefsActionProcess.running = false
            root.refreshMopidyStatus()
        }
    }

    Process {
        id: browseEntryCoverProcess
        command: []
        running: false
        stdout: StdioCollector { id: browseEntryCoverStdout }
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            browseEntryCoverProcess.running = false
            root.finishBrowseEntryCover(
                root.browseEntryCoverActiveUri,
                root.browseEntryCoverActiveGeneration,
                exitCode,
                browseEntryCoverStdout.text
            )
        }
    }

    Process {
        id: browseProcess
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim() || "{}")
                    root.browseEntries = data.ok === false ? [] : (Array.isArray(data.entries) ? data.entries : [])
                    root.browseFolderCover = data.ok === false ? "" : String(data.folderCover || "")
                } catch (e) {
                    root.browseEntries = []
                    root.browseFolderCover = ""
                }
                root.browseBusy = false
                browseProcess.running = false
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: searchProcess
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim() || "{}")
                    root.searchResults = data.ok === false ? [] : (Array.isArray(data.results) ? data.results : [])
                } catch (e) {
                    root.searchResults = []
                }
                root.searchBusy = false
                searchProcess.running = false
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: addTrackProcess
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            root.showAddNotice(root.addTrackNotice)
            root.refreshQueue()
        }
    }

    Process {
        id: addFolderProcess
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            root.showAddNotice(root.addFolderNotice)
            root.refreshQueue()
        }
    }

    Process {
        id: playlistsProcess
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim() || "{}")
                    if (root.libraryMode === "playlists")
                        root.playlists = data.ok === false ? [] : (Array.isArray(data.playlists) ? data.playlists : [])
                    else if (root.libraryMode === "playlistItems")
                        root.playlistItems = data.ok === false ? [] : (Array.isArray(data.items) ? data.items : [])
                } catch (e) {
                    if (root.libraryMode === "playlists")
                        root.playlists = []
                    else if (root.libraryMode === "playlistItems")
                        root.playlistItems = []
                }
                root.playlistsBusy = false
                playlistsProcess.running = false
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: playlistEditProcess
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    playlistEditProcess.result = JSON.parse(this.text.trim() || "{}")
                } catch (e) {
                    playlistEditProcess.result = {ok: false, error: "invalid_response"}
                }
            }
        }
        stderr: StdioCollector {}
        property var result: null
        onExited: {
            var data = playlistEditProcess.result || {}
            playlistEditProcess.result = null
            playlistEditProcess.running = false
            if (data.ok) {
                var count = Number(data.count || 0)
                root.showAddNotice("В плейлист «" + String(root.playlistTitle || "") + "» добавлено: " + count)
                if (root.playlistUri) {
                    root.playlistsBusy = true
                    playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "items", root.playlistUri]
                    playlistsProcess.running = true
                }
            } else {
                root.showErrorNotice(data.error || "не удалось добавить в плейлист")
            }
        }
    }

    Process {
        id: playlistContentActionProcess
        command: []
        running: false
        property var result: null
        stdout: StdioCollector {
            onStreamFinished: {
                try { playlistContentActionProcess.result = JSON.parse(this.text.trim() || "{}") }
                catch (e) { playlistContentActionProcess.result = {ok: false, error: "invalid_response"} }
            }
        }
        stderr: StdioCollector {}
        onExited: {
            var data = playlistContentActionProcess.result || {}
            playlistContentActionProcess.result = null
            playlistContentActionProcess.running = false
            if (data.ok) {
                root.showAddNotice("Удалено из плейлиста: " + String(root.playlistContentActionNotice || "трек"))
                if (root.playlistUri) {
                    root.playlistsBusy = true
                    playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "items", root.playlistUri]
                    playlistsProcess.running = true
                }
            } else {
                root.showErrorNotice(data.error || "не удалось удалить трек из плейлиста")
            }
        }
    }

    Process {
        id: playlistContentMoveProcess
        command: []
        running: false
        property var result: null
        stdout: StdioCollector {
            onStreamFinished: {
                try { playlistContentMoveProcess.result = JSON.parse(this.text.trim() || "{}") }
                catch (e) { playlistContentMoveProcess.result = {ok: false, error: "invalid_response"} }
            }
        }
        stderr: StdioCollector {}
        onExited: {
            var data = playlistContentMoveProcess.result || {}
            var moveUri = String(root.playlistContentMoveUri || "")
            playlistContentMoveProcess.result = null
            playlistContentMoveProcess.running = false
            root.playlistContentMoveUri = ""
            if (Settings.mopidy && moveUri) {
                if (!data.ok)
                    root.showErrorNotice(data.error === "playlist_changed"
                        ? "Плейлист изменился. Порядок обновлён — повтори перетаскивание."
                        : (data.error === "move_unconfirmed"
                            ? "Mopidy не подтвердил новый порядок плейлиста"
                            : (data.error === "offline"
                                ? "Mopidy недоступен"
                                : (data.error === "playlist_save_failed"
                                    ? "Сервер не разрешил изменить этот плейлист"
                                    : "Не удалось изменить порядок плейлиста"))))
                if (root.playlistUri === moveUri && root.libraryMode === "playlistItems") {
                    root.playlistsBusy = true
                    playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "items", moveUri]
                    playlistsProcess.running = true
                }
            }
        }
    }

    Process {
        id: playlistSwitchProcess
        command: []
        running: false
        property var result: null
        stdout: StdioCollector {
            onStreamFinished: {
                try { playlistSwitchProcess.result = JSON.parse(this.text.trim() || "{}") }
                catch (e) { playlistSwitchProcess.result = {ok: false, error: "invalid_response"} }
            }
        }
        stderr: StdioCollector {}
        onExited: {
            var data = playlistSwitchProcess.result || {}
            playlistSwitchProcess.result = null
            playlistSwitchProcess.running = false
            if (data.ok)
                root.showAddNotice("Переключено: " + String(root.playlistSwitchNotice || "плейлист"))
            else
                root.showErrorNotice(data.error || "не удалось переключить плейлист")
            root.refreshQueue()
        }
    }

    Process {
        id: playlistActionProcess
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            playlistActionProcess.running = false
            root.showAddNotice(root.playlistActionNotice)
            root.refreshQueue()
            if (root.libraryMode === "playlistItems" && root.playlistUri) {
                root.playlistsBusy = true
                playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "items", root.playlistUri]
                playlistsProcess.running = true
            }
        }
    }

    Process {
        id: playlistManageProcess
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.playlistManageResult = JSON.parse(this.text.trim() || "{}")
                } catch (e) {
                    root.playlistManageResult = {ok: false, error: "invalid_response"}
                }
            }
        }
        stderr: StdioCollector {}
        onExited: {
            var data = root.playlistManageResult || {}
            var mode = root.playlistDialogMode
            var targetTitle = root.playlistManageTitle
            root.playlistManageResult = null
            playlistManageProcess.running = false

            if (!data.ok) {
                root.playlistDialogError = data.error || "Операция не выполнена"
                return
            }

            root.closePlaylistDialog()

            if (mode === "create") {
                root.showAddNotice("Создан: " + String((data.playlist && data.playlist.name) || root.playlistDialogInput || "плейлист"))
                root.loadPlaylists()
                return
            }

            if (mode === "rename") {
                if (data.playlist && data.playlist.uri)
                    root.playlistUri = String(data.playlist.uri)
                if (data.playlist && data.playlist.name)
                    root.playlistTitle = String(data.playlist.name)
                root.showAddNotice("Переименован: " + String((data.playlist && data.playlist.name) || targetTitle))
                if (root.libraryMode === "playlistItems" && root.playlistUri) {
                    root.playlistsBusy = true
                    playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "items", root.playlistUri]
                    playlistsProcess.running = true
                } else {
                    root.loadPlaylists()
                }
                return
            }

            if (mode === "delete") {
                root.showAddNotice("Удалён: " + targetTitle)
                root.playlistUri = ""
                root.playlistTitle = ""
                root.playlistItems = []
                root.libraryMode = "playlists"
                root.loadPlaylists()
            }
        }
    }

    Timer {
        id: addNoticeTimer
        interval: 1600
        repeat: false
        onTriggered: root.addNoticeVisible = false
    }

    Timer {
        id: mixerPendingRefreshTimer
        interval: 250
        repeat: false
        onTriggered: root.refreshMopidyStatusAfterPending()
    }

    Timer {
        id: mixerPendingFallbackTimer
        interval: 6000
        repeat: false
        onTriggered: {
            if (!root.mixerCommandPending) return
            root.mixerCommandPending = false
            root.pendingMixerTargetVolume = -1
            root.pendingMixerTargetMuted = false
            root.pendingMixerMatchVolume = true
            root.refreshMopidyStatus()
        }
    }

    Timer {
        // Keep countdown labels smooth without downloading and rebuilding the
        // complete queue every second. Queue data refreshes when its version or
        // the current track changes.
        interval: 1000
        running: Settings.loaded && Settings.mopidy
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshPlaybackPosition()
    }

    Timer {
        interval: 1200
        running: Settings.loaded && Settings.mopidy
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshMopidyStatus()
    }

    Connections {
        target: Config
        function onMopidyGroupAlbumsChanged() {
            Qt.callLater(function() { root.updateStickyAlbum() })
        }
        function onMopidyAlbumFontSizeChanged() {
            Qt.callLater(function() { root.updateStickyAlbum() })
        }
        function onMopidyAlbumSeparatorChanged() {
            Qt.callLater(function() { root.updateStickyAlbum() })
        }
    }

    Connections {
        target: Settings
        function onMopidyChanged() {
            if (Settings.mopidy) {
                root.refreshQueue()
                root.refreshMopidyStatus()
            } else {
                if (queueProcess.running) queueProcess.running = false
                if (queuePositionProcess.running) queuePositionProcess.running = false
                if (queueActionProcess.running) queueActionProcess.running = false
                if (queueReorderProcess.running) queueReorderProcess.running = false
                if (mopidyStatusProcess.running) mopidyStatusProcess.running = false
                if (mixerActionProcess.running) mixerActionProcess.running = false
                if (mixerSoftMuteMigrationProcess.running) mixerSoftMuteMigrationProcess.running = false
                root.mixerSoftMuteMigrationPending = false
                root.mixerSoftMuteMigrationAttempted = false
                if (playbackPrefsActionProcess.running) playbackPrefsActionProcess.running = false
                queueBusy = false
                root.queueMovePending = false
                root.queueReorderDragging = false
                root.queueActiveDragHandle = null
                root.queueDragPointerY = -1
                root.queueRefreshPending = false
                root.playlistContentReorderDragging = false
                root.playlistContentActiveDragHandle = null
                root.playlistContentDragY = -1
                root.mixerAvailable = false
                root.mopidyVolume = -1
                root.mopidyRestoreVolume = -1
                root.mopidyMuted = false
                root.mixerCommandPending = false
                root.pendingMixerTargetVolume = -1
                root.pendingMixerTargetMuted = false
                root.pendingMixerMatchVolume = true
                mixerPendingFallbackTimer.stop()
                mixerPendingRefreshTimer.stop()
                root.playbackPrefsAvailable = false
                root.mopidyRandom = false
                root.mopidyRepeat = false
                root.mopidySingle = false
                root.searchOpen = false
                root.addingToPlaylist = false
                root.searchQuery = ""
                root.searchResults = []
                root.browseEntries = []
                root.browseStack = []
                root.browseUri = ""
                root.browseTitle = "Музыка"
                root.browseFolderCover = ""
                if (searchProcess.running) searchProcess.running = false
                if (browseProcess.running) browseProcess.running = false
                if (addTrackProcess.running) addTrackProcess.running = false
                if (addFolderProcess.running) addFolderProcess.running = false
                if (playlistsProcess.running) playlistsProcess.running = false
                if (playlistActionProcess.running) playlistActionProcess.running = false
                if (playlistSwitchProcess.running) playlistSwitchProcess.running = false
                if (playlistEditProcess.running) playlistEditProcess.running = false
                if (playlistContentActionProcess.running) playlistContentActionProcess.running = false
                if (playlistContentMoveProcess.running) playlistContentMoveProcess.running = false
                root.playlistContentMoveUri = ""
                root.playlistContentReorderDragging = false
                root.playlists = []
                root.playlistItems = []
                root.playlistUri = ""
                root.playlistTitle = ""
                root.libraryMode = "browse"
                root.queueAvailable = false
                root.tracks = []
                root.currentTlid = -1
                root.currentPositionMs = 0
                root.tracklistVersion = -1
            }
        }
        function onLoadedChanged() {
            if (Settings.loaded && Settings.mopidy) {
                root.refreshQueue()
                root.refreshMopidyStatus()
            }
        }
    }

    MouseArea {
        id: rootPointerArea
        anchors.fill: parent
        z: -100
        acceptedButtons: Qt.NoButton
        hoverEnabled: true

        onPositionChanged: {
            if (!Config.mopidyHideTopPanel || !root.externalTopPanelHover) return
            if (mouseY > 24)
                root.topPanelHideRequested()
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        MopidyWidgets.MopidyTopPanel {
            id: mopidyTopPanel
            width: parent.width
            controller: root
        }

        Item {
            width: parent.width
            // Fill all remaining vertical space after the top-panel wrapper.
            // The wrapper height may be negative when Top offset Y is negative;
            // account for that explicitly so it never creates an empty bottom gap.
            height: Math.max(0, parent.height - mopidyTopPanel.height - 6)
            clip: true

            Text {
                id: queueStatusText
                anchors.centerIn: parent
                width: Math.min(Config.mopidyStatusWidth, parent.width)
                visible: !root.searchOpen && root.tracks.length === 0
                text: root.queueAvailable ? Config.mopidyEmptyQueueText : Config.mopidyUnavailableText
                color: Config.textMuted
                font.family: Config.mopidyStatusFont
                font.pixelSize: Config.uiFontSize(Config.mopidyStatusFontSize)
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Config.mopidyStatusLongFontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
            }

            MopidyWidgets.MopidyLibraryView {
                id: libraryView
                anchors.fill: parent
                controller: root
            }

            ListView {
                id: queueView
                anchors.fill: parent
                clip: true
                spacing: root.effectiveQueueRowSpacing
                boundsBehavior: Flickable.StopAtBounds
                // Keep the source delegate alive while edge auto-scroll moves
                // the list across long queues; restore normal virtualization
                // as soon as the drag ends.
                cacheBuffer: root.queueReorderDragging ? contentHeight : height * 2
                interactive: !root.queueReorderDragging
                model: root.queueItems
                visible: !root.searchOpen

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                onContentYChanged: root.updateStickyAlbum()
                onCountChanged: root.updateStickyAlbum()
                onHeightChanged: root.updateStickyAlbum()
                onContentHeightChanged: root.updateStickyAlbum()

                delegate: Loader {
                    width: queueView.width
                    property var itemData: modelData
                    sourceComponent: itemData.kind === "album" ? albumHeaderComponent : trackRowComponent
                }
            }

            Loader {
                id: stickyAlbumLoader
                visible: !root.searchOpen && root.stickyAlbumIndex >= 0 && root.stickyAlbumData !== null
                z: 20
                x: 0
                y: root.stickyAlbumY
                width: queueView.width
                sourceComponent: albumHeaderComponent
                property var itemData: root.stickyAlbumData
                property bool stickyHeader: true
            }

            // The reorder marker is hosted above the sticky album header, but
            // outside the ListView's positioner/content item. Its coordinates
            // are viewport-relative, just like queueView.mapFromItem().
            Item {
                id: queueReorderOverlay
                anchors.fill: parent
                clip: true
                z: 30
            }

            Component {
                id: albumHeaderComponent
                MopidyWidgets.MopidyAlbumHeader {
                    controller: root
                    itemData: parent ? parent.itemData : null
                    stickyHeader: parent ? parent.stickyHeader === true : false
                }
            }

            Component {
                id: trackRowComponent
                MopidyWidgets.MopidyQueueTrackRow {
                    controller: root
                    itemData: parent ? parent.itemData : null
                }
            }

            // When Mopidy is available but the playback queue is empty, any click
            // in the queue area opens the track browser. The top panel remains
            // outside this item, so its existing buttons keep their own actions.
            MouseArea {
                id: emptyQueueOpenBrowserMouse
                anchors.fill: parent
                z: 100
                visible: root.queueAvailable && root.tracks.length === 0 && !root.searchOpen
                enabled: visible && !root.queueBusy
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.queueAvailable && root.tracks.length === 0 && !root.searchOpen)
                        root.toggleSearch()
                }
            }
}
    }

    // When the Mopidy RPC service is unavailable, clicking anywhere in the
    // module attempts to start the local `mopidy` command. This overlay sits
    // above the module's normal controls but below modal dialogs.
    MouseArea {
        id: unavailableMopidyClickArea
        anchors.fill: parent
        z: 150
        visible: !root.queueAvailable && !root.playlistDialogVisible
        enabled: visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        cursorShape: root.mopidyLaunchCooldown ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.requestMopidyStart()
    }

    MopidyWidgets.MopidyPlaylistDialog {
        anchors.fill: parent
        z: 200
        controller: root
    }

    Primitives.MorphGeometry {
        id: addNoticeMorph
        z: 100
        property real noticeWidth: Math.max(0, Math.min(Math.max(120, addNoticeTextMetrics.advanceWidth + 28), parent.width - 16))
        fromGeometry: Qt.rect(parent.width - 8 - noticeWidth, parent.height - 36, noticeWidth, 28)
        toGeometry: fromGeometry
        progress: root.addNoticeVisible ? 1 : 0
        visible: root.addNoticeVisible || normalizedProgress > 0.001
        animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")
        animationProfile: Config.animationMopidyMorphProfile
        animationPhase: root.addNoticeVisible ? "enter" : "exit"

        Item {
            anchors.fill: parent
            opacity: addNoticeMorph.normalizedProgress
            scale: 0.96 + 0.04 * addNoticeMorph.normalizedProgress
            transformOrigin: Item.Center

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: Config.settingsBackground
                border.width: 1
                border.color: root.addNoticeError ? "#ff5555" : Config.accent
            }

            Text {
                id: addNoticeTextItem
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                text: root.addNoticeText
                color: root.addNoticeError ? "#ff5555" : Config.text
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        TextMetrics {
            id: addNoticeTextMetrics
            font: addNoticeTextItem.font
            text: root.addNoticeText
        }
    }

}
