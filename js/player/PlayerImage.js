.pragma library

// Keep image path handling shared between the Player module and Dashboard.
// Local paths may contain spaces, Cyrillic characters, URL-reserved characters
// or an existing file:// prefix; encode them exactly once before giving them
// to QtQuick.Image. Known transparent/default cover assets are not artwork.
function isPlaceholderImage(value, shellDir) {
    var path = String(value || "")
    if (path === "") return true
    if (path === String(shellDir || "") + "/assets/1px.png") return true
    return path.endsWith("/album_cover.png")
}

function imageSourceForPath(value, shellDir) {
    var path = String(value || "")
    // Player historically renders album_cover.png as its visible fallback;
    // only an empty path and the transparent 1px sentinel have no image source.
    if (path === "" || path === String(shellDir || "") + "/assets/1px.png")
        return ""

    // Preserve non-file image URLs and Qt resource/image-provider URLs.
    if (/^(https?:|data:|qrc:|image:)/i.test(path))
        return path

    var localPath = path
    if (path.startsWith("file://")) {
        localPath = path.substring(7)
        if (localPath.startsWith("localhost/"))
            localPath = localPath.substring("localhost".length)
        // Existing file URLs may already contain percent-encoding. Decode
        // first so they can be normalized once rather than double-encoded.
        try { localPath = decodeURIComponent(localPath) } catch (e) {}
    } else if (/^[A-Za-z][A-Za-z0-9+.-]*:/.test(path)) {
        return path
    }

    var encodedPath = encodeURIComponent(localPath).replace(/%2F/gi, "/")
    return "file://" + encodedPath
}
