import QtQuick
import Quickshell.Io
import "Kit.js" as Kit

Item {
    id: root

    required property var livery
    required property var bridge

    property var usage: ({})
    property real nowMs: Date.now()
    property bool cooling: false

    readonly property var live: usage.live ? usage.live : ({})
    readonly property bool liveOk: live.ok === true
    readonly property var local: usage.local ? usage.local : ({})
    readonly property var today: local.today ? local.today : ({})
    readonly property var week: local.week ? local.week : ({})
    readonly property bool hasLocal: today.costUsd !== undefined || week.costUsd !== undefined
    readonly property bool hasData: !!usage.live || !!usage.local

    readonly property real fetchedMs: usage.fetchedAt ? Date.parse(usage.fetchedAt) : NaN
    readonly property bool stale: !isNaN(fetchedMs) && nowMs - fetchedMs > 900000
    readonly property bool reading: liveOk && !stale

    function util(block) { return liveOk && block && block.utilization !== undefined ? block.utilization : -1 }
    function resets(block) { return block ? livery.usageResetIn(block.resetsAt, nowMs) : "" }
    function money(v) { return v === undefined ? "—" : "$" + Number(v).toFixed(2) }
    function clock(ms) { return Qt.formatTime(new Date(ms), "hh:mm") }

    readonly property string caption: !hasData ? "usage unavailable" : stale ? "stale · as of " + clock(fetchedMs) : "live usage unavailable"

    implicitWidth: 196
    implicitHeight: hasLocal ? 112 : 95

    FileView {
        path: root.livery.usagePath
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(text())
                root.usage = d && typeof d === "object" ? d : ({})
            } catch (e) { root.usage = ({}) }
        }
        onLoadFailed: root.usage = ({})
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.nowMs = Date.now() }
    Timer { id: cool; interval: 10000; onTriggered: root.cooling = false }

    component Use: Loader {
        property var props: ({})
        Component.onCompleted: setSource(Kit.helper("Dial"), props)
    }

    component Cap: Rectangle {
        id: cap
        property string label: ""
        height: 13
        radius: 2
        color: Kit.ink
        Text {
            anchors.centerIn: parent
            text: cap.label
            color: "#ffffff"
            font: Kit.bodyFont(9)
            textFormat: Text.PlainText
        }
    }

    Item {
        anchors.fill: parent
        opacity: (root.liveOk && root.stale) || !root.hasData ? 0.55 : 1

        Use { x: 17; y: 3; props: ({ livery: root.livery, label: "5 HR", value: Qt.binding(function () { return root.util(root.live.fiveHour) }) }) }
        Use { x: 109; y: 3; props: ({ livery: root.livery, label: "WEEK", value: Qt.binding(function () { return root.util(root.live.sevenDay) }) }) }

        Cap { visible: root.reading; x: 8; y: 80; width: 88; label: root.resets(root.live.fiveHour) }
        Cap { visible: root.reading; x: 100; y: 80; width: 88; label: root.resets(root.live.sevenDay) }
        Cap { visible: !root.reading; x: 8; y: 80; width: 180; label: root.caption }

        Cap { visible: root.hasLocal; x: 8; y: 97; width: 180; label: "today " + root.money(root.today.costUsd) + " · week " + root.money(root.week.costUsd) }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.cooling) return
            root.cooling = true
            cool.restart()
            root.bridge.refreshUsage()
        }
    }
}
