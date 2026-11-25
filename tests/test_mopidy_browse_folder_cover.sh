#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/bin" "$TMP_DIR/cache" "$TMP_DIR/music/Album One"
export HOME="$TMP_DIR/home" XDG_CONFIG_HOME="$TMP_DIR/config" XDG_DATA_HOME="$TMP_DIR/data" XDG_STATE_HOME="$TMP_DIR/state" XDG_CACHE_HOME="$TMP_DIR/xdg-cache"
export QS_PROJECT_DIR="$ROOT" QS_CACHE_DIR="$TMP_DIR/cache"
export MOPIDY_RPC_URL='http://mopidy.test/mopidy/rpc'
export MOCK_MOPIDY_MODE="direct" MOCK_MOPIDY_CALLS="$TMP_DIR/calls" MOCK_MOPIDY_DOWNLOADS="$TMP_DIR/downloads" MOCK_IMAGE_SOURCE="$TMP_DIR/cover.png"
export MOCK_FILE_TRACK_URI="file://$TMP_DIR/music/Album%20One/01%20Track.flac"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/S5sAAAAASUVORK5CYII=' | base64 -d > "$MOCK_IMAGE_SOURCE"
printf 'audio' > "$TMP_DIR/music/Album One/01 Track.flac"
cp "$MOCK_IMAGE_SOURCE" "$TMP_DIR/music/Album One/cover.jpg"

cat > "$TMP_DIR/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
payload="" output="" url=""
while (($#)); do
    case "$1" in
        -d) payload="$2"; shift 2 ;;
        -o) output="$2"; shift 2 ;;
        http://*|https://*) url="$1"; shift ;;
        *) shift ;;
    esac
done
if [[ -n "$payload" ]]; then
    method="$(jq -r '.method // ""' <<< "$payload")"
    printf '%s\n' "$payload" >> "$MOCK_MOPIDY_CALLS"
    case "$method" in
        core.library.browse)
            jq -cn --arg mode "$MOCK_MOPIDY_MODE" --arg fileTrack "$MOCK_FILE_TRACK_URI" '
              if $mode == "root" then
                {result:[{__model__:"Ref",type:"directory",uri:"artist:one",name:"Artist"}]}
              elif $mode == "file" then
                {result:[{__model__:"Ref",type:"track",uri:$fileTrack,name:"Track one"}]}
              else
                {result:[
                  {__model__:"Ref",type:"track",uri:"track:one",name:"Track one"},
                  {__model__:"Ref",type:"track",uri:"track:two",name:"Track two"},
                  {__model__:"Ref",type:"track",uri:"track:three",name:"Track three"},
                  {__model__:"Ref",type:"track",uri:"track:four",name:"Track four"},
                  {__model__:"Ref",type:"track",uri:"track:five",name:"Track five"},
                  {__model__:"Ref",type:"track",uri:"track:six",name:"Track six"}
                ]}
              end'
            ;;
        core.library.lookup)
            if [[ "$MOCK_MOPIDY_MODE" == "file" ]]; then
                jq -cn '{result:{}}'
            else
                jq -cn '{result:{
                  "track:one":[{__model__:"Track",uri:"track:one",album:{__model__:"Album",uri:"album:one",name:"Album One"}}],
                  "track:two":[{__model__:"Track",uri:"track:two",album:{__model__:"Album",uri:"album:one",name:"Album One"}}],
                  "track:three":[{__model__:"Track",uri:"track:three",album:{__model__:"Album",uri:"album:one",name:"Album One"}}]
                }}'
            fi
            ;;
        core.library.get_images)
            case "$MOCK_MOPIDY_MODE" in
                direct)
                    jq -cn '{result:{
                      "track:one":[
                        {__model__:"Image",uri:"/local/small.jpg",width:100,height:100},
                        {__model__:"Image",uri:"/local/large.jpg",width:900,height:900}
                      ],
                      "album:one":[{__model__:"Image",uri:"/local/album.jpg",width:500,height:500}]
                    }}'
                    ;;
                fallback)
                    jq -cn '{result:{
                      "album:one":[{__model__:"Image",uri:"/local/album-fallback.jpg",width:500,height:500}]
                    }}'
                    ;;
                empty) jq -cn '{result:{}}' ;;
                *) echo "Unexpected mode for get_images: $MOCK_MOPIDY_MODE" >&2; exit 90 ;;
            esac
            ;;
        *) echo "Unexpected Mopidy method: $method" >&2; exit 90 ;;
    esac
else
    [[ -n "$output" && -n "$url" ]] || { echo "Unexpected curl invocation: $url $output" >&2; exit 91; }
    printf '%s\n' "$url" >> "$MOCK_MOPIDY_DOWNLOADS"
    cp "$MOCK_IMAGE_SOURCE" "$output"
fi
STUB
chmod +x "$TMP_DIR/bin/curl"
export PATH="$TMP_DIR/bin:$PATH"

run_browse() {
    local mode="$1" uri="$2"
    MOCK_MOPIDY_MODE="$mode" "$ROOT/scripts/mopidy/library.sh" browse "$uri"
}

# Mopidy-File has no get_images support. The Player's actual artwork path for
# file:// tracks scans the album directory; the folder browser must reuse it.
run_browse file "file://$TMP_DIR/music/Album%20One" > "$TMP_DIR/file.json"
file_cover="$(jq -r '.folderCover' "$TMP_DIR/file.json")"
[[ "$file_cover" == "$TMP_DIR/music/Album One/cover.jpg" ]]
[[ -s "$file_cover" ]]
[[ "$(jq -r '.entries | length' "$TMP_DIR/file.json")" == 1 ]]
# The same resolver is exposed as a bounded single-folder command for lazy list previews.
MOCK_MOPIDY_MODE=file "$ROOT/scripts/mopidy/library.sh" folder_cover "file://$TMP_DIR/music/Album%20One" > "$TMP_DIR/file-row-cover.txt"
[[ "$(cat "$TMP_DIR/file-row-cover.txt")" == "$TMP_DIR/music/Album One/cover.jpg" ]]

# Mopidy-Local image-capable path reuses the same resolver/cache as Player:
# Track Ref -> lookup Track.album.uri -> get_images(track, album) -> local cache.
: > "$MOCK_MOPIDY_CALLS"
: > "$MOCK_MOPIDY_DOWNLOADS"
run_browse direct 'directory:album' > "$TMP_DIR/direct.json"
cover_path="$(jq -r '.folderCover' "$TMP_DIR/direct.json")"
[[ -s "$cover_path" ]]
[[ "$(file --brief --mime-type "$cover_path")" == image/png ]]
[[ "$cover_path" == "$TMP_DIR/cache/mopidy-covers/"* ]]
[[ "$(jq -r '.entries | length' "$TMP_DIR/direct.json")" == 6 ]]
[[ "$(wc -l < "$MOCK_MOPIDY_CALLS" | tr -d ' ')" == 3 ]]
lookup_tracks="$(sed -n '2p' "$MOCK_MOPIDY_CALLS" | jq -c '.params.uris')"
[[ "$(jq -r 'length' <<< "$lookup_tracks")" == 5 ]]
image_uris="$(sed -n '3p' "$MOCK_MOPIDY_CALLS" | jq -c '.params.uris')"
[[ "$(jq -e 'index("track:one") != null and index("album:one") != null' <<< "$image_uris")" == true ]]
[[ "$(tail -n 1 "$MOCK_MOPIDY_DOWNLOADS")" == 'http://mopidy.test/local/large.jpg' ]]
: > "$MOCK_MOPIDY_DOWNLOADS"
MOCK_MOPIDY_MODE=direct "$ROOT/scripts/mopidy/library.sh" folder_cover 'directory:album' > "$TMP_DIR/direct-row-cover.txt"
[[ "$(cat "$TMP_DIR/direct-row-cover.txt")" == "$cover_path" ]]
[[ ! -s "$MOCK_MOPIDY_DOWNLOADS" ]]

# When track image is absent, the same Player resolver falls back to Album.uri.
: > "$MOCK_MOPIDY_CALLS"
: > "$MOCK_MOPIDY_DOWNLOADS"
rm -f "$TMP_DIR/cache/mopidy-covers/"*
run_browse fallback 'directory:album' > "$TMP_DIR/fallback.json"
cover_path="$(jq -r '.folderCover' "$TMP_DIR/fallback.json")"
[[ -s "$cover_path" ]]
[[ "$(tail -n 1 "$MOCK_MOPIDY_DOWNLOADS")" == 'http://mopidy.test/local/album-fallback.jpg' ]]

# Re-opening the same folder reuses the Player's track-keyed cache, no redownload.
: > "$MOCK_MOPIDY_DOWNLOADS"
run_browse fallback 'directory:album' > "$TMP_DIR/fallback-cache.json"
[[ "$(jq -r '.folderCover' "$TMP_DIR/fallback-cache.json")" == "$cover_path" ]]
[[ ! -s "$MOCK_MOPIDY_DOWNLOADS" ]]

# Unknown backend images yield no visible art; placeholders must never be shown.
: > "$MOCK_MOPIDY_DOWNLOADS"
rm -f "$TMP_DIR/cache/mopidy-covers/"*
run_browse empty 'directory:album' > "$TMP_DIR/empty.json"
[[ -z "$(jq -r '.folderCover' "$TMP_DIR/empty.json")" ]]
[[ ! -s "$MOCK_MOPIDY_DOWNLOADS" ]]

# Root browsing must not make lookup or get_images requests.
: > "$MOCK_MOPIDY_CALLS"
run_browse root '' > "$TMP_DIR/root.json"
[[ -z "$(jq -r '.folderCover' "$TMP_DIR/root.json")" ]]
[[ "$(wc -l < "$MOCK_MOPIDY_CALLS" | tr -d ' ')" == 1 ]]

# QML uses the same path normalizer as the working Player cover.
FILE_BROWSER="$ROOT/components/mopidy/MopidyFileBrowser.qml"
MOPIDY_QML="$ROOT/components/mopidy/Mopidy.qml"
grep -Fq 'PlayerImage.imageSourceForPath(controller.browseFolderCover, Quickshell.shellDir)' "$FILE_BROWSER"
grep -Fq 'asynchronous: true' "$FILE_BROWSER"
grep -Fq 'cache: true' "$FILE_BROWSER"
grep -Fq 'property string browseFolderCover: ""' "$MOPIDY_QML"
grep -Fq 'root.browseFolderCover = data.ok === false ? "" : String(data.folderCover || "")' "$MOPIDY_QML"
grep -Fq 'root.browseFolderCover = ""' "$MOPIDY_QML"
printf 'Mopidy folder artwork: Mopidy-File adjacent cover reuse, Mopidy-Local Track/Album API/cache reuse, fallback, cache hit, root fast path and shared QML normalization passed\n'
