pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: nwroot

    property string activeNetwork: "--"

    Process {
        id: networkProc
        command: ["sh", "-c", "nmcli -g NAME c show -a | rg 14"]
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

    ////////////////////

    property bool expanded: false
    property bool scanning: false
    property var networks: []
    Process {
        id: scanProc
        // command: ["nmcli", "-t", "-f", "IN-USE,SSID,BARS", "dev", "wifi", "list"]
        command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SECURITY,BARS dev wifi list | rg 14"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split('\n');
                let list = [];
                for (let line of lines) {
                    if (!line || line.trim() === "")
                        continue;

                    // Делим строку по двоеточию
                    let parts = line.split(':');
                    if (parts.length >= 4) {
                        let ssidName = parts[1].trim();
                        // Пропускаем скрытые сети без названия
                        if (ssidName === "")
                            continue;

                        let inUse = parts[0] === "*";

                        // if (!inUse) {
                        list.push({
                            inUse: inUse,
                            ssid: ssidName,
                            security: parts[2].trim(),
                            bars: parts[3].trim()
                        });
                        // }
                    }
                }
                nwroot.networks = list;
                nwroot.scanning = false;
            }
        }
    }
    function refresh() {
        nwroot.scanning = true;
        scanProc.running = false;
        scanProc.running = true;
    }

    onExpandedChanged: {
        if (expanded)
            refresh();
    }

    ////////////////////

    property string targetSsid: ""

    Process {
        id: connectProc
        property string targetSsid: ""
        command: ["nmcli", "dev", "wifi", "connect", targetSsid]
        running: false
    }

    function connectTo(ssid) {
        nwroot.targetSsid = ssid;
        connectProc.targetSsid = nwroot.targetSsid;
        connectProc.running = false;
        connectProc.running = true;
        console.log("Connecting to " + ssid);
    }
}
