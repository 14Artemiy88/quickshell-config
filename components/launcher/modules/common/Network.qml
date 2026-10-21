pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string activeNetwork: "--"
    property bool scanning: false
    property var networks: []

    // nmcli uses backslash escapes in terse output. Split only on unescaped
    // colons so SSIDs containing ':' remain intact.
    function parseFields(line) {
        const fields = []
        let field = ""
        let escaped = false

        for (let i = 0; i < line.length; ++i) {
            const ch = line[i]
            if (escaped) {
                field += ch
                escaped = false
            } else if (ch === "\\") {
                escaped = true
            } else if (ch === ":") {
                fields.push(field)
                field = ""
            } else {
                field += ch
            }
        }

        if (escaped)
            field += "\\"
        fields.push(field)
        return fields
    }

    Process {
        id: activeConnectionProcess
        command: ["nmcli", "-t", "--escape", "yes", "-f", "NAME", "connection", "show", "--active"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = String(this.text ?? "").trim().split("\n")
                root.activeNetwork = lines.length && lines[0] ? lines[0] : "--"
            }
        }
    }

    Process {
        id: scanProcess
        command: ["nmcli", "-t", "--escape", "yes", "-f", "IN-USE,SSID,SECURITY,BARS", "device", "wifi", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = String(this.text ?? "").split("\n")
                const result = []

                for (const line of lines) {
                    if (!line || !line.trim())
                        continue

                    const parts = root.parseFields(line)
                    if (parts.length < 4)
                        continue

                    const ssid = String(parts[1] ?? "").trim()
                    if (!ssid)
                        continue

                    result.push({
                        inUse: String(parts[0] ?? "").trim() === "*",
                        ssid: ssid,
                        security: String(parts[2] ?? "").trim(),
                        bars: String(parts[3] ?? "").trim()
                    })
                }

                root.networks = result
                root.scanning = false
            }
        }
    }

    Process {
        id: connectProcess
        property string targetSsid: ""
        command: ["nmcli", "device", "wifi", "connect", targetSsid]
        running: false
    }

    function refresh() {
        root.scanning = true
        if (scanProcess.running)
            scanProcess.running = false
        if (activeConnectionProcess.running)
            activeConnectionProcess.running = false
        scanProcess.running = true
        activeConnectionProcess.running = true
    }

    function connectTo(ssid) {
        connectProcess.targetSsid = String(ssid ?? "")
        if (!connectProcess.targetSsid)
            return
        if (connectProcess.running)
            connectProcess.running = false
        connectProcess.running = true
    }
}
