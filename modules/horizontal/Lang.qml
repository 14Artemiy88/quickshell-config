import QtQuick
import Quickshell
import Quickshell.Io

import "../../launcher/theme"

Rectangle {
    Theme { id: theme }
    property string currentLang: "--"

    anchors.top: parent.top
    anchors.topMargin: -11

    implicitWidth: 20

    Process {
        id: langProc
        command: ["sh", "-c", "niri msg keyboard-layouts | grep '*'"]
        stdout: SplitParser {
            onRead: data => {
                // if (data) currentLang = data.trim().substring(4, 6).toUpperCase();
                if (data)
                    currentLang = data.trim().substring(4, 6) === "Ru" ? "🇷🇺" : "🇺🇸";
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            langProc.running = true;
        }
    }

    Text {
        id: langBlock
        text: currentLang
        color: theme.nonAccent
        font.family: "LED"
        font.pixelSize: 16
        Component.onCompleted: {
            parent.width = timeBlock.contentWidth;
        }
    }
}
