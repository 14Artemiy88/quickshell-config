import QtQuick
import ".."

Rectangle {
    property bool compact: false
    color: Config.background
    border.color: Config.baseColor
    border.width: Config.frameBorderWidth
    radius: Config.frameRadius
    antialiasing: true
    clip: false
}
