import QtQuick
import Quickshell.Io
import "Kit.js" as Kit

Item {
    id: root

    required property var livery
    required property var bridge

    implicitWidth: 196
    implicitHeight: 150

    property real cpuPct: 0
    property real ramPct: 0
    property real prevTotal: -1
    property real prevIdle: -1

    function parseStat() {
        var f = stat.text().split("\n")[0].trim().split(/\s+/)
        if (f[0] !== "cpu") return
        var total = 0, idle = 0
        for (var i = 1; i < f.length; i++) {
            var v = parseInt(f[i])
            if (isNaN(v)) continue
            total += v
            if (i === 4 || i === 5) idle += v
        }
        var dt = total - root.prevTotal
        if (root.prevTotal >= 0 && dt > 0) root.cpuPct = Math.max(0, Math.min(100, (dt - (idle - root.prevIdle)) / dt * 100))
        root.prevTotal = total
        root.prevIdle = idle
    }

    function parseMem() {
        var kv = {}, lines = mem.text().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var m = lines[i].match(/^(\w+):\s+(\d+)/)
            if (m) kv[m[1]] = parseInt(m[2])
        }
        if (kv.MemTotal > 0 && kv.MemAvailable !== undefined)
            root.ramPct = Math.max(0, Math.min(100, (kv.MemTotal - kv.MemAvailable) / kv.MemTotal * 100))
    }

    FileView { id: stat; path: "/proc/stat"; blockLoading: true; printErrors: false }
    FileView { id: mem; path: "/proc/meminfo"; blockLoading: true; printErrors: false }

    function sample() {
        stat.reload()
        mem.reload()
        root.parseStat()
        root.parseMem()
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: root.sample() }
    Component.onCompleted: root.sample()

    component Use: Loader {
        property var props: ({})
        Component.onCompleted: setSource(Kit.helper("Dial"), props)
    }

    Use { x: 3; y: 25; props: ({ livery: root.livery, big: true, label: "CPU", value: Qt.binding(function () { return root.cpuPct }) }) }
    Use { x: 120; y: 7; props: ({ livery: root.livery, label: "RAM", value: Qt.binding(function () { return root.ramPct }) }) }
}
