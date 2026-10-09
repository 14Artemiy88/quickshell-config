import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "." as Widgets
import "./primitives" as Primitives
import ".."

Widgets.Frame {
    id: root
    moduleName: "mopidy"
    moduleBackgroundColor: Config.mopidyBackground

    property bool externalTopPanelHover: false
    signal topPanelHideRequested()

    property bool queueAvailable: false
    property int currentTlid: -1
    property int currentPositionMs: 0
    property int mopidyVolume: -1
    property bool mopidyMuted: false
    property bool mixerAvailable: false
    property bool playbackPrefsAvailable: false
    property bool mopidyRandom: false
    property bool mopidyRepeat: false
    property bool mopidySingle: false
    property var tracks: []
    property bool queueBusy: false
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
    property var browseStack: []
    property var browseEntries: []
    property bool playlistsBusy: false
    property var playlists: []
    property string playlistUri: ""
    property string playlistTitle: ""
    property var playlistItems: []
    property string playlistEditNotice: ""
    property string playlistContentActionNotice: "трек"
    readonly property var browseDisplayEntries: {
        if (root.browseStack.length === 0)
            return root.browseEntries
        return [{type: "parent", uri: "", name: ".."}].concat(root.browseEntries)
    }
    property real preservedQueueContentY: 0
    property int stickyAlbumIndex: -1
    property var stickyAlbumData: null
    property real stickyAlbumY: 0

    readonly property var queueLayout: {
        var items = root.queueItems
        var tops = []
        var albumIndices = []
        var y = 0
        var spacing = 2
        var albumHeight = Math.max(26, Config.mopidyAlbumFontSize + 9)

        for (var i = 0; i < items.length; ++i) {
            tops.push(y)
            if (items[i] && items[i].kind === "album") {
                albumIndices.push(i)
                y += albumHeight
            } else {
                y += 38
            }
            if (i < items.length - 1)
                y += spacing
        }

        return { tops: tops, albumIndices: albumIndices, contentHeight: y }
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
        var headerHeight = Math.max(26, Config.mopidyAlbumFontSize + 9)

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
        return hovered && Config.mopidyHoverMode === "frame" ? 1 : 0
    }

    function hoverBorderColor(hovered) {
        return hovered && Config.mopidyHoverMode === "frame" ? Config.mopidyHoverColor : Config.transparent
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
            if (isFinite(tlid) && tlid > 0)
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
        if (!Settings.mopidy || queueProcess.running) return
        root.rememberQueueScroll()
        queueProcess.running = true
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
    function moveTrack(tlid, position) { runQueueCommand(["move", String(tlid), String(position)]) }
    function clearQueue() { runQueueCommand(["clear"]) }
    function stopPlayback() { runQueueCommand(["stop"]) }
    function refreshMixer() {
        if (!Settings.mopidy || mixerProcess.running || mixerActionProcess.running) return
        mixerProcess.running = true
    }
    function setMixerVolume(value) {
        var next = Math.max(0, Math.min(100, Math.round(Number(value))))
        if (!isFinite(next) || mixerActionProcess.running) return
        root.mopidyVolume = next
        mixerActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/mixer.sh", "set", String(next)]
        mixerActionProcess.running = true
    }
    function adjustMixerVolume(delta) {
        var base = Number(root.mopidyVolume)
        if (!isFinite(base) || base < 0) return
        setMixerVolume(base + delta)
    }
    function refreshPlaybackPrefs() {
        if (!Settings.mopidy || playbackPrefsProcess.running || playbackPrefsActionProcess.running) return
        playbackPrefsProcess.running = true
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
        if (mixerActionProcess.running || !root.mixerAvailable) return
        root.mopidyMuted = !root.mopidyMuted
        mixerActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/mixer.sh", "mute", String(root.mopidyMuted)]
        mixerActionProcess.running = true
    }

    function toggleSearch() {
        if (root.searchOpen) {
            root.searchOpen = false
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
        }
    }

    function openPlaylistAddMode() {
        if (!root.playlistUri || root.playlistsBusy) return
        root.addingToPlaylist = true
        root.searchOpen = true
        root.searchQuery = ""
        root.searchResults = []
        root.libraryMode = "browse"
        root.openBrowseRoot()
    }

    function openBrowseRoot() {
        root.libraryMode = "browse"
        root.browseStack = []
        root.browseUri = ""
        root.browseTitle = "Музыка"
        root.browseEntries = []
        root.browseBusy = true
        browseProcess.command = [Quickshell.shellDir + "/scripts/mopidy/library.sh", "browse"]
        browseProcess.running = true
    }

    function browseUriAt(uri, title) {
        if (root.browseBusy) return
        root.browseStack = root.browseStack.concat([{uri: root.browseUri, title: root.browseTitle}])
        root.browseUri = String(uri || "")
        root.browseTitle = String(title || "Музыка")
        root.browseBusy = true
        browseProcess.command = [Quickshell.shellDir + "/scripts/mopidy/library.sh", "browse", root.browseUri]
        browseProcess.running = true
    }

    function browseBack() {
        if (root.browseBusy || root.browseStack.length === 0) return
        var stack = root.browseStack.slice(0)
        var previous = stack.pop()
        root.browseStack = stack
        root.browseUri = String(previous.uri || "")
        root.browseTitle = String(previous.title || "Музыка")
        root.browseBusy = true
        browseProcess.command = root.browseUri
            ? [Quickshell.shellDir + "/scripts/mopidy/library.sh", "browse", root.browseUri]
            : [Quickshell.shellDir + "/scripts/mopidy/library.sh", "browse"]
        browseProcess.running = true
    }

    function showSearch() {
        root.libraryMode = "search"
        root.searchResults = []
        Qt.callLater(function() { if (searchField) searchField.forceActiveFocus() })
    }

    function showBrowse() {
        root.libraryMode = "browse"
        root.searchQuery = ""
        root.searchResults = []
        root.openBrowseRoot()
    }

    function showPlaylists() {
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
        if (root.playlistsBusy) return
        root.playlistsBusy = true
        playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "list"]
        playlistsProcess.running = true
    }

    function openPlaylist(uri, title) {
        if (!uri || root.playlistsBusy) return
        root.libraryMode = "playlistItems"
        root.playlistUri = String(uri)
        root.playlistTitle = String(title || "Плейлист")
        root.playlistItems = []
        root.playlistsBusy = true
        playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "items", root.playlistUri]
        playlistsProcess.running = true
    }

    function backToPlaylists() {
        root.libraryMode = "playlists"
        root.playlistUri = ""
        root.playlistTitle = ""
        root.playlistItems = []
        root.loadPlaylists()
    }

    function resetToInitialScreen() {
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
        if (!uri || playlistSwitchProcess.running) return
        root.playlistSwitchNotice = String(label || "плейлист")
        playlistSwitchProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "switch_playlist", uri]
        playlistSwitchProcess.running = true
    }

    function addPlaylist(uri, label) {
        if (!uri || playlistActionProcess.running) return
        root.playlistActionNotice = String(label || "плейлист")
        playlistActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "add_playlist", uri]
        playlistActionProcess.running = true
    }

    function addPlaylistItem(uri, label) {
        if (!uri || playlistActionProcess.running) return
        root.playlistActionNotice = String(label || "трек")
        playlistActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "add_track", uri]
        playlistActionProcess.running = true
    }

    function removePlaylistItem(index, label) {
        if (!root.playlistUri || playlistContentActionProcess.running) return
        root.playlistContentActionNotice = String(label || "трек")
        playlistContentActionProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "remove_item", root.playlistUri, String(index)]
        playlistContentActionProcess.running = true
    }

    function movePlaylistItem(index, newIndex, label) {
        if (!root.playlistUri || playlistContentMoveProcess.running || playlistContentActionProcess.running) return
        playlistContentMoveProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "move_item", root.playlistUri, String(index), String(newIndex)]
        playlistContentMoveProcess.running = true
    }

    function openCreatePlaylistDialog() {
        if (playlistManageProcess.running) return
        root.playlistDialogMode = "create"
        root.playlistDialogInput = ""
        root.playlistDialogError = ""
        root.playlistManageUri = ""
        root.playlistManageTitle = ""
        root.playlistDialogVisible = true
        Qt.callLater(function() { if (playlistDialogField) playlistDialogField.forceActiveFocus() })
    }

    function openRenamePlaylistDialog() {
        if (!root.playlistUri || playlistManageProcess.running) return
        root.playlistDialogMode = "rename"
        root.playlistDialogInput = String(root.playlistTitle || "")
        root.playlistDialogError = ""
        root.playlistManageUri = String(root.playlistUri)
        root.playlistManageTitle = String(root.playlistTitle || "Плейлист")
        root.playlistDialogVisible = true
        Qt.callLater(function() {
            if (playlistDialogField) {
                playlistDialogField.forceActiveFocus()
                playlistDialogField.selectAll()
            }
        })
    }

    function openDeletePlaylistDialog() {
        if (!root.playlistUri || playlistManageProcess.running) return
        root.playlistDialogMode = "delete"
        root.playlistDialogInput = ""
        root.playlistDialogError = ""
        root.playlistManageUri = String(root.playlistUri)
        root.playlistManageTitle = String(root.playlistTitle || "Плейлист")
        root.playlistDialogVisible = true
    }

    function openDeletePlaylistFromListDialog(uri, title) {
        if (!uri || playlistManageProcess.running) return
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
        if (playlistManageProcess.running) return
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
        if (!uri) return
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
        if (!uri) return
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

    function trackDisplayDuration(track) {
        var duration = Number(track && track.duration)
        if (!isFinite(duration) || duration < 0) duration = 0
        if (!Config.mopidyShowTrackRemaining || Number(track && track.tlid) !== Number(root.currentTlid))
            return duration
        return Math.max(0, duration - Math.max(0, Number(root.currentPositionMs) || 0))
    }

    function albumDisplayDuration(itemData) {
        var duration = Number(itemData && itemData.duration)
        if (!isFinite(duration) || duration < 0) duration = 0
        if (!Config.mopidyShowAlbumRemaining || !itemData || itemData.startIndex === undefined || itemData.endIndex === undefined)
            return duration

        var current = root.currentQueueIndex
        if (current < itemData.startIndex || current > itemData.endIndex)
            return duration

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

    function formatDuration(value) {
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

        if (hours > 0)
            return hours + ":" + twoDigits(minutes) + ":" + twoDigits(seconds)
        return minutes + ":" + twoDigits(seconds)
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
                    root.tracks = Array.isArray(data.tracks) ? data.tracks : []
                    root.restoreQueueScroll()
                    root.updateStickyAlbum()
                } catch (e) {
                    root.queueAvailable = false
                    root.currentTlid = -1
                    root.currentPositionMs = 0
                    root.tracks = []
                    root.restoreQueueScroll()
                }
                queueProcess.running = false
            }
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
        id: mixerProcess
        command: [Quickshell.shellDir + "/scripts/mopidy/mixer.sh", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim() || "{}")
                    root.mixerAvailable = data.ok === true && (data.volume !== null || data.mute !== null)
                    if (data.volume !== null && isFinite(Number(data.volume)))
                        root.mopidyVolume = Math.max(0, Math.min(100, Number(data.volume)))
                    if (data.mute !== null)
                        root.mopidyMuted = !!data.mute
                } catch (e) {
                    root.mixerAvailable = false
                    root.mopidyVolume = -1
                }
                mixerProcess.running = false
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: mixerActionProcess
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            mixerActionProcess.running = false
            root.refreshMixer()
        }
    }

    Process {
        id: playbackPrefsProcess
        command: [Quickshell.shellDir + "/scripts/mopidy/playback.sh", "state"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text.trim() || "{}")
                    root.playbackPrefsAvailable = data.ok === true
                    root.mopidyRandom = !!data.random
                    root.mopidyRepeat = !!data.repeat
                    root.mopidySingle = !!data.single
                } catch (e) {
                    root.playbackPrefsAvailable = false
                    root.mopidyRandom = false
                    root.mopidyRepeat = false
                    root.mopidySingle = false
                }
                playbackPrefsProcess.running = false
            }
        }
        stderr: StdioCollector {}
    }

    Process {
        id: playbackPrefsActionProcess
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            playbackPrefsActionProcess.running = false
            root.refreshPlaybackPrefs()
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
                } catch (e) {
                    root.browseEntries = []
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
            playlistContentMoveProcess.result = null
            playlistContentMoveProcess.running = false
            if (data.ok) {
                if (root.playlistUri) {
                    root.playlistsBusy = true
                    playlistsProcess.command = [Quickshell.shellDir + "/scripts/mopidy/playlists.sh", "items", root.playlistUri]
                    playlistsProcess.running = true
                }
            } else {
                root.showErrorNotice(data.error || "не удалось переместить трек в плейлисте")
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
        interval: 1500
        running: Settings.loaded && Settings.mopidy
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshQueue()
    }

    Timer {
        interval: 1200
        running: Settings.loaded && Settings.mopidy
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshMixer()
    }

    Timer {
        interval: 1200
        running: Settings.loaded && Settings.mopidy
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshPlaybackPrefs()
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
                root.refreshMixer()
                root.refreshPlaybackPrefs()
            } else {
                if (queueProcess.running) queueProcess.running = false
                if (queueActionProcess.running) queueActionProcess.running = false
                if (mixerProcess.running) mixerProcess.running = false
                if (mixerActionProcess.running) mixerActionProcess.running = false
                if (playbackPrefsProcess.running) playbackPrefsProcess.running = false
                if (playbackPrefsActionProcess.running) playbackPrefsActionProcess.running = false
                queueBusy = false
                root.mixerAvailable = false
                root.mopidyVolume = -1
                root.mopidyMuted = false
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
                if (searchProcess.running) searchProcess.running = false
                if (browseProcess.running) browseProcess.running = false
                if (addTrackProcess.running) addTrackProcess.running = false
                if (addFolderProcess.running) addFolderProcess.running = false
                if (playlistsProcess.running) playlistsProcess.running = false
                if (playlistActionProcess.running) playlistActionProcess.running = false
                if (playlistSwitchProcess.running) playlistSwitchProcess.running = false
                if (playlistEditProcess.running) playlistEditProcess.running = false
                if (playlistContentActionProcess.running) playlistContentActionProcess.running = false
                root.playlists = []
                root.playlistItems = []
                root.playlistUri = ""
                root.playlistTitle = ""
                root.libraryMode = "browse"
                root.queueAvailable = false
                root.tracks = []
                root.currentTlid = -1
                root.currentPositionMs = 0
            }
        }
        function onLoadedChanged() {
            if (Settings.loaded && Settings.mopidy) {
                root.refreshQueue()
                root.refreshMixer()
                root.refreshPlaybackPrefs()
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

        Item {
            id: topPanelWrapper
            width: parent.width
            // Keep the layout height at the hidden hotspot height so the
            // expanding icon row overlays the content instead of pushing it.
            height: Config.mopidyHideTopPanel ? Config.mopidyTopPanelOffsetY : (24 + Config.mopidyTopPanelOffsetY)
            z: 100
            clip: false

            readonly property bool topPanelHoverOpen: root.externalTopPanelHover
            readonly property bool topPanelRevealed: !Config.mopidyHideTopPanel || root.externalTopPanelHover

            Rectangle {
                id: topPanelBackground
                x: 0
                y: 0
                width: parent.width
                height: 24
                visible: Config.mopidyHideTopPanel && topPanelWrapper.topPanelRevealed
                color: Config.mopidyTopPanelBackground
                z: 0
            }

            Item {
                id: topPanelRow
                width: parent.width
                height: 24
                visible: topPanelWrapper.topPanelRevealed

                readonly property var normalizedTopIconOrder: root.normalizedTopIconOrder()

                function iconIsVisible(id) {
                    if (id === "stop") return Config.mopidyShowStopIcon && root.queueAvailable && root.tracks.length > 0
                    if (id === "shuffle") return Config.mopidyShowShuffleIcon && root.queueAvailable && root.tracks.length > 0
                    if (id === "repeat") return Config.mopidyShowRepeatIcon && root.queueAvailable && root.tracks.length > 0
                    if (id === "volume") return Config.mopidyShowVolumeIcon && root.queueAvailable && root.tracks.length > 0
                    if (id === "refresh") return Config.mopidyShowRefreshIcon && root.queueAvailable && root.tracks.length > 0
                    if (id === "openAdd") return Config.mopidyShowOpenAddIcon && root.queueAvailable
                    if (id === "clear") return Config.mopidyShowClearIcon && root.queueAvailable && root.tracks.length > 0
                    return false
                }

                function iconWidthFor(id) {
                    return id === "volume" ? (Config.mopidyShowVolumePercent ? 58 : 22) : 22
                }

                function totalIconWidth() {
                    var width = 0
                    var count = 0
                    for (var i = 0; i < normalizedTopIconOrder.length; ++i) {
                        var id = normalizedTopIconOrder[i]
                        if (!iconIsVisible(id)) continue
                        width += iconWidthFor(id)
                        count += 1
                    }
                    return width + Math.max(0, count - 1) * 6
                }

                function iconXFor(id) {
                    var x = parent.width - totalIconWidth()
                    var gapCount = 0
                    for (var i = 0; i < normalizedTopIconOrder.length; ++i) {
                        var current = normalizedTopIconOrder[i]
                        if (!iconIsVisible(current)) continue
                        if (current === id) return x + gapCount * 6
                        x += iconWidthFor(current)
                        gapCount += 1
                    }
                    return x
                }

                readonly property real topIconStartX: parent.width - totalIconWidth()

                Item {
                    visible: Config.mopidyShowQueueTotalDuration && root.queueAvailable && root.tracks.length > 0
                    width: 60
                    height: parent.height
                    x: topPanelRow.topIconStartX - (topPanelRow.totalIconWidth() > 0 ? 66 : 60)

                    Text {
                        width: parent.width
                        height: parent.height
                        x: Config.mopidyQueueDurationX
                        y: Config.mopidyQueueDurationY
                        text: Config.mopidyQueueDurationMode === "remaining" ? root.formatDuration(root.queueRemainingDuration) : root.formatDuration(root.queueTotalDuration)
                        color: Config.mopidyQueueDurationColor
                        font.family: Config.mopidyQueueDurationFont
                        font.pixelSize: Config.mopidyQueueDurationFontSize
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideNone
                    }
                }

                Widgets.MopidyHoverIcon {
                    x: topPanelRow.iconXFor("stop")
                    width: 22; height: parent.height
                    iconText: Config.mopidyStopIcon; iconSize: Config.mopidyStopIconSize; iconX: Config.mopidyStopIconX; iconY: Config.mopidyStopIconY
                    visible: Config.mopidyShowStopIcon && root.queueAvailable && root.tracks.length > 0
                    baseColor: root.queueAvailable && !root.queueBusy ? Config.mopidyControlIconColor : Config.textDisabled
                    enabledState: root.queueAvailable && !root.queueBusy
                    onClicked: root.stopPlayback()
                }

                Widgets.MopidyHoverIcon {
                    x: topPanelRow.iconXFor("shuffle")
                    width: 22; height: parent.height
                    iconText: Config.mopidyShuffleIcon; iconSize: Config.mopidyShuffleIconSize; iconX: Config.mopidyShuffleIconX; iconY: Config.mopidyShuffleIconY
                    visible: Config.mopidyShowShuffleIcon && root.queueAvailable && root.tracks.length > 0
                    baseColor: root.mopidyRandom && root.playbackPrefsAvailable ? Config.accent : (root.playbackPrefsAvailable ? Config.mopidyControlIconColor : Config.textDisabled)
                    enabledState: root.playbackPrefsAvailable
                    onClicked: root.toggleRandom()
                }

                Widgets.MopidyHoverIcon {
                    id: repeatIconButton
                    x: topPanelRow.iconXFor("repeat")
                    width: 22; height: parent.height
                    iconText: Config.mopidyRepeatIcon; iconSize: Config.mopidyRepeatIconSize; iconX: Config.mopidyRepeatIconX; iconY: Config.mopidyRepeatIconY
                    visible: Config.mopidyShowRepeatIcon && root.queueAvailable && root.tracks.length > 0
                    baseColor: root.mopidyRepeat && root.playbackPrefsAvailable ? Config.accent : (root.playbackPrefsAvailable ? Config.mopidyControlIconColor : Config.textDisabled)
                    enabledState: root.playbackPrefsAvailable
                    toolTipText: root.mopidySingle ? "Повтор одного" : (root.mopidyRepeat ? "Повтор всех" : "Повтор выключен")
                    onClicked: root.cycleRepeat()
                }

                Item {
                    id: volumeControl
                    x: topPanelRow.iconXFor("volume")
                    width: Config.mopidyShowVolumePercent ? 58 : 22
                    height: parent.height
                    visible: Config.mopidyShowVolumeIcon && root.queueAvailable && root.tracks.length > 0

                    Rectangle {
                        anchors.fill: parent
                        z: 0
                        radius: 4
                        color: volumeControlMouse.containsMouse && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : Config.transparent
                        border.width: volumeControlMouse.containsMouse && Config.mopidyHoverMode === "frame" ? 1 : 0
                        border.color: Config.mopidyHoverColor
                    }

                    Text {
                        id: volumeIconText
                        z: 1
                        width: 22
                        height: parent.height
                        text: root.mopidyMuted ? Config.mopidyMutedIcon : Config.mopidyVolumeIcon
                        color: root.hoverTextColor(volumeControlMouse.containsMouse, root.mixerAvailable ? Config.mopidyControlIconColor : Config.textDisabled)
                        font.family: Config.font
                        font.pixelSize: root.mopidyMuted ? Config.mopidyMutedIconSize : Config.mopidyVolumeIconSize
                        y: root.mopidyMuted ? Config.mopidyMutedIconY : Config.mopidyVolumeIconY
                        transform: Translate { x: root.mopidyMuted ? Config.mopidyMutedIconX : Config.mopidyVolumeIconX }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        visible: Config.mopidyShowVolumePercent
                        anchors.left: volumeIconText.right
                        anchors.leftMargin: 2
                        width: 32
                        height: parent.height
                        text: root.mopidyVolume >= 0 ? String(root.mopidyVolume) + "%" : "--"
                        color: root.hoverTextColor(volumeControlMouse.containsMouse, root.mixerAvailable ? Config.mopidyControlIconColor : Config.textDisabled)
                        font.family: Config.mopidyDurationFont
                        font.pixelSize: Config.mopidyDurationFontSize
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: volumeControlMouse
                        anchors.fill: parent
                        enabled: root.mixerAvailable && !root.queueBusy
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        hoverEnabled: true
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton)
                                root.toggleMixerMute()
                        }
                        onWheel: function(wheel) {
                            var step = Math.max(1, Number(Config.mopidyVolumeStep))
                            root.adjustMixerVolume(wheel.angleDelta.y > 0 ? step : -step)
                        }
                    }
                }

                Widgets.MopidyHoverIcon {
                    x: topPanelRow.iconXFor("refresh")
                    width: 22; height: parent.height
                    iconText: Config.mopidyRefreshIcon; iconSize: Config.mopidyRefreshIconSize; iconX: Config.mopidyRefreshIconX; iconY: Config.mopidyRefreshIconY
                    visible: Config.mopidyShowRefreshIcon && root.queueAvailable && root.tracks.length > 0
                    baseColor: Config.mopidyControlIconColor
                    enabledState: root.queueAvailable && !root.queueBusy
                    onClicked: root.refreshQueue()
                }

                Widgets.MopidyHoverIcon {
                    x: topPanelRow.iconXFor("openAdd")
                    width: 22; height: parent.height
                    iconText: Config.mopidyOpenAddIcon; iconSize: Config.mopidyOpenAddIconSize; iconX: Config.mopidyOpenAddIconX; iconY: Config.mopidyOpenAddIconY
                    visible: Config.mopidyShowOpenAddIcon && root.queueAvailable
                    baseColor: root.searchOpen ? Config.accent : Config.mopidyControlIconColor
                    enabledState: root.queueAvailable && !root.queueBusy
                    onClicked: root.toggleSearch()
                }

                Widgets.MopidyHoverIcon {
                    x: topPanelRow.iconXFor("clear")
                    width: 22; height: parent.height
                    iconText: Config.mopidyClearIcon; iconSize: Config.mopidyClearIconSize; iconX: Config.mopidyClearIconX; iconY: Config.mopidyClearIconY
                    visible: Config.mopidyShowClearIcon && root.queueAvailable && root.tracks.length > 0
                    baseColor: root.tracks.length && !root.queueBusy ? Config.mopidyControlIconColor : Config.textDisabled
                    enabledState: root.tracks.length > 0 && !root.queueBusy
                    onClicked: root.clearQueue()
                }
            }
        }

        Item {
            width: parent.width
            // Fill all remaining vertical space after the top-panel wrapper.
            // The wrapper height may be negative when Top offset Y is negative;
            // account for that explicitly so it never creates an empty bottom gap.
            height: Math.max(0, parent.height - topPanelWrapper.height - 6)
            clip: true

            Text {
                id: queueStatusText
                anchors.centerIn: parent
                width: Math.min(Config.mopidyStatusWidth, parent.width)
                visible: !root.searchOpen && root.tracks.length === 0
                text: root.queueAvailable ? Config.mopidyEmptyQueueText : Config.mopidyUnavailableText
                color: Config.textMuted
                font.family: Config.mopidyStatusFont
                font.pixelSize: Config.mopidyStatusFontSize
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Config.mopidyStatusLongFontSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
            }

            Column {
                anchors.fill: parent
                spacing: 5
                visible: root.searchOpen

                Row {
                    width: parent.width
                    height: 30
                    spacing: 5

                    Rectangle {
                        width: 72
                        height: 30
                        radius: 4
                        color: browseTabMouse.containsMouse && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : (root.libraryMode === "browse" ? Config.activeNetworkBackground : Config.settingsBackground)
                        border.color: browseTabMouse.containsMouse && Config.mopidyHoverMode === "frame" ? Config.mopidyHoverColor : (root.libraryMode === "browse" ? Config.accent : Config.baseColor)
                        border.width: 1

                        Text {
                            anchors.fill: parent
                            text: "Папки"
                            color: root.hoverTextColor(browseTabMouse.containsMouse, Config.text)
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        MouseArea {
                            id: browseTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.libraryMode !== "browse" && !root.browseBusy
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showBrowse()
                        }
                    }

                    Rectangle {
                        width: 82
                        height: 30
                        radius: 4
                        color: playlistsTabMouse.containsMouse && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : (root.libraryMode === "playlists" || root.libraryMode === "playlistItems" ? Config.activeNetworkBackground : Config.settingsBackground)
                        border.color: playlistsTabMouse.containsMouse && Config.mopidyHoverMode === "frame" ? Config.mopidyHoverColor : (root.libraryMode === "playlists" || root.libraryMode === "playlistItems" ? Config.accent : Config.baseColor)
                        border.width: 1

                        Text {
                            anchors.fill: parent
                            text: "Плейлисты"
                            color: root.hoverTextColor(playlistsTabMouse.containsMouse, Config.text)
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        MouseArea {
                            id: playlistsTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.playlistsBusy
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showPlaylists()
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 30
                        radius: 4
                        color: searchTabMouse.containsMouse && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : (root.libraryMode === "search" ? Config.activeNetworkBackground : Config.settingsBackground)
                        border.color: searchTabMouse.containsMouse && Config.mopidyHoverMode === "frame" ? Config.mopidyHoverColor : (root.libraryMode === "search" ? Config.accent : Config.baseColor)
                        border.width: 1

                        Text {
                            anchors.fill: parent
                            text: "Поиск"
                            color: root.hoverTextColor(searchTabMouse.containsMouse, Config.text)
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        MouseArea {
                            id: searchTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.libraryMode !== "search"
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showSearch()
                        }
                    }

                    Item { width: Math.max(0, parent.width - 236); height: 1 }

                    Text {
                        width: 32
                        height: 30
                        visible: (root.libraryMode === "browse" && root.browseStack.length > 0) || (root.libraryMode === "playlistItems")
                        text: "‹"
                        color: root.hoverTextColor(backLibraryMouse.containsMouse, (root.browseBusy || root.playlistsBusy) ? Config.textDisabled : Config.mopidyControlIconColor)
                        font.family: Config.font
                        font.pixelSize: 22
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            id: backLibraryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.browseBusy && !root.playlistsBusy
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.libraryMode === "playlistItems" ? root.backToPlaylists() : root.browseBack()
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(0, parent.height - 35)
                    visible: root.libraryMode === "browse"

                    Column {
                        anchors.fill: parent
                        spacing: 4

                        Text {
                            width: parent.width
                            height: 22
                            text: root.browseBusy ? "Загрузка…" : root.browseTitle
                            color: Config.accent
                            font.family: Config.mopidyAlbumFont
                            font.pixelSize: Config.mopidyAlbumFontSize
                            font.bold: Config.mopidyAlbumBold
                            elide: Text.ElideRight
                        }

                        ListView {
                            width: parent.width
                            height: Math.max(0, parent.height - 26)
                            clip: true
                            spacing: 2
                            model: root.browseDisplayEntries
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                width: parent ? parent.width : 0
                                height: 38
                                radius: 4
                                property bool addButtonVisible: Config.mopidyShowAddIcon && (modelData.type === "directory" || modelData.type === "track")
                                property bool rowHovered: browseMouse.containsMouse
                                color: Config.transparent

                                Rectangle {
                                    id: browseHoverFrame
                                    x: addButtonVisible ? 33 : 0
                                    y: 0
                                    width: Math.max(0, parent.width - x)
                                    height: parent.height
                                    radius: 4
                                    color: rowHovered && modelData.type !== "parent" ? root.hoverBackgroundColor(true) : Config.transparent
                                    border.width: rowHovered && modelData.type !== "parent" ? root.hoverBorderWidth(true) : 0
                                    border.color: root.hoverBorderColor(rowHovered && modelData.type !== "parent")
                                    z: 0
                                }

                                Text {
                                    id: browseIcon
                                    z: 1
                                    x: 34
                                    width: 28
                                    height: parent.height
                                    text: modelData.type === "parent" ? "" : (modelData.type === "directory" ? "" : "")
                                    color: root.hoverTextColor(rowHovered && modelData.type !== "parent", modelData.type === "parent" || modelData.type === "directory" ? Config.accent : Config.textMuted)
                                    font.family: Config.font
                                    font.pixelSize: Config.fontSize
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    x: modelData.type === "parent" ? 66 : (addButtonVisible ? 66 : 38)
                                    z: 1
                                    width: Math.max(0, parent.width - x - 5)
                                    height: parent.height
                                    text: modelData.name || "Без названия"
                                    color: root.hoverTextColor(rowHovered && modelData.type !== "parent", Config.text)
                                    font.family: modelData.type === "parent" || modelData.type === "directory" ? Config.mopidyAlbumFont : Config.mopidyTrackFont
                                    font.pixelSize: modelData.type === "parent" || modelData.type === "directory" ? Config.mopidyAlbumFontSize : Config.mopidyTrackFontSize
                                    font.bold: modelData.type === "parent" || modelData.type === "directory" ? Config.mopidyAlbumBold : false
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Rectangle {
                                    id: browseAddButton
                                    z: 2
                                    visible: addButtonVisible
                                    x: 1
                                    y: 1
                                    width: 30
                                    height: parent.height - 2
                                    radius: 3
                                    color: root.hoverBackgroundColor(browseAddMouse.containsMouse)
                                    border.width: root.hoverBorderWidth(browseAddMouse.containsMouse)
                                    border.color: root.hoverBorderColor(browseAddMouse.containsMouse)

                                    Text {
                                        x: (parent.width - width) / 2 + Config.mopidyAddIconX
                                        y: (parent.height - height) / 2 + Config.mopidyAddIconY
                                        width: Math.max(1, implicitWidth)
                                        height: Math.max(1, implicitHeight)
                                        text: Config.mopidyAddIcon
                                        color: root.hoverTextColor(browseAddMouse.containsMouse, Config.mopidyControlIconColor)
                                        font.family: Config.font
                                        font.pixelSize: Config.mopidyAddIconSize
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    MouseArea {
                                        id: browseAddMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.type === "directory")
                                                root.addBrowseFolder(modelData.uri, modelData.name)
                                            else if (modelData.type === "track")
                                                root.addSearchResult(modelData.uri, modelData.name)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: browseMouse
                                    x: addButtonVisible ? 33 : 0
                                    hoverEnabled: true
                                    y: 0
                                    width: Math.max(0, parent.width - x)
                                    height: parent.height
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    onClicked: function(mouse) {
                                        if (modelData.type === "parent") {
                                            if (mouse.button === Qt.LeftButton)
                                                root.browseBack()
                                            return
                                        }
                                        if (modelData.type === "directory") {
                                            if (mouse.button === Qt.LeftButton)
                                                root.browseUriAt(modelData.uri, modelData.name)
                                            else if (mouse.button === Qt.RightButton)
                                                root.addBrowseFolder(modelData.uri, modelData.name)
                                            return
                                        }
                                        if (modelData.type === "track" && mouse.button === Qt.RightButton)
                                            root.addSearchResult(modelData.uri, modelData.name)
                                    }
                                }
                            }
                        }
                    }

                }

                Text {
                    width: parent.width
                    height: parent.height
                    visible: root.libraryMode === "browse" && !root.browseBusy && root.browseEntries.length === 0
                    text: "Папка пуста"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Column {
                    width: parent.width
                    height: Math.max(0, parent.height - 35)
                    spacing: 5
                    visible: root.libraryMode === "playlists"

                    Row {
                        width: parent.width
                        height: 22
                        spacing: 4

                        Text {
                            width: Math.max(0, parent.width - 28)
                            height: parent.height
                            text: root.playlistsBusy ? "Загрузка…" : "Плейлисты"
                            color: Config.accent
                            font.family: Config.mopidyAlbumFont
                            font.pixelSize: Config.mopidyAlbumFontSize
                            font.bold: Config.mopidyAlbumBold
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            width: 24; height: parent.height; radius: 3
                            color: root.hoverBackgroundColor(playlistCreateMouse.containsMouse)
                            border.width: root.hoverBorderWidth(playlistCreateMouse.containsMouse)
                            border.color: root.hoverBorderColor(playlistCreateMouse.containsMouse)
                            Text { anchors.fill: parent; text: "+"; color: root.hoverTextColor(playlistCreateMouse.containsMouse, Config.mopidyControlIconColor); font.family: Config.font; font.pixelSize: Config.mopidyAddIconSize; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            MouseArea { id: playlistCreateMouse; anchors.fill: parent; enabled: !root.playlistsBusy; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openCreatePlaylistDialog() }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: Math.max(0, parent.height - 26)
                        clip: true
                        spacing: 2
                        model: root.playlists
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 38
                            radius: 4
                            property bool addButtonVisible: Config.mopidyShowAddIcon
                            property bool switchButtonVisible: Config.mopidyShowSwitchPlaylistIcon
                            property int leftButtonCount: (addButtonVisible ? 1 : 0) + (switchButtonVisible ? 1 : 0)
                            property int leftButtonsWidth: leftButtonCount * 33
                            color: Config.transparent

                            Rectangle {
                                id: playlistHoverFrame
                                x: leftButtonsWidth
                                y: 0
                                width: Math.max(0, parent.width - x)
                                height: parent.height
                                radius: 4
                                color: root.hoverBackgroundColor(playlistMouse.containsMouse)
                                border.width: root.hoverBorderWidth(playlistMouse.containsMouse)
                                border.color: root.hoverBorderColor(playlistMouse.containsMouse)
                                z: 0
                            }

                            Text {
                                x: leftButtonCount > 0 ? leftButtonsWidth + 5 : 5
                                z: 1
                                width: Math.max(0, parent.width - x - (Config.mopidyShowPlaylistDeleteIcon ? 38 : 5))
                                height: parent.height
                                text: modelData.name || "Без названия"
                                color: root.hoverTextColor(playlistMouse.containsMouse, Config.text)
                                font.family: Config.mopidyTrackFont
                                font.pixelSize: Config.mopidyTrackFontSize
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                id: playlistListDeleteButton
                                z: 3
                                visible: Config.mopidyShowPlaylistDeleteIcon
                                x: parent.width - 31
                                y: 1
                                width: 30
                                height: parent.height - 2
                                radius: 3
                                color: root.hoverBackgroundColor(playlistListDeleteMouse.containsMouse)
                                border.width: root.hoverBorderWidth(playlistListDeleteMouse.containsMouse)
                                border.color: root.hoverBorderColor(playlistListDeleteMouse.containsMouse)

                                Text {
                                    x: (parent.width - width) / 2 + Config.mopidyPlaylistDeleteIconX
                                    y: (parent.height - height) / 2 + Config.mopidyPlaylistDeleteIconY
                                    width: Math.max(1, implicitWidth)
                                    height: Math.max(1, implicitHeight)
                                    text: Config.mopidyPlaylistDeleteIcon
                                    color: root.playlistDeleteIconColor(playlistListDeleteMouse.containsMouse)
                                    font.family: Config.font
                                    font.pixelSize: Config.mopidyPlaylistDeleteIconSize
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: playlistListDeleteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openDeletePlaylistFromListDialog(modelData.uri, modelData.name)
                                }
                            }

                            Rectangle {
                                id: playlistSwitchButton
                                z: 2
                                visible: switchButtonVisible
                                x: 1
                                y: 1
                                width: 30
                                height: parent.height - 2
                                radius: 3
                                color: root.hoverBackgroundColor(playlistSwitchMouse.containsMouse)
                                border.width: root.hoverBorderWidth(playlistSwitchMouse.containsMouse)
                                border.color: root.hoverBorderColor(playlistSwitchMouse.containsMouse)

                                Text {
                                    x: (parent.width - width) / 2 + Config.mopidySwitchPlaylistIconX
                                    y: (parent.height - height) / 2 + Config.mopidySwitchPlaylistIconY
                                    width: Math.max(1, implicitWidth)
                                    height: Math.max(1, implicitHeight)
                                    text: Config.mopidySwitchPlaylistIcon
                                    color: root.hoverTextColor(playlistSwitchMouse.containsMouse, Config.mopidyControlIconColor)
                                    font.family: Config.font
                                    font.pixelSize: Config.mopidySwitchPlaylistIconSize
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: playlistSwitchMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.switchPlaylist(modelData.uri, modelData.name)
                                }
                            }

                            Rectangle {
                                id: playlistAddButton
                                z: 2
                                visible: addButtonVisible
                                x: switchButtonVisible ? 34 : 1
                                y: 1
                                width: 30
                                height: parent.height - 2
                                radius: 3
                                color: root.hoverBackgroundColor(playlistAddMouse.containsMouse)
                                border.width: root.hoverBorderWidth(playlistAddMouse.containsMouse)
                                border.color: root.hoverBorderColor(playlistAddMouse.containsMouse)

                                Text {
                                    x: (parent.width - width) / 2 + Config.mopidyAddIconX
                                    y: (parent.height - height) / 2 + Config.mopidyAddIconY
                                    width: Math.max(1, implicitWidth)
                                    height: Math.max(1, implicitHeight)
                                    text: Config.mopidyAddIcon
                                    color: root.hoverTextColor(playlistAddMouse.containsMouse, Config.mopidyControlIconColor)
                                    font.family: Config.font
                                    font.pixelSize: Config.mopidyAddIconSize
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: playlistAddMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.addPlaylist(modelData.uri, modelData.name)
                                }
                            }

                            MouseArea {
                                id: playlistMouse
                                x: leftButtonsWidth
                                y: 0
                                width: Math.max(0, parent.width - x - (Config.mopidyShowPlaylistDeleteIcon ? 33 : 0))
                                height: parent.height
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.MiddleButton)
                                        root.openDeletePlaylistFromListDialog(modelData.uri, modelData.name)
                                    else if (mouse.button === Qt.RightButton)
                                        root.addPlaylist(modelData.uri, modelData.name)
                                    else
                                        root.openPlaylist(modelData.uri, modelData.name)
                                }
                            }
                        }
                    }

                }

                Text {
                    width: parent.width
                    height: parent.height
                    visible: root.libraryMode === "playlists" && !root.playlistsBusy && root.playlists.length === 0
                    text: "Плейлистов нет"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Column {
                    width: parent.width
                    height: Math.max(0, parent.height - 35)
                    spacing: 5
                    visible: root.libraryMode === "playlistItems"

                    Row {
                        width: parent.width
                        height: 22
                        spacing: 4

                        Text {
                            width: Math.max(0, parent.width - 56)
                            height: parent.height
                            text: root.playlistsBusy ? "Загрузка…" : root.playlistTitle
                            color: Config.accent
                            font.family: Config.mopidyAlbumFont
                            font.pixelSize: Config.mopidyAlbumFontSize
                            font.bold: Config.mopidyAlbumBold
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            width: 24; height: parent.height; radius: 3
                            color: root.hoverBackgroundColor(playlistAddTracksMouse.containsMouse)
                            border.width: root.hoverBorderWidth(playlistAddTracksMouse.containsMouse)
                            border.color: root.hoverBorderColor(playlistAddTracksMouse.containsMouse)
                            Text { anchors.fill: parent; text: Config.mopidyAddIcon; color: root.hoverTextColor(playlistAddTracksMouse.containsMouse, Config.mopidyControlIconColor); font.family: Config.font; font.pixelSize: Config.mopidyAddIconSize; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            MouseArea { id: playlistAddTracksMouse; anchors.fill: parent; enabled: !root.playlistsBusy && !!root.playlistUri && !root.addingToPlaylist; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openPlaylistAddMode() }
                        }

                        Rectangle {
                            width: 24; height: parent.height; radius: 3
                            color: root.hoverBackgroundColor(playlistRenameMouse.containsMouse)
                            border.width: root.hoverBorderWidth(playlistRenameMouse.containsMouse)
                            border.color: root.hoverBorderColor(playlistRenameMouse.containsMouse)
                            Text { anchors.fill: parent; text: ""; color: root.hoverTextColor(playlistRenameMouse.containsMouse, Config.mopidyControlIconColor); font.family: Config.font; font.pixelSize: Config.fontSize; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            MouseArea { id: playlistRenameMouse; anchors.fill: parent; enabled: !root.playlistsBusy && !!root.playlistUri; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openRenamePlaylistDialog() }
                        }

                        Rectangle {
                            width: 24; height: parent.height; radius: 3
                            color: root.hoverBackgroundColor(playlistDeleteMouse.containsMouse)
                            border.width: root.hoverBorderWidth(playlistDeleteMouse.containsMouse)
                            border.color: root.hoverBorderColor(playlistDeleteMouse.containsMouse)
                            Text { anchors.fill: parent; text: ""; color: root.hoverTextColor(playlistDeleteMouse.containsMouse, Config.mopidyControlIconColor); font.family: Config.font; font.pixelSize: Config.fontSize; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            MouseArea { id: playlistDeleteMouse; anchors.fill: parent; enabled: !root.playlistsBusy && !!root.playlistUri; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.openDeletePlaylistDialog() }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: Math.max(0, parent.height - 26)
                        clip: true
                        spacing: 2
                        model: root.playlistItems
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 38
                            radius: 4
                            color: root.hoverBackgroundColor(playlistItemMouse.containsMouse)
                            border.width: root.hoverBorderWidth(playlistItemMouse.containsMouse)
                            border.color: root.hoverBorderColor(playlistItemMouse.containsMouse)

                            readonly property int playlistMoveWidth: (Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? 42 : 0
                            readonly property int playlistDeleteWidth: Config.mopidyShowPlaylistDeleteIcon ? 33 : 0

                            Text {
                                x: 5
                                width: Math.max(0, parent.width - 5 - playlistMoveWidth - playlistDeleteWidth - 43)
                                height: parent.height
                                text: modelData.name || "Без названия"
                                color: root.hoverTextColor(playlistItemMouse.containsMouse, Config.text)
                                font.family: Config.mopidyTrackFont
                                font.pixelSize: Config.mopidyTrackFontSize
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                readonly property int rightControlGap: (Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? 2 : (Config.mopidyShowPlaylistDeleteIcon ? 2 : 0)
                                anchors.right: (Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? playlistContentMoveButtons.left : (Config.mopidyShowPlaylistDeleteIcon ? playlistContentDeleteButton.left : parent.right)
                                anchors.rightMargin: 1 + rightControlGap
                                anchors.verticalCenter: parent.verticalCenter
                                width: 38
                                text: root.formatDuration(modelData.duration)
                                color: root.hoverTextColor(playlistItemMouse.containsMouse, Config.textMuted)
                                font.family: Config.mopidyDurationFont
                                font.pixelSize: Config.mopidyDurationFontSize
                                horizontalAlignment: Text.AlignRight
                            }

                            Item {
                                id: playlistContentMoveButtons
                                visible: Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon
                                anchors.right: Config.mopidyShowPlaylistDeleteIcon ? playlistContentDeleteButton.left : parent.right
                                anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 42
                                height: parent.height
                            }

                            Primitives.MoveArrowButton {
                                id: playlistContentMoveUpIconButton
                                z: 4
                                width: 22
                                height: 22
                                x: playlistContentMoveButtons.x + Config.mopidyMoveUpIconX
                                y: Math.round((parent.height - height) / 2) + Config.mopidyMoveUpIconY
                                iconText: index > 0 ? Config.mopidyMoveUpIcon : ""
                                iconSize: Config.mopidyMoveUpIconSize
                                visible: index > 0 && Config.mopidyShowMoveUpIcon
                                baseColor: Config.textMuted
                                hoverMode: Config.mopidyHoverMode
                                hoverColor: Config.mopidyHoverColor
                                interactionEnabled: visible && !root.playlistsBusy && !playlistContentMoveProcess.running
                                onClicked: root.movePlaylistItem(index, index - 1, modelData.name)
                            }

                            Primitives.MoveArrowButton {
                                id: playlistContentMoveDownIconButton
                                z: 4
                                width: 22
                                height: 22
                                x: playlistContentMoveButtons.x + 21 + Config.mopidyMoveDownIconX
                                y: Math.round((parent.height - height) / 2) + Config.mopidyMoveDownIconY
                                iconText: index < root.playlistItems.length - 1 ? Config.mopidyMoveDownIcon : ""
                                iconSize: Config.mopidyMoveDownIconSize
                                visible: index < root.playlistItems.length - 1 && Config.mopidyShowMoveDownIcon
                                baseColor: Config.textMuted
                                hoverMode: Config.mopidyHoverMode
                                hoverColor: Config.mopidyHoverColor
                                interactionEnabled: visible && !root.playlistsBusy && !playlistContentMoveProcess.running
                                onClicked: root.movePlaylistItem(index, index + 1, modelData.name)
                            }

                            Rectangle {
                                id: playlistContentDeleteButton
                                z: 3
                                visible: Config.mopidyShowPlaylistDeleteIcon
                                x: parent.width - 31
                                y: 1
                                width: 30
                                height: parent.height - 2
                                radius: 3
                                color: root.hoverBackgroundColor(playlistContentDeleteMouse.containsMouse)
                                border.width: root.hoverBorderWidth(playlistContentDeleteMouse.containsMouse)
                                border.color: root.hoverBorderColor(playlistContentDeleteMouse.containsMouse)

                                Text {
                                    x: (parent.width - width) / 2 + Config.mopidyPlaylistDeleteIconX
                                    y: (parent.height - height) / 2 + Config.mopidyPlaylistDeleteIconY
                                    width: Math.max(1, implicitWidth)
                                    height: Math.max(1, implicitHeight)
                                    text: Config.mopidyPlaylistDeleteIcon
                                    color: root.playlistDeleteIconColor(playlistContentDeleteMouse.containsMouse)
                                    font.family: Config.font
                                    font.pixelSize: Config.mopidyPlaylistDeleteIconSize
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: playlistContentDeleteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.removePlaylistItem(index, modelData.name)
                                }
                            }

                            MouseArea {
                                id: playlistItemMouse
                                x: 0
                                y: 0
                                width: Math.max(0, parent.width - (Config.mopidyShowPlaylistDeleteIcon ? 33 : 0) - ((Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? 42 : 0))
                                height: parent.height
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.MiddleButton) {
                                        root.removePlaylistItem(index, modelData.name)
                                        return
                                    }
                                    if (mouse.button === Qt.RightButton || mouse.button === Qt.LeftButton)
                                        root.addPlaylistItem(modelData.uri, modelData.name)
                                }
                            }
                        }
                    }

                }

                Rectangle {
                    id: emptyPlaylistArea
                    width: parent.width
                    height: parent.height
                    z: 50
                    visible: root.libraryMode === "playlistItems" && !root.playlistsBusy && root.playlistItems.length === 0
                    objectName: "mopidyEmptyPlaylistArea"
                    MouseArea {
                        id: emptyPlaylistClickArea
                        anchors.fill: parent
                        enabled: !root.playlistsBusy && !!root.playlistUri
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openPlaylistAddMode()
                    }
                    color: root.hoverBackgroundColor(emptyPlaylistHover.containsMouse)
                    border.width: root.hoverBorderWidth(emptyPlaylistHover.containsMouse)
                    border.color: root.hoverBorderColor(emptyPlaylistHover.containsMouse)
                    radius: 4

                    Text {
                        anchors.fill: parent
                        text: "Плейлист пуст"
                        color: root.hoverTextColor(emptyPlaylistHover.containsMouse, Config.textMuted)
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        enabled: false
                    }

                    HoverHandler {
                        id: emptyPlaylistHover
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    }
                }

                Column {
                    width: parent.width
                    height: Math.max(0, parent.height - 35)
                    spacing: 5
                    visible: root.libraryMode === "search"

                    Row {
                        width: parent.width
                        height: 30
                        spacing: 5

                        TextField {
                            id: searchField
                            width: parent.width - 42
                            height: 30
                            text: root.searchQuery
                            color: Config.text
                            placeholderText: "Поиск в Mopidy…"
                            placeholderTextColor: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                            selectByMouse: true
                            background: Rectangle {
                                color: Config.settingsBackground
                                border.color: searchField.activeFocus ? Config.accent : Config.baseColor
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: root.searchQuery = text
                            onAccepted: root.searchLibrary()
                        }

                        Text {
                            width: 37
                            height: 30
                            text: root.searchBusy ? "…" : Config.mopidyRefreshIcon
                            color: root.searchBusy ? Config.textMuted : Config.mopidyControlIconColor
                            font.family: Config.font
                            font.pixelSize: Config.mopidyRefreshIconSize
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            MouseArea {
                                anchors.fill: parent
                                enabled: !root.searchBusy
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.searchLibrary()
                            }
                        }
                    }

                    ListView {
                        width: parent.width
                        height: Math.max(0, parent.height - 35)
                        clip: true
                        spacing: 2
                        model: root.searchResults
                        visible: root.searchResults.length > 0
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 38
                            radius: 4
                            color: root.hoverBackgroundColor(resultMouse.containsMouse)
                            border.width: root.hoverBorderWidth(resultMouse.containsMouse)
                            border.color: root.hoverBorderColor(resultMouse.containsMouse)

                            Column {
                                x: 5
                                width: Math.max(0, parent.width - 55)
                                height: parent.height

                                Text {
                                    width: parent.width
                                    height: 18
                                    text: modelData.name || "Без названия"
                                    color: Config.text
                                    font.family: Config.mopidyTrackFont
                                    font.pixelSize: Config.mopidyTrackFontSize
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    height: 14
                                    text: [modelData.artist || "", modelData.album || ""].filter(function(v) { return !!v }).join(" · ")
                                    color: Config.textMuted
                                    font.family: Config.mopidyArtistFont
                                    font.pixelSize: Config.mopidyArtistFontSize
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                width: 45
                                anchors.right: parent.right
                                anchors.rightMargin: 1
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.formatDuration(modelData.duration)
                                color: root.hoverTextColor(resultMouse.containsMouse, Config.textMuted)
                                font.family: Config.mopidyDurationFont
                                font.pixelSize: Config.mopidyDurationFontSize
                                horizontalAlignment: Text.AlignRight
                            }

                            MouseArea {
                                id: resultMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton)
                                        root.addSearchResult(modelData.uri, modelData.name)
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        height: Math.max(0, parent.height - 35)
                        visible: !root.searchBusy && root.searchQuery.trim().length > 0 && root.searchResults.length === 0
                        text: "Ничего не найдено"
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            ListView {
                id: queueView
                anchors.fill: parent
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
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

            Component {
                id: albumHeaderComponent

                Rectangle {
                    property var itemData: parent ? parent.itemData : null
                    property bool stickyHeader: parent ? parent.stickyHeader === true : false
                    width: queueView.width
                    height: Math.max(26, Config.mopidyAlbumFontSize + 9)
                    property bool albumHovered: albumMouse.containsMouse
                    color: stickyHeader ? Config.mopidyBackground : root.hoverBackgroundColor(albumHovered)
                    border.width: Config.mopidyAlbumSeparator === "frame" ? 1 : root.hoverBorderWidth(albumHovered)
                    border.color: albumHovered && Config.mopidyHoverMode === "frame" ? Config.mopidyHoverColor : Config.accent
                    radius: Config.mopidyAlbumSeparator === "frame" || root.hoverBorderWidth(albumHovered) > 0 ? 3 : 0

                    Text {
                        id: albumTitleText
                        x: 5
                        width: Math.min(implicitWidth, Math.max(0, parent.width - albumDurationText.implicitWidth - (Config.mopidyAlbumSeparator === "none" ? 5 : 20)))
                        anchors.verticalCenter: parent.verticalCenter
                        text: itemData ? ((itemData.albumYear ? itemData.albumYear + " - " : "") + (itemData.album || "")) : ""
                        color: root.hoverTextColor(albumHovered, Config.accent)
                        font.family: Config.mopidyAlbumFont
                        font.pixelSize: Config.mopidyAlbumFontSize
                        font.bold: Config.mopidyAlbumBold
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: albumSeparator
                        property bool isBetween: Config.mopidyAlbumSeparator === "between-line"
                        property bool isUnder: Config.mopidyAlbumSeparator === "under-line"
                        visible: isBetween || isUnder
                        x: isBetween
                            ? albumTitleText.x + albumTitleText.width + 4
                            : albumTitleText.x
                        y: isBetween
                            ? Math.round((parent.height - 1) / 2)
                            : parent.height - 2
                        width: isBetween
                            ? Math.max(0, albumDurationText.x - (albumTitleText.x + albumTitleText.width + 8))
                            : Math.max(0, albumDurationText.x + albumDurationText.width - albumTitleText.x)
                        height: 1
                        color: root.hoverTextColor(albumHovered, Config.accent)
                        opacity: 0.65
                    }

                    Text {
                        id: albumDurationText
                        width: 60
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.formatDuration(root.albumDisplayDuration(itemData))
                        color: root.hoverTextColor(albumHovered, Config.accent)
                        font.family: Config.mopidyDurationFont
                        font.pixelSize: Config.mopidyDurationFontSize
                        font.bold: Config.mopidyAlbumBold
                        horizontalAlignment: Text.AlignRight
                    }

                    MouseArea {
                        id: albumMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.MiddleButton)
                                root.removeAlbum(itemData.tlids)
                        }
                    }
                }
            }

            Component {
                id: trackRowComponent

                Rectangle {
                    id: trackRow
                    width: queueView.width
                    height: 38
                    radius: 4
                    color: rowMouse.containsMouse ? root.hoverBackgroundColor(true) : Config.transparent
                    border.width: root.hoverBorderWidth(rowMouse.containsMouse)
                    border.color: root.hoverBorderColor(rowMouse.containsMouse)

                    readonly property int actionWidth: (Config.mopidyShowMoveUpIcon || Config.mopidyShowMoveDownIcon) ? 42 : 0
                    readonly property int numberWidth: Config.mopidyShowTrackNumbers ? 18 : 0
                    readonly property int durationWidth: 38

                    Row {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5

                        Text {
                            width: trackRow.numberWidth
                            height: parent.height
                            visible: Config.mopidyShowTrackNumbers
                            text: Number(itemData.track.tlid) === root.currentTlid ? "▶" : String(itemData.queueIndex + 1)
                            color: Number(itemData.track.tlid) === root.currentTlid ? Config.accent : root.hoverTextColor(rowMouse.containsMouse, Config.textMuted)
                            font.family: Config.font
                            font.pixelSize: Config.fontSize
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Item {
                            width: parent.width - trackRow.numberWidth - trackRow.durationWidth - trackRow.actionWidth - 15
                            height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: itemData.track.artist ? 2 : 0

                            Text {
                                id: trackTitleText
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                height: itemData.track.artist ? 16 : parent.height
                                text: itemData.track.name || "Без названия"
                                color: Number(itemData.track.tlid) === root.currentTlid ? Config.accent : root.hoverTextColor(rowMouse.containsMouse, Config.text)
                                font.family: Config.mopidyTrackFont
                                font.pixelSize: Config.mopidyTrackFontSize
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                id: trackArtistText
                                visible: !!itemData.track.artist
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 12
                                text: itemData.track.artist || ""
                                color: Number(itemData.track.tlid) === root.currentTlid ? Config.accent : root.hoverTextColor(rowMouse.containsMouse, Config.textMuted)
                                font.family: Config.mopidyArtistFont
                                font.pixelSize: Config.mopidyArtistFontSize
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Item {
                            width: trackRow.durationWidth
                            height: parent.height
                        }
                    }

                    Text {
                        id: trackDurationText
                        z: 3
                        width: trackRow.durationWidth
                        height: 28
                        x: trackRow.width - width - 5
                        y: Math.round((trackRow.height - height) / 2)
                        text: root.formatDuration(root.trackDisplayDuration(itemData.track))
                        color: Number(itemData.track.tlid) === root.currentTlid ? Config.accent : root.hoverTextColor(rowMouse.containsMouse, Config.textMuted)
                        font.family: Config.mopidyDurationFont
                        font.pixelSize: Config.mopidyDurationFontSize
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Primitives.MoveArrowButton {
                        id: queueMoveUpIconButton
                        z: 4
                        width: 22
                        height: 22
                        x: trackRow.width - trackRow.durationWidth - 27 + Config.mopidyMoveUpIconX
                        y: Math.round((trackRow.height - height) / 2) + Config.mopidyMoveUpIconY
                        iconText: itemData.queueIndex > 0 ? Config.mopidyMoveUpIcon : ""
                        iconSize: Config.mopidyMoveUpIconSize
                        visible: itemData.queueIndex > 0 && Config.mopidyShowMoveUpIcon
                        baseColor: Config.textMuted
                        hoverMode: Config.mopidyHoverMode
                        hoverColor: Config.mopidyHoverColor
                        interactionEnabled: visible && !root.queueBusy
                        onClicked: root.moveTrack(Number(itemData.track.tlid), itemData.queueIndex - 1)
                    }

                    Primitives.MoveArrowButton {
                        id: queueMoveDownIconButton
                        z: 4
                        width: 22
                        height: 22
                        x: trackRow.width - trackRow.durationWidth - 5 + Config.mopidyMoveDownIconX
                        y: Math.round((trackRow.height - height) / 2) + Config.mopidyMoveDownIconY
                        iconText: itemData.queueIndex < root.tracks.length - 1 ? Config.mopidyMoveDownIcon : ""
                        iconSize: Config.mopidyMoveDownIconSize
                        visible: itemData.queueIndex < root.tracks.length - 1 && Config.mopidyShowMoveDownIcon
                        baseColor: Config.textMuted
                        hoverMode: Config.mopidyHoverMode
                        hoverColor: Config.mopidyHoverColor
                        interactionEnabled: visible && !root.queueBusy
                        onClicked: root.moveTrack(Number(itemData.track.tlid), itemData.queueIndex + 1)
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        anchors.rightMargin: trackRow.actionWidth
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.MiddleButton)
                                root.removeTrack(Number(itemData.track.tlid))
                            else if (mouse.button === Qt.LeftButton)
                                root.playTrack(Number(itemData.track.tlid))
                        }
                    }
                }
            }

        }
    }

    Rectangle {
        id: playlistDialogOverlay
        z: 200
        anchors.fill: parent
        visible: root.playlistDialogVisible
        color: "#88000000"

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Rectangle {
            width: Math.min(parent.width - 20, 280)
            height: root.playlistDialogMode === "delete" ? 88 : 104
            anchors.centerIn: parent
            radius: 5
            color: Config.settingsBackground
            border.width: 1
            border.color: Config.baseColor

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 7

                Text {
                    width: parent.width
                    height: 18
                    text: root.playlistDialogMode === "create" ? "Новый плейлист" : (root.playlistDialogMode === "rename" ? "Переименовать плейлист" : "Удалить плейлист")
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    font.bold: true
                    elide: Text.ElideRight
                }

                TextField {
                    id: playlistDialogField
                    width: parent.width
                    height: 30
                    visible: root.playlistDialogMode !== "delete"
                    text: root.playlistDialogInput
                    color: Config.text
                    placeholderText: "Название"
                    placeholderTextColor: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    selectByMouse: true
                    onTextChanged: root.playlistDialogInput = text
                    onAccepted: root.submitPlaylistDialog()
                    background: Rectangle {
                        color: Config.settingsBackground
                        border.color: playlistDialogField.activeFocus ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: 4
                    }
                    Keys.onEscapePressed: root.closePlaylistDialog()
                }

                Text {
                    width: parent.width
                    height: 26
                    visible: root.playlistDialogMode === "delete"
                    text: "Удалить «" + root.playlistManageTitle + "»?"
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width
                    height: 16
                    visible: !!root.playlistDialogError
                    text: root.playlistDialogError
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(9)
                    elide: Text.ElideRight
                }

                Row {
                    width: parent.width
                    height: 28
                    spacing: 6

                    Item { width: Math.max(0, parent.width - 118); height: 1 }

                    Rectangle {
                        width: 56
                        height: 28
                        radius: 4
                        color: playlistCancelMouse.containsMouse && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : Config.settingsBackground
                        border.color: playlistCancelMouse.containsMouse && Config.mopidyHoverMode === "frame" ? Config.mopidyHoverColor : Config.baseColor
                        border.width: 1
                        Text { anchors.fill: parent; text: "Отмена"; color: root.hoverTextColor(playlistCancelMouse.containsMouse, Config.text); font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        MouseArea { id: playlistCancelMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closePlaylistDialog() }
                    }

                    Rectangle {
                        width: 56
                        height: 28
                        radius: 4
                        color: playlistConfirmMouse.containsMouse && Config.mopidyHoverMode === "background" ? Config.mopidyHoverColor : Config.settingsBackground
                        border.color: playlistConfirmMouse.containsMouse && Config.mopidyHoverMode === "frame" ? Config.mopidyHoverColor : Config.accent
                        border.width: 1
                        Text { anchors.fill: parent; text: root.playlistDialogMode === "create" ? "Создать" : (root.playlistDialogMode === "rename" ? "Сохранить" : "Удалить"); color: root.hoverTextColor(playlistConfirmMouse.containsMouse, Config.text); font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        MouseArea { id: playlistConfirmMouse; anchors.fill: parent; enabled: !playlistManageProcess.running; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.submitPlaylistDialog() }
                    }
                }
            }
        }
    }

    Rectangle {
        z: 100
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 8
        anchors.bottomMargin: 8
        width: Math.max(0, Math.min(Math.max(120, addNoticeTextMetrics.advanceWidth + 28), parent.width - 16))
        height: 28
        radius: 4
        visible: root.addNoticeVisible
        color: Config.settingsBackground
        border.width: 1
        border.color: root.addNoticeError ? "#ff5555" : Config.accent

        Text {
            id: addNoticeTextItem
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            text: root.addNoticeText
            color: root.addNoticeError ? "#ff5555" : Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        TextMetrics {
            id: addNoticeTextMetrics
            font: addNoticeTextItem.font
            text: root.addNoticeText
        }
    }

}
