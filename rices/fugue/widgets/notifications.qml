// notifications.qml -- fugue's "notifications" slot: the notification popup, hosted by
// SurfaceSlot (shell.qml's notificationsSlot), so this root is a PanelWindow that
// owns its own layer surface -- hidden while the ledger is empty.
//
// Mechanism only borrowed from sonata's notifications.qml (read as reference, not
// copied): read-only state/stage/notifications.json via FileView, newest last, a
// LOCAL dismiss clock keyed by id (0 timeoutMs = never expires), and two
// outbound commands over the bridge socket -- notificationsdismiss / notificationsverdict
// -- never a file write from QML (CONTRACTS.md section 4).
//
// Grammar is unmistakably fugue's, not sonata's (design/intent.md "Why a
// screenshot can never be confused with sonata"): each record draws as a
// stack of Cell instances (Cell.qml, this rice's own uppercase helper) --
// flat rectangles, hairline separators, a 2px rule for the live/urgent
// register, no marble, no crown glyph, no cast shadow.
//
// No Process, no execDetached, no shelling out to any binary from this
// file (hard constraint) -- outbound traffic is the bridge socket only.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    // -- Injected props -- exactly what shell.qml's notificationsSlot hands over ---
    // (shell.qml: SurfaceSlot { slot: "notifications" }, no extraProps configured)
    required property var theme
    required property var bridge

    readonly property int cardW: 260
    readonly property int stackGap: 6
    readonly property int maxCards: 5

    // -- The ledger file -- read-only, watched -------------------------------
    // notifications.json is a CONDUCTING file (CONTRACTS.md section 4) --
    // state/stage/, not $STRILLIX_ROOT/stage/.
    readonly property string notificationsPath:
        (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/state/stage/notifications.json"
    property var records: []
    FileView {
        id: notificationsFile
        path: root.notificationsPath
        watchChanges: true
        onFileChanged: notificationsFile.reload()
        onTextChanged: {
            try {
                var d = JSON.parse(notificationsFile.text())
                root.ingest((d && d.notifications) ? d.notifications : [])
            } catch (e) { /* absent/garbage -- hold what we have */ }
        }
        Component.onCompleted: notificationsFile.reload()
    }

    // -- The dismiss clock -- one map id -> epoch-ms deadline (0 = never) ----
    // A deadline counts from the record's receivedAt (from first sight only
    // when that does not parse), so a reload of this file, which meets the
    // whole stored ledger as first sight, never shows it again as fresh
    // toasts. A record already past its deadline lapses in ingest, so it is
    // never drawn.
    property var deadlines: ({})
    property var lapsed: ({})
    // id -> receivedAt of the arrival currently tracked. dunst's
    // stack_duplicates reuses ONE notification id for a repeated identical
    // toast (e.g. two back-to-back "nothing to reap" pings carry the same
    // DUNST_ID), but aoide notifications push still stamps a fresh receivedAt on
    // every call -- so the record genuinely changed even though its id
    // didn't. Without this check, lapsed[id] latches true the first time
    // that id's card expires and carries forward onto every LATER push
    // reusing that id -- the popup silently stops showing that id's result
    // forever. Ported from sonata's notifications.qml, same shared pipeline, same
    // bug.
    property var arrivals: ({})
    property int epoch: 0

    function ingest(arr) {
        var now = Date.now()
        var dl = {}
        var lp = {}
        var av = {}
        for (var i = 0; i < arr.length; i++) {
            var r = arr[i]
            if (!r || r.id === undefined) continue
            var id = "" + r.id
            var receivedAt = "" + (r.receivedAt || "")
            var sameArrival = root.arrivals[id] !== undefined && root.arrivals[id] === receivedAt
            var t = (r.timeoutMs !== undefined) ? (r.timeoutMs | 0) : 0
            dl[id] = (sameArrival && id in root.deadlines) ? root.deadlines[id]
                                            : (t > 0 ? (Date.parse(receivedAt) || now) + t : 0)
            if ((sameArrival && root.lapsed[id]) || (dl[id] > 0 && now >= dl[id])) lp[id] = true
            av[id] = receivedAt
        }
        root.deadlines = dl
        root.lapsed = lp
        root.arrivals = av
        root.records = arr
        root.epoch++
    }
    Timer {
        interval: 500
        repeat: true
        running: root.visibleRecords.length > 0
        onTriggered: {
            var now = Date.now()
            var changed = false
            var lp = root.lapsed
            for (var id in root.deadlines) {
                var d = root.deadlines[id]
                if (d > 0 && now >= d && !lp[id]) { lp[id] = true; changed = true }
            }
            if (changed) { root.lapsed = lp; root.epoch++ }
        }
    }

    // newest last -> bottom-anchored stack grows upward out of the corner
    readonly property var visibleRecords: {
        var e = root.epoch
        var out = []
        for (var i = root.records.length - 1; i >= 0; i--) {
            var r = root.records[i]
            if (!r || r.id === undefined) continue
            if (root.lapsed["" + r.id]) continue
            out.push(r)
            if (out.length >= root.maxCards) break
        }
        return out.reverse()
    }

    function isSummons(r) { return r && r.kind === "summons" }
    function urgencyOf(r) { return r ? ("" + (r.urgency || "normal")) : "normal" }
    function tagOf(r) {
        if (root.isSummons(r)) return "verdict"
        return root.urgencyOf(r)
    }
    function dismiss(id) {
        root.bridge.sendCommand({ cmd: "notificationsdismiss", id: "" + id })
    }
    function wave(id) {
        var lp = root.lapsed
        lp["" + id] = true
        root.lapsed = lp
        root.epoch++
    }
    function verdict(sessionId, word) {
        root.bridge.sendCommand({ cmd: "notificationsverdict", id: "" + sessionId, verdict: word })
    }

    // -- Layer-shell surface -- bottom-right, the corner the notifications cries
    // from (dormant while the ledger is empty) ------------------------------
    anchors { bottom: true; right: true }
    margins { bottom: 8; right: 10 }
    exclusiveZone: 0
    color: "transparent"
    visible: root.visibleRecords.length > 0
    implicitWidth: root.cardW + 1
    implicitHeight: Math.max(1, stack.implicitHeight)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "aoide-notifications"

    Column {
        id: stack
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        spacing: root.stackGap

        Repeater {
            model: root.visibleRecords
            delegate: Item {
                id: slot
                required property var modelData
                readonly property var rec: modelData
                readonly property bool summons: root.isSummons(rec)
                readonly property bool critical: root.urgencyOf(rec) === "critical"
                readonly property string bodyText: rec ? ("" + (rec.body || "")) : ""

                width: root.cardW
                height: col.implicitHeight

                Rectangle {
                    anchors.fill: parent
                    radius: 0
                    color: root.theme.notifBg
                }

                MouseArea {
                    // whole-card dismiss catcher, declared first so the
                    // verdict chips (below) win the hit test over it
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: slot.summons ? root.wave(slot.rec.id) : root.dismiss(slot.rec.id)
                }

                Column {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 0

                    Row {
                        spacing: 0
                        Cell {
                            theme: root.theme
                            paper: root.theme.notifBg
                            ink: root.theme.notifFg
                            label: "app"
                            value: slot.rec ? ("" + (slot.rec.app || "system")) : "system"
                        }
                        Cell {
                            theme: root.theme
                            paper: root.theme.notifBg
                            ink: root.theme.notifFg
                            label: "tag"
                            value: root.tagOf(slot.rec)
                            urgent: slot.critical || slot.summons
                            active: slot.critical
                        }
                    }

                    Text {
                        width: parent.width
                        leftPadding: 8
                        rightPadding: 8
                        topPadding: 4
                        bottomPadding: 4
                        visible: text.length > 0
                        text: slot.rec ? ("" + (slot.rec.summary || "")) : ""
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: root.theme.notifFg
                    }
                    Text {
                        width: parent.width
                        leftPadding: 8
                        rightPadding: 8
                        bottomPadding: 4
                        visible: slot.bodyText.length > 0
                        text: slot.bodyText
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: root.theme.notifFg
                        opacity: 0.75
                    }

                    Row {
                        visible: slot.summons
                        spacing: 0
                        Cell {
                            theme: root.theme
                            paper: root.theme.notifBg
                            ink: root.theme.notifFg
                            value: "approve"
                            interactive: true
                            onActivated: root.verdict(slot.rec.sessionId, "approve")
                        }
                        Cell {
                            theme: root.theme
                            paper: root.theme.notifBg
                            ink: root.theme.notifFg
                            value: "deny"
                            urgent: true
                            interactive: true
                            onActivated: root.verdict(slot.rec.sessionId, "deny")
                        }
                    }
                }
            }
        }
    }
}
