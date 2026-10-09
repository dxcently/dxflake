import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Kit.js" as Kit
import "Notice.js" as Notice

PanelWindow {
    id: root

    required property var livery
    required property var bridge

    readonly property var kit: Kit.make(root.livery)
    readonly property string stageDir: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/state/stage/"

    readonly property int cardW: 340
    readonly property int padX: 12
    readonly property int padTop: 8
    readonly property int tailW: 16
    readonly property int tailH: 10
    readonly property int tipRoom: 6
    readonly property int tipGap: 3

    property var records: []
    property var sessions: ({})
    property var waved: ({})
    property int tick: 0

    FileView {
        path: root.stageDir + "herald.json"
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(text())
                root.records = d && d.notifications ? d.notifications : []
            } catch (e) {}
            root.tick++
        }
        onLoadFailed: root.records = []
    }
    FileView {
        path: root.stageDir + "sessions.json"
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var by = {}
            try {
                var l = JSON.parse(text()).sessions || []
                for (var i = 0; i < l.length; i++) by[l[i].sessionId] = l[i]
            } catch (e) {}
            root.sessions = by
        }
    }
    Timer {
        interval: 250
        repeat: true
        running: root.head !== null
        onTriggered: root.tick++
    }

    readonly property var queue: {
        root.tick
        var now = Date.now(), sums = [], toasts = []
        var all = Notice.newest(root.records)
        for (var i = 0; i < all.length; i++) {
            var r = all[i], end = Notice.lapseAt(r)
            if (root.waved[Notice.key(r)] || (end > 0 && now >= end)) continue
            if (Notice.isSummons(r)) sums.push(r)
            else toasts.push(r)
        }
        return sums.concat(toasts)
    }
    readonly property var head: queue.length > 0 ? queue[0] : null
    readonly property string headKey: head ? Notice.key(head) : ""
    readonly property bool summons: Notice.isSummons(head)

    function wave(r) {
        var w = root.waved
        w[Notice.key(r)] = true
        root.waved = w
        root.tick++
    }
    function dismiss(r) {
        if (Notice.isSummons(r)) root.wave(r)
        else root.bridge.sendCommand({ cmd: "heralddismiss", id: "" + r.id })
    }
    function verdict(r, word) {
        root.bridge.sendCommand({ cmd: "heraldverdict", id: "" + r.sessionId, verdict: word })
    }

    readonly property bool yielded: {
        root.tick
        var open = Kit.hub.open
        return !!(open && open[root.focusName])
    }

    readonly property int pointAt: root.summons ? Kit.tray.agents : Kit.tray.flag
    readonly property int edge: Math.max(root.padX, root.pointAt - root.cardW / 2)
    readonly property real tailCx: Math.max(22, Math.min(root.cardW - 22, root.cardW - (root.pointAt - root.edge)))

    readonly property string meta: {
        root.tick
        if (!root.head) return ""
        var tops = Hyprland.toplevels && Hyprland.toplevels.values ? Hyprland.toplevels.values : []
        var where = root.summons ? Notice.place(root.sessions[root.head.sessionId], tops) : ""
        return [where || ("" + (root.head.app || "")), Notice.ago(root.head, Date.now())].filter(function (p) { return p !== "" }).join(" · ")
    }

    readonly property string focusName: {
        var mon = Hyprland.focusedMonitor
        return mon ? mon.name : ""
    }
    screen: {
        var screens = Quickshell.screens
        for (var i = 0; i < screens.length; i++)
            if (screens[i].name === root.focusName) return screens[i]
        return null
    }
    anchors { bottom: true; right: true }
    margins.right: root.edge - root.padX
    margins.bottom: root.tipGap - root.tipRoom
    implicitWidth: root.cardW + 2 * root.padX
    implicitHeight: root.padTop + hit.height + root.tipRoom
    exclusiveZone: 0
    color: "transparent"
    visible: root.head !== null && !root.yielded
    mask: Region { item: hit }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "aoide-herald"

    onHeadKeyChanged: if (root.headKey !== "") fade.restart()

    component Glyph: Item {
        id: gl
        property color tone: "#25bbcf"
        property bool bang: false
        width: 16
        height: 16
        Rectangle { x: 0.5; y: 0.5; width: 15; height: 15; radius: 7.5; color: gl.tone; border.width: 1; border.color: Kit.dark(0.55) }
        Rectangle { visible: gl.bang; x: 7.1; y: 3.1; width: 1.8; height: 6.8; radius: 0.9; color: Kit.ink }
        Rectangle { visible: gl.bang; x: 7; y: 10.5; width: 2; height: 2; radius: 1; color: Kit.ink }
        Rectangle { visible: !gl.bang; x: 7; y: 3.5; width: 2; height: 2; radius: 1; color: Kit.ink }
        Rectangle { visible: !gl.bang; x: 7.1; y: 6.8; width: 1.8; height: 5.7; radius: 0.9; color: Kit.ink }
    }

    component Pill: Item {
        id: pill
        property string label: ""
        property color tone: "#3bdcac"
        signal clicked()
        width: lab.implicitWidth + 26
        height: 22
        Rectangle {
            anchors.fill: parent
            radius: 11
            color: pill.tone
            border.width: 1
            border.color: Kit.dark(0.55)
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0; color: Kit.white(0.55) }
                    GradientStop { position: 0.5; color: Kit.white(0.15) }
                    GradientStop { position: 0.5; color: Kit.white(0) }
                    GradientStop { position: 1; color: Kit.white(0) }
                }
            }
            Rectangle { anchors.fill: parent; radius: 11; color: Kit.white(0.20); visible: pillMa.containsMouse }
        }
        Text {
            id: lab
            anchors.centerIn: parent
            text: pill.label
            color: Kit.ink
            font: Kit.boldFont(12)
            textFormat: Text.PlainText
        }
        MouseArea { id: pillMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }

    Item {
        id: hit
        x: root.padX
        y: root.padTop
        width: root.cardW
        height: card.height + root.tailH - 1

        NumberAnimation { id: fade; target: hit; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }

        Item {
            id: bgSrc
            width: hit.width
            height: hit.height
            layer.enabled: true
            visible: false
            Rectangle {
                width: parent.width
                height: card.height
                radius: 6
                border.width: 1
                border.color: Kit.dark(0.55)
                gradient: Gradient {
                    GradientStop { position: 0; color: "#f5fbfb" }
                    GradientStop { position: 1; color: "#e5f5f7" }
                }
            }
            Shape {
                x: root.tailCx - root.tailW / 2
                y: card.height - 1
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: "#e5f5f7"
                    PathSvg { path: "M0 0 H16 L8 10 Z" }
                }
                ShapePath {
                    strokeColor: Kit.dark(0.55)
                    strokeWidth: 1
                    fillColor: "transparent"
                    PathSvg { path: "M0 0 L8 10 L16 0" }
                }
            }
        }
        MultiEffect {
            width: bgSrc.width
            height: bgSrc.height
            source: bgSrc
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.18
            shadowBlur: 0.3
            shadowVerticalOffset: 3
            autoPaddingEnabled: true
        }

        Item {
            id: card
            width: root.cardW
            height: col.height + 24

            MouseArea {
                anchors.fill: parent
                cursorShape: root.summons ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: if (root.head) root.dismiss(root.head)
            }

            Column {
                id: col
                x: 13
                y: 11
                width: parent.width - 26

                Item {
                    width: parent.width
                    height: Math.max(16, title.implicitHeight)
                    Glyph {
                        anchors.verticalCenter: parent.verticalCenter
                        tone: root.summons ? root.kit.awaiting
                            : root.head && root.head.urgency === "critical" ? root.livery.notifUrgent
                            : root.head && root.head.urgency === "low" ? "#8db0ba" : "#25bbcf"
                        bang: root.summons || (!!root.head && root.head.urgency === "critical")
                    }
                    Text {
                        id: title
                        x: 24
                        width: parent.width - 24 - 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.head ? "" + (root.head.summary || root.head.app || "") : ""
                        color: Kit.ink
                        font: Kit.boldFont(13)
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    Item {
                        id: closeBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: 16
                        height: 16
                        Rectangle { anchors.fill: parent; radius: 2; color: Kit.accent(0.15); visible: closeMa.containsMouse }
                        Text { anchors.centerIn: parent; text: "×"; color: Kit.dark(0.72); font: Kit.bodyFont(13); textFormat: Text.PlainText }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.head) root.dismiss(root.head)
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 1 + metaText.implicitHeight + 6
                    Text {
                        id: metaText
                        x: 24
                        y: 1
                        width: parent.width - 24
                        text: root.meta
                        elide: Text.ElideRight
                        color: Kit.dark(0.72)
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                }

                Item {
                    id: bodyRow
                    readonly property var cmd: root.summons ? Notice.command(root.head.body) : ({ label: "", code: "" })
                    readonly property bool hasCmd: cmd.label !== ""
                    readonly property bool hasText: !!root.head && ("" + (root.head.body || "")).length > 0 && !hasCmd
                    width: parent.width
                    height: hasCmd ? Math.max(cmdLabel.implicitHeight, chip.height) : (hasText ? bodyText.implicitHeight : 0)
                    Text {
                        id: bodyText
                        visible: bodyRow.hasText
                        x: 24
                        width: parent.width - 24
                        text: root.head ? "" + (root.head.body || "") : ""
                        color: Kit.ink
                        font: Kit.bodyFont(12)
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    Text {
                        id: cmdLabel
                        visible: bodyRow.hasCmd
                        x: 24
                        text: bodyRow.cmd.label
                        color: Kit.ink
                        font: Kit.bodyFont(12)
                        textFormat: Text.PlainText
                    }
                    TextMetrics { id: codeProbe; font: Notice.monoFont(11); text: bodyRow.cmd.code }
                    Rectangle {
                        id: chip
                        visible: bodyRow.hasCmd
                        x: 24 + cmdLabel.implicitWidth + 4
                        y: (cmdLabel.implicitHeight - 15) / 2
                        width: Math.min(codeProbe.advanceWidth + 8, parent.width - x)
                        height: codeText.implicitHeight
                        radius: 2
                        color: Kit.dark(0.06)
                        Text {
                            id: codeText
                            x: 3
                            width: parent.width - 6
                            text: bodyRow.cmd.code
                            color: Kit.ink
                            font: Notice.monoFont(11)
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                    }
                }

                Item {
                    readonly property int pct: root.head && root.head.progress !== undefined ? root.head.progress | 0 : -1
                    visible: pct >= 0
                    width: parent.width
                    height: visible ? 8 + 15 : 0
                    Rectangle { x: 24; y: 8 + 4.5; width: parent.width - 24 - 40; height: 6; radius: 3; color: Kit.dark(0.20); border.width: 1; border.color: Kit.dark(0.25) }
                    Rectangle { x: 24; y: 8 + 4.5; width: Math.max(6, (parent.width - 24 - 40) * Math.min(100, parent.pct) / 100); height: 6; radius: 3; color: "#25bbcf" }
                    Text {
                        anchors { right: parent.right; top: parent.top; topMargin: 8 }
                        height: 15
                        verticalAlignment: Text.AlignVCenter
                        text: Math.min(100, parent.pct) + "%"
                        color: Kit.dark(0.72)
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                }

                Item {
                    visible: root.summons
                    width: parent.width
                    height: visible ? 10 + 22 : 0
                    Row {
                        x: 24
                        y: 10
                        spacing: 8
                        Pill { label: "Approve"; tone: root.livery.paletteHot; onClicked: root.verdict(root.head, "approve") }
                        Pill { label: "Deny"; tone: root.livery.notifUrgent; onClicked: root.verdict(root.head, "deny") }
                    }
                }
            }
        }
    }
}
