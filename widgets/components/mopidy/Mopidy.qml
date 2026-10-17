import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "." as MopidyWidgets
import "../primitives" as Primitives
import "../.."

Primitives.ModuleFrame {
    id: root
    moduleName: "mopidy"
    moduleBackgroundColor: Config.mopidyBackground

    property bool externalTopPanelHover: false
    signal topPanelHideRequested()

    property bool queueAvailable: false
    property bool mopidyLaunchCooldown: false
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
                y += Config.mopidyTrackRowHeight
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
    readonly property bool playlistManageBusy: playlistManageProcess.running
    readonly property bool playlistContentMoveBusy: playlistContentMoveProcess.running

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
        if (!root.playlistUri || root.playlistsBusy) return
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

    function openBrowseRoot() {
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
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
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
        root.browseStack = root.browseStack.concat([{uri: root.browseUri, title: root.browseTitle}])
        root.browseUri = String(uri || "")
        root.browseTitle = String(title || "Музыка")
        root.browseBusy = true
        browseProcess.command = [Quickshell.shellDir + "/scripts/mopidy/library.sh", "browse", root.browseUri]
        browseProcess.running = true
    }

    function browseBack() {
        if (root.browseBusy || root.browseStack.length === 0) return
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
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

    function closeLibraryBrowserToQueue() {
        root.searchOpen = false
        root.fileFilterOpen = false
        root.fileFilterQuery = ""
        root.searchQuery = ""
        root.searchResults = []
        root.browseEntries = []
        root.browseStack = []
        root.browseUri = ""
        root.browseTitle = "Музыка"
        root.playlists = []
        root.playlistItems = []
        root.playlistUri = ""
        root.playlistTitle = ""
        root.addingToPlaylist = false
        root.libraryMode = "browse"
    }

    function showSearch() {
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
    }

    function openRenamePlaylistDialog() {
        if (!root.playlistUri || playlistManageProcess.running) return
        root.playlistDialogMode = "rename"
        root.playlistDialogInput = String(root.playlistTitle || "")
        root.playlistDialogError = ""
        root.playlistManageUri = String(root.playlistUri)
        root.playlistManageTitle = String(root.playlistTitle || "Плейлист")
        root.playlistDialogVisible = true
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
                font.pixelSize: Config.mopidyStatusFontSize
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
