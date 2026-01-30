pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: nwroot

    property string activeNetwork: "--"

    Process {
        id: networkProc
        command: ["sh", "-c", "nmcli -g NAME c show -a | ag 14"]
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
    property var networks: []

    Process {
        id: scanProc
        // command: ["nmcli", "-t", "-f", "IN-USE,SSID,BARS", "dev", "wifi", "list"]
        command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,BARS dev wifi list | ag 14"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split('\n');
                let list = [];
                for (let line of lines) {
                    if (!line || line.trim() === "")
                        continue;

                    // Делим строку по двоеточию
                    let parts = line.split(':');
                    if (parts.length >= 3) {
                        let ssidName = parts[1].trim();
                        // Пропускаем скрытые сети без названия
                        if (ssidName === "")
                            continue;

                        let inUse = parts[0] === "*";

                        // if (!inUse) {
                        list.push({
                            inUse: inUse,
                            ssid: ssidName,
                            bars: parts[2]
                        });
                        // }
                    }
                }
                nwroot.networks = list;
            }
        }
    }
    function refresh() {
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
        command: ["nmcli", "dev", "wifi", "connect", nwroot.targetSsid]
        running: false // по умолчанию выключен
    }

    function connectTo(ssid) {
        nwroot.targetSsid = ssid;
        connectProc.running = false;
        connectProc.running = true;
        console.log("Connet+d to " + ssid);
    }
}
