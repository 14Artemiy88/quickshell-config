pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: vpnroot

    property bool vpnIsActive: false

    Process {
        id: networkProc
        command: ["sh", "-c", "nmcli -g NAME c show -a | rg DimaVPN"]
        stdout: SplitParser {
            onRead: data => {
                if (data)
                    activeNetwork = data.trim();
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
            networkProc.running = true;
        }
    }
}
