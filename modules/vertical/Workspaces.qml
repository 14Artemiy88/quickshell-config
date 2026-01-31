import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common

Column {
    spacing: 10

    Repeater {
        model: niri.workspaces

        delegate: Rectangle {
            // visible: (index > 1 && index <= niri.windows.count + 1) || model.isFocused
            width: model.isActive ? 7 : 3
            height: 10
            topRightRadius: 10
            bottomRightRadius: 10
            color: model.isActive ? Config.accentColor : (index > 1 && index < niri.windows.count) ? Config.nonAccentColor : Config.inactiveColor
        }
    }
}
