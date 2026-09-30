import QtQuick
import ".."

Rectangle {
    property bool compact: false
    property string moduleName: ""
    property color moduleBackgroundColor: Config.background
    readonly property bool moduleFrameVisible: !moduleName || !Settings.loaded || Settings.moduleFrames[moduleName] !== false
    readonly property bool moduleBackgroundVisible: !moduleName || !Settings.loaded || Settings.moduleBackgrounds[moduleName] !== false

    color: moduleBackgroundVisible ? moduleBackgroundColor : Config.transparent
    border.color: moduleFrameVisible ? Config.baseColor : Config.transparent
    border.width: moduleFrameVisible ? Config.frameBorderWidth : 0
    radius: Config.frameRadius
    antialiasing: true
    clip: false
}
