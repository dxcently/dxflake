import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Kit.js" as Kit
import "Buddy.js" as Buddy

PanelWindow {
    id: root

    required property var livery
    required property var bridge
    property var shared: null
    property var stagingEngine: null

    property bool shown: false
    property var targetScreen: null
    property real hiddenAt: 0
    property var hiddenScreen: null

    readonly property string aoideRoot: Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")
    readonly property string stageDir: root.aoideRoot + "/state/stage/"
    readonly property string iconDir: "file://" + root.aoideRoot + "/song/songbook/barcarolle/icons/"
    readonly property string bust: "?v=" + Date.now()
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string fUi: Qt.fontFamilies().indexOf("Tahoma") >= 0 ? "Tahoma" : Kit.family
    readonly property string fMono: Qt.fontFamilies().indexOf("Andale Mono") >= 0 ? "Andale Mono" : "Noto Sans Mono"
    readonly property var k: Kit.make(root.livery)
    readonly property bool canVerdict: !!root.bridge && typeof root.bridge.sendCommand === "function"
    readonly property color wash30: Qt.rgba(232 / 255, 207 / 255, 106 / 255, 0.30)
    readonly property color edgeGold: Qt.rgba(176 / 255, 140 / 255, 20 / 255, 0.55)

    property var sessions: []
    property var hooks: []
    property var notes: []
    property var ledger: []
    property var activeAt: ({})
    property var hookAt: ({})
    property string host: ""
    property var collapsed: ({})
    property var answered: ({})
    property var model: Buddy.build([], {})
    property string sig: ""
    property var feed: []
    property bool logStick: true
    property int loaded: 0
    property bool primed: false
    property var seenJoin: ({})
    property var seenPhase: ({})
    property var seenHerald: ({})
    property int ledgerSeen: 0
    property real now: Date.now()
    property bool spinning: false
    property var tip: null
    property real tipTop: 0

    screen: root.targetScreen
    visible: root.shown
    anchors { right: true; bottom: true }
    margins.right: 4
    margins.bottom: 6
    exclusiveZone: 0
    implicitWidth: 384
    implicitHeight: 713
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "aoide-dock"
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab { windows: [root]; active: root.shown; onCleared: root.hide() }
    Shortcut { sequence: "Escape"; enabled: root.shown; onActivated: root.hide() }
    Timer { interval: 30000; repeat: true; running: root.shown; triggeredOnStart: true; onTriggered: root.now = Date.now() }
    Timer { id: spinStop; interval: 3000; onTriggered: root.spinning = false }

    // ── open / close ─────────────────────────────────────────────────────
    function focusName() {
        var mon = Hyprland.focusedMonitor
        return mon ? mon.name : ""
    }
    function focusedScreen() {
        var n = root.focusName(), s = Quickshell.screens
        for (var i = 0; i < s.length; i++) if (s[i].name === n) return s[i]
        return null
    }
    function show(scr) {
        var t = scr || root.focusedScreen()
        root.tip = null
        if (root.shown && t === root.targetScreen) return
        if (root.shown) {
            root.shown = false
            root.targetScreen = t
            Qt.callLater(function () { root.shown = true })
            return
        }
        root.targetScreen = t
        root.now = Date.now()
        root.shown = true
    }
    function hide() {
        if (!root.shown) return
        root.hiddenAt = Date.now()
        root.hiddenScreen = root.targetScreen
        root.tip = null
        root.shown = false
    }
    function toggle(scr) {
        if (root.shown && (!scr || scr === root.targetScreen)) { root.hide(); return }
        if (!root.shown && Date.now() - root.hiddenAt < 250 && (!scr || scr === root.hiddenScreen)) return
        root.show(scr)
    }

    // ── data ─────────────────────────────────────────────────────────────
    function b16(n, fb) {
        var b = root.livery && root.livery.raw && root.livery.raw.base16
        return b && b[n] ? b[n] : fb
    }
    function listOf(fv, key) {
        try { var o = JSON.parse(fv.text()); return (o && o[key]) || [] } catch (e) { return [] }
    }
    function readLedger(fv) {
        var out = [], lines = ("" + fv.text()).split("\n")
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim() === "") continue
            try { out.push(JSON.parse(lines[i])) } catch (e) {}
        }
        return out
    }
    function rebuild() {
        var summons = {}, live = {}, kept = {}, dropped = false, i, n, id
        for (i = 0; i < root.notes.length; i++) {
            n = root.notes[i]
            if (Buddy.str(n.kind) === "summons" && Buddy.str(n.sessionId) !== "") summons[Buddy.str(n.sessionId)] = n
        }
        for (i = 0; i < root.sessions.length; i++) live[Buddy.str(root.sessions[i].sessionId)] = Buddy.str(root.sessions[i].state)
        for (id in root.answered) { if (live[id] === "awaiting") kept[id] = root.answered[id]; else dropped = true }
        if (dropped) root.answered = kept
        var m = Buddy.build(root.sessions, { home: root.home, collapsed: root.collapsed,
            summons: root.canVerdict ? summons : {}, answered: root.answered,
            activeAt: root.activeAt, hookAt: root.hookAt })
        var sig = JSON.stringify([m.groups, m.rows, m.counts, m.total])
        if (sig === root.sig) return
        root.sig = sig
        root.model = m
    }
    function feedIn(lines) {
        if (!lines.length) return
        root.logStick = logView.atYEnd
        root.feed = Buddy.merge(root.feed, lines)
    }
    // bits: 1 sessions, 2 hooks, 4 herald, 8 ledger. The feed primes once all four have loaded or failed.
    function mark(bit) {
        root.rebuild()
        if (!root.primed) {
            root.loaded = root.loaded | bit
            if (root.loaded === 15) root.prime()
            return
        }
        var by = root.model.byId, r
        if (bit === 1) { r = Buddy.joins(root.seenJoin, root.sessions, by); root.seenJoin = r.seen; root.feedIn(r.lines) }
        if (bit === 2) { r = Buddy.phases(root.seenPhase, root.hooks, by); root.seenPhase = r.seen; root.feedIn(r.lines) }
        if (bit === 4) { r = Buddy.heralds(root.seenHerald, root.notes, by); root.seenHerald = r.seen; root.feedIn(r.lines) }
        if (bit === 8) {
            root.feedIn(Buddy.leaves(root.ledger, Math.min(root.ledgerSeen, root.ledger.length), Date.now()))
            root.ledgerSeen = root.ledger.length
        }
    }
    function prime() {
        var by = root.model.byId, now = Date.now()
        var p = Buddy.phases({}, root.hooks, by), h = Buddy.heralds({}, root.notes, by)
        root.seenJoin = Buddy.joins({}, root.sessions, by).seen
        root.seenPhase = p.seen
        root.seenHerald = h.seen
        root.ledgerSeen = root.ledger.length
        root.primed = true
        root.feedIn(h.lines.concat(Buddy.leaves(root.ledger, 0, now),
            p.lines.filter(function (l) { return now - l.t <= Buddy.DAY })))
    }

    // ── actions ──────────────────────────────────────────────────────────
    function collapse(key) {
        var c = {}
        for (var x in root.collapsed) c[x] = root.collapsed[x]
        c[key] = !c[key]
        root.collapsed = c
        root.rebuild()
    }
    function reveal(sid) {
        var by = root.model.byId, s = by[sid]
        if (!s) return
        var key = Buddy.groupOf(s, by)
        if (root.collapsed[key]) root.collapse(key)
        var rows = root.model.rows
        for (var i = 0; i < rows.length; i++) if (rows[i].sid === sid) {
            list.contentY = Math.max(0, Math.min(rows[i].y - 26, list.contentHeight - list.height))
            return
        }
    }
    function verdict(row, word) {
        if (!row.knock || row.knock.mode !== "verdict") return
        var a = {}
        for (var x in root.answered) a[x] = root.answered[x]
        a[row.sid] = row.knock.cmd
        root.answered = a
        root.bridge.sendCommand({ cmd: "heraldverdict", id: row.sid, verdict: word })
        root.rebuild()
    }
    function focusRow(id) {
        if (id === "") return
        root.bridge.focusSession(id)
        root.hide()
    }
    function jump(ws) {
        if (ws === null) return
        Hyprland.dispatch("workspace " + ws)
        root.hide()
    }
    function recheck() {
        root.spinning = true
        spinStop.restart()
        root.bridge.recheckSessions()
    }
    function newTerminal() {
        Quickshell.execDetached(Kit.scopeArgv({ command: ["kitty"] }))
        root.hide()
    }
    function monitorOf(ws) {
        var w = (Hyprland.workspaces && Hyprland.workspaces.values) ? Hyprland.workspaces.values : []
        for (var i = 0; i < w.length; i++) if (w[i].id === ws) return w[i].monitor ? w[i].monitor.name : ""
        return ""
    }
    function hatch(w, h) {
        var d = ""
        for (var x = -h; x < w; x += 3) d += "M" + x + " " + h + " L" + (x + h) + " 0 "
        return d
    }

    // ── files ────────────────────────────────────────────────────────────
    FileView {
        id: sessionsFile
        path: root.stageDir + "sessions.json"
        watchChanges: true; blockLoading: false; printErrors: false
        onFileChanged: reload()
        onLoaded: { root.sessions = root.listOf(sessionsFile, "sessions"); root.spinning = false; root.mark(1) }
        onLoadFailed: { root.sessions = []; root.mark(1) }
    }
    FileView {
        id: hooksFile
        path: root.stageDir + "hooks.json"
        watchChanges: true; blockLoading: false; printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var h = root.listOf(hooksFile, "hooks"), at = {}
            for (var i = 0; i < h.length; i++) at[Buddy.str(h[i].sessionId)] = Buddy.ms(h[i].updatedAt)
            root.hooks = h
            root.hookAt = at
            root.mark(2)
        }
        onLoadFailed: { root.hooks = []; root.hookAt = ({}); root.mark(2) }
    }
    FileView {
        id: heraldFile
        path: root.stageDir + "herald.json"
        watchChanges: true; blockLoading: false; printErrors: false
        onFileChanged: reload()
        onLoaded: { root.notes = root.listOf(heraldFile, "notifications"); root.mark(4) }
        onLoadFailed: { root.notes = []; root.mark(4) }
    }
    FileView {
        id: ledgerFile
        path: root.aoideRoot + "/state/session-ledger.jsonl"
        watchChanges: true; blockLoading: false; printErrors: false
        onFileChanged: reload()
        onLoaded: { root.ledger = root.readLedger(ledgerFile); root.mark(8) }
        onLoadFailed: { root.ledger = []; root.mark(8) }
    }
    FileView {
        id: graphFile
        path: root.stageDir + "graph.json"
        watchChanges: true; blockLoading: false; printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var n = root.listOf(graphFile, "nodes"), at = {}
            for (var i = 0; i < n.length; i++) {
                var id = Buddy.str(n[i].id)
                if (id.indexOf("session:") === 0) at[id.slice(8)] = Buddy.ms(n[i].activeAt)
            }
            root.activeAt = at
            root.rebuild()
        }
    }
    FileView {
        id: hostFile
        path: "/etc/hostname"
        blockLoading: false; printErrors: false
        onLoaded: root.host = ("" + hostFile.text()).trim()
    }

    // ── parts ────────────────────────────────────────────────────────────
    component Glyph: Image {
        property string name: ""
        width: 12; height: 12
        sourceSize: Qt.size(width, height)
        source: name === "" ? "" : root.iconDir + "dock/" + name + ".svg" + root.bust
    }
    component Dash: Shape {
        id: ds
        property string d: ""
        property color stroke: Kit.dark(0.55)
        property real gap: 1
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: ds.stroke; strokeWidth: 1; fillColor: "transparent"
            strokeStyle: ShapePath.DashLine; dashPattern: [ds.gap, ds.gap]
            PathSvg { path: ds.d }
        }
    }
    component Orb: Item {
        id: orb
        property string st: ""
        property bool ring: true
        width: 12; height: 12
        Rectangle { visible: orb.ring; x: -2.5; y: -2.5; width: 17; height: 17; radius: 8.5; color: Kit.dark(0.55) }
        Rectangle { visible: orb.ring; x: -1.5; y: -1.5; width: 15; height: 15; radius: 7.5; color: "#ffffff" }
        Rectangle { visible: !orb.ring; x: -1; y: -1; width: 14; height: 14; radius: 7; color: Kit.dark(0.55) }
        Rectangle {
            anchors.fill: parent; radius: 6
            color: orb.st === "working" ? root.k.working : orb.st === "awaiting" ? root.k.awaiting
                 : orb.st === "idle" ? root.b16("base04", "#8db0ba") : orb.st === "done" ? root.livery.holoBlue : "#ffffff"
        }
        Rectangle {
            visible: orb.st === "working"; x: 1; y: 1; width: 10; height: 5; topLeftRadius: 5; topRightRadius: 5
            gradient: Gradient { GradientStop { position: 0; color: Kit.white(0.65) } GradientStop { position: 1; color: Kit.white(0.15) } }
        }
        Rectangle { visible: orb.st === "awaiting"; x: 3.5; y: 3; width: 1.5; height: 6; color: Kit.dark(1) }
        Rectangle { visible: orb.st === "awaiting"; x: 6.5; y: 3; width: 1.5; height: 6; color: Kit.dark(1) }
        Rectangle { visible: orb.st === "stopped"; x: 3.5; y: 3.5; width: 5; height: 5; radius: 1; color: Kit.dark(1) }
        Shape {
            visible: orb.st === "done"; anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Kit.dark(1); strokeWidth: 1.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathSvg { path: "M3.6 6.2 L5.3 7.9 L8.6 4.1" }
            }
        }
    }
    component PBox: Item {
        id: pb
        signal clicked()
        width: 13; height: 13
        Rectangle { anchors.fill: parent; color: "#020a0f" }
        Shape {
            x: 1; y: 1; width: 11; height: 11
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 11; y2: 11
                    GradientStop { position: 0; color: "#ffffff" }
                    GradientStop { position: 0.4; color: "#dcf0f2" }
                    GradientStop { position: 1; color: "#8fbdc7" }
                }
                PathSvg { path: "M0 0 H11 V11 H0 Z" }
            }
        }
        Rectangle { x: 1; y: 1; width: 11; height: 1; color: pm.pressed ? Kit.dark(0.45) : "#ffffff" }
        Rectangle { x: 1; y: 1; width: 1; height: 11; color: pm.pressed ? Kit.dark(0.45) : "#ffffff" }
        Rectangle { x: 1; y: 11; width: 11; height: 1; color: pm.pressed ? "#ffffff" : Kit.dark(0.45) }
        Rectangle { x: 11; y: 1; width: 1; height: 11; color: pm.pressed ? "#ffffff" : Kit.dark(0.45) }
        MouseArea { id: pm; anchors.fill: parent; onClicked: pb.clicked() }
    }
    component ArrowBox: Item {
        id: ab
        property bool up: true
        signal clicked()
        x: 1; width: 14; height: 15
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 14; y2: 15
                    GradientStop { position: 0; color: "#ffffff" }
                    GradientStop { position: 1; color: "#d4e8ec" }
                }
                PathSvg { path: "M0 0 H14 V15 H0 Z" }
            }
        }
        Rectangle { width: 14; height: 1; color: am.pressed ? Kit.dark(0.28) : "#ffffff" }
        Rectangle { width: 1; height: 15; color: am.pressed ? Kit.dark(0.28) : "#ffffff" }
        Rectangle { x: 13; width: 1; height: 15; color: am.pressed ? "#ffffff" : Kit.dark(0.28) }
        Rectangle { y: ab.up ? 14 : 0; width: 14; height: 1; color: Kit.dark(0.55) }
        Glyph { name: ab.up ? "up" : "dn"; width: 9; height: 6; anchors.centerIn: parent }
        MouseArea { id: am; anchors.fill: parent; onClicked: ab.clicked() }
    }
    component Pill: Rectangle {
        id: pl
        property string label: ""
        property bool live: true
        signal clicked()
        width: pt.implicitWidth + 22; height: 20; radius: 10
        border.width: 1; border.color: Kit.dark(0.6)
        opacity: pl.live ? 1 : 0.5
        Rectangle {
            x: 1; y: 1; width: parent.width - 2; height: 9; topLeftRadius: 9; topRightRadius: 9
            gradient: Gradient { GradientStop { position: 0; color: Kit.white(0.6) } GradientStop { position: 1; color: Kit.white(0.18) } }
        }
        Text { id: pt; anchors.centerIn: parent; text: pl.label; font.family: root.fUi; font.pixelSize: 11; font.bold: true; color: Kit.dark(1) }
        MouseArea { anchors.fill: parent; enabled: pl.live; cursorShape: Qt.PointingHandCursor; onClicked: pl.clicked() }
    }

    // ── A1 rim (glass) ───────────────────────────────────────────────────
    Rectangle {
        width: 384; height: 713
        topLeftRadius: 7; topRightRadius: 7; bottomLeftRadius: 4; bottomRightRadius: 4
        color: Kit.rimTint()
        border.width: 1; border.color: Kit.dark(0.85)
    }
    Rectangle {
        x: 1; y: 1; width: 382; height: 24; topLeftRadius: 6; topRightRadius: 6
        gradient: Gradient { GradientStop { position: 0; color: Kit.white(0.22) } GradientStop { position: 1; color: Kit.white(0.06) } }
    }
    Item {
        x: 1; y: 7; width: 382; height: 699; clip: true
        Shape {
            anchors.fill: parent
            ShapePath { strokeColor: "transparent"; fillColor: Kit.white(0.035); PathSvg { path: Kit.streaks(382, 699) } }
        }
    }
    Rectangle {
        x: 1; y: 1; width: 382; height: 711
        topLeftRadius: 6; topRightRadius: 6; bottomLeftRadius: 3; bottomRightRadius: 3
        color: "transparent"; border.width: 1; border.color: Kit.white(0.35)
    }

    // ── A2–A6 title bar ──────────────────────────────────────────────────
    Rectangle {
        x: 6; y: 6; width: 372; height: 23
        topLeftRadius: 3; topRightRadius: 3
        color: Kit.withA("#0f2b3c", 0.85)
        border.width: 1; border.color: "#041219"
        Rectangle {
            x: 1; y: 1; width: 370; height: 10; topLeftRadius: 2; topRightRadius: 2
            gradient: Gradient { GradientStop { position: 0; color: Kit.white(0.16) } GradientStop { position: 1; color: Kit.white(0.05) } }
        }
        Repeater {
            model: 4
            Item {
                required property int index
                Rectangle { x: 25; y: 6 + 3 * index; width: Math.max(0, ttl.x - 25); height: 1; color: Kit.white(0.42) }
                Rectangle { x: 25; y: 7 + 3 * index; width: Math.max(0, ttl.x - 25); height: 1; color: Qt.rgba(0, 6 / 255, 10 / 255, 0.85) }
                Rectangle { x: ttl.x + ttl.width; y: 6 + 3 * index; width: Math.max(0, 347 - ttl.x - ttl.width); height: 1; color: Kit.white(0.42) }
                Rectangle { x: ttl.x + ttl.width; y: 7 + 3 * index; width: Math.max(0, 347 - ttl.x - ttl.width); height: 1; color: Qt.rgba(0, 6 / 255, 10 / 255, 0.85) }
            }
        }
        Item {
            id: ttl
            x: Math.round((372 - width) / 2); y: 1; height: 21
            width: ttlRow.implicitWidth + 14
            Row {
                id: ttlRow
                x: 7; height: 21; spacing: 4
                Glyph { name: "proxy"; width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter }
                Text { height: 21; verticalAlignment: Text.AlignVCenter; text: "Agents"; font.family: root.fUi; font.pixelSize: 12; font.bold: true; color: "#ffffff"; style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.55) }
                Text { visible: root.model.counts.working > 0 || root.model.counts.awaiting > 0; height: 21; verticalAlignment: Text.AlignVCenter; text: "·"; font.family: root.fUi; font.pixelSize: 11; color: Kit.white(0.86) }
                Text { visible: root.model.counts.working > 0; height: 21; verticalAlignment: Text.AlignVCenter; text: root.model.counts.working + " working"; font.family: root.fUi; font.pixelSize: 11; color: "#9ff0d4" }
                Text { visible: root.model.counts.working > 0 && root.model.counts.awaiting > 0; height: 21; verticalAlignment: Text.AlignVCenter; text: "·"; font.family: root.fUi; font.pixelSize: 11; color: Kit.white(0.86) }
                Text { visible: root.model.counts.awaiting > 0; height: 21; verticalAlignment: Text.AlignVCenter; text: root.model.counts.awaiting + " awaiting"; font.family: root.fUi; font.pixelSize: 11; color: "#f6e39a" }
            }
        }
        PBox {
            x: 7; y: 5
            onClicked: root.hide()
            Rectangle { x: 3; y: 3; width: 7; height: 7; color: "transparent"; border.width: 1; border.color: Kit.dark(0.55) }
        }
        PBox {
            x: 352; y: 5
            onClicked: root.recheck()
            Glyph {
                id: rck
                name: "rck"; x: 2; y: 2; width: 9; height: 9
                RotationAnimation on rotation {
                    running: root.spinning; from: 0; to: 360; duration: 400; loops: Animation.Infinite
                    onStopped: rck.rotation = 0
                }
            }
        }
    }

    // ── A7 plate (children are plate-local; the plate's origin is window (6,28)) ──
    Rectangle {
        x: 6; y: 28; width: 372; height: 679
        bottomLeftRadius: 2; bottomRightRadius: 2
        color: Qt.rgba(245 / 255, 251 / 255, 251 / 255, 0.98)
        border.width: 1; border.color: "#041219"
        Rectangle { width: 372; height: 1; color: Kit.dark(0.85) }

        // A8 list
        Flickable {
            id: list
            x: 1; y: 1; width: 355; height: 486
            clip: true
            contentWidth: 355
            contentHeight: Math.max(root.model.height, 1)
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            onContentHeightChanged: if (contentY > Math.max(0, contentHeight - height)) contentY = Math.max(0, contentHeight - height)
            onContentYChanged: root.tip = null

            // A10 group headers
            Repeater {
                model: root.model.groups
                delegate: Item {
                    id: grp
                    required property var modelData
                    readonly property var g: modelData
                    y: g.y; width: 355; height: 26
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0; color: grp.g.collapsed ? "#eef6f7" : "#f6fbfc" }
                            GradientStop { position: 1; color: grp.g.collapsed ? "#d5e4e7" : "#dae9ec" }
                        }
                    }
                    Rectangle { width: 355; height: 1; color: "#ffffff" }
                    Rectangle { y: 25; width: 355; height: 1; color: Kit.dark(0.2) }
                    Glyph { x: 4; y: 8; width: 10; height: 10; name: grp.g.collapsed ? "tri-r" : "tri-d" }
                    MouseArea { width: 18; height: 26; cursorShape: Qt.PointingHandCursor; onClicked: root.collapse(grp.g.key) }
                    Item {
                        x: 20; y: 3; width: 44; height: 20
                        Rectangle { visible: grp.g.ws !== null; x: -1; y: -1; width: 46; height: 22; radius: 4; color: Kit.dark(0.5) }
                        Rectangle {
                            visible: grp.g.ws !== null; anchors.fill: parent; radius: 3; clip: true
                            gradient: Gradient { GradientStop { position: 0; color: "#2b5468" } GradientStop { position: 1; color: "#0c2130" } }
                            Rectangle {
                                anchors.fill: parent
                                color: grp.g.wash === "awaiting" ? Qt.rgba(232 / 255, 207 / 255, 106 / 255, 0.48)
                                     : grp.g.wash === "working" ? Qt.rgba(59 / 255, 220 / 255, 172 / 255, 0.38) : "transparent"
                            }
                            Rectangle {
                                width: parent.width; height: 10
                                gradient: Gradient { GradientStop { position: 0; color: Kit.white(0.18) } GradientStop { position: 1; color: Kit.white(0.04) } }
                            }
                            Rectangle { anchors.fill: parent; radius: 3; color: "transparent"; border.width: 1; border.color: Kit.white(0.25) }
                            Rectangle {
                                x: 2; y: 3; width: 11; height: 14; radius: 2; color: Kit.dark(0.9)
                                Text { anchors.centerIn: parent; text: "" + grp.g.ws; font.family: root.fUi; font.pixelSize: 9; font.weight: Font.DemiBold; color: "#ffffff" }
                            }
                            Row {
                                x: 15; y: 4; spacing: 1
                                Repeater {
                                    model: grp.g.minis
                                    Image { required property var modelData; width: 12; height: 12; sourceSize: Qt.size(12, 12); source: root.iconDir + "agents/" + modelData + ".svg" + root.bust }
                                }
                            }
                        }
                        Dash { visible: grp.g.ws === null; anchors.fill: parent; gap: 3; stroke: Kit.dark(0.38); d: "M0.5 0.5 H43.5 V19.5 H0.5 Z" }
                        Row {
                            visible: grp.g.ws === null; anchors.centerIn: parent; spacing: 2; opacity: 0.55
                            Repeater {
                                model: grp.g.minis
                                Image { required property var modelData; width: 12; height: 12; sourceSize: Qt.size(12, 12); source: root.iconDir + "agents/" + modelData + ".svg" + root.bust }
                            }
                        }
                    }
                    Text { id: glab; x: 70; height: 26; verticalAlignment: Text.AlignVCenter; text: grp.g.label; font.family: root.fUi; font.pixelSize: 11; font.bold: true; color: Kit.dark(1) }
                    Text { x: glab.x + glab.implicitWidth + 6; height: 26; verticalAlignment: Text.AlignVCenter; text: grp.g.count; font.family: root.fUi; font.pixelSize: 10; color: Kit.dark(0.55) }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 8; height: 26; verticalAlignment: Text.AlignVCenter
                        text: grp.g.ws === null ? "no window" : root.monitorOf(grp.g.ws)
                        font.family: root.fUi; font.pixelSize: 10; color: Kit.dark(0.55)
                    }
                    MouseArea {
                        visible: grp.g.ws !== null; x: 20; width: glab.x + glab.implicitWidth - 20; height: 26
                        cursorShape: Qt.PointingHandCursor; onClicked: root.jump(grp.g.ws)
                    }
                }
            }

            // A11 rows (+ A12 knock)
            Repeater {
                model: root.model.rows
                delegate: Item {
                    id: row
                    required property var modelData
                    readonly property var r: modelData
                    readonly property int bx: r.sub ? 25 : 3
                    readonly property int bw: r.sub ? 327 : 349
                    readonly property bool clickable: r.clickId !== ""
                    readonly property bool dim: r.state === "idle" || r.state === "done"
                    readonly property bool sel: hov.hovered && clickable
                    y: r.y; width: 355; height: r.h

                    Dash { visible: row.r.sub; x: row.bx - 12; y: -5; width: 9; height: 22; d: "M0.5 0 V21.5 H9" }

                    Rectangle {
                        x: row.bx; y: 1; width: row.bw; height: 36
                        topLeftRadius: 3; topRightRadius: 3
                        bottomLeftRadius: row.r.knock ? 0 : 3; bottomRightRadius: row.r.knock ? 0 : 3
                        border.width: 1
                        border.color: row.sel ? "#84cfdb" : row.r.state === "awaiting" ? root.edgeGold : "transparent"
                        gradient: Gradient {
                            GradientStop { position: 0; color: row.r.state === "awaiting" ? root.wash30 : row.sel ? "#f1fbfc" : "transparent" }
                            GradientStop { position: 1; color: row.r.state === "awaiting" ? Qt.rgba(232 / 255, 207 / 255, 106 / 255, 0.18) : row.sel ? "#cfeef4" : "transparent" }
                        }
                        Rectangle {
                            visible: row.sel && row.r.state !== "awaiting"
                            anchors.fill: parent; anchors.margins: 1; radius: 2
                            color: "transparent"; border.width: 1; border.color: Kit.white(0.75)
                        }
                        Glyph { visible: row.r.state === "awaiting"; name: "knock"; x: 1; y: 6; width: 7; height: 22 }
                        Image {
                            x: 9; y: 3; width: 28; height: 28
                            sourceSize: Qt.size(28, 28)
                            source: root.iconDir + "agents/" + row.r.icon + ".svg" + root.bust
                            opacity: row.r.state === "done" ? 0.5 : row.r.state === "idle" ? 0.62 : 1
                            rotation: row.r.state === "awaiting" ? -6 : 0
                            layer.enabled: row.dim
                            layer.effect: MultiEffect { saturation: row.r.state === "done" ? -0.7 : -0.45 }
                            SequentialAnimation on rotation {
                                running: root.shown && row.r.state === "awaiting"
                                loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 90 }
                                NumberAnimation { to: -6; duration: 90 }
                                NumberAnimation { to: 0; duration: 90 }
                                NumberAnimation { to: -6; duration: 90 }
                                PauseAnimation { duration: 3640 }
                            }
                        }
                        Orb { x: 28; y: 22; st: row.r.state }
                        Text {
                            id: lab
                            x: 44; y: 3; height: 15
                            width: Math.min(implicitWidth, row.bw - 100 - (word.text === "" ? 0 : word.implicitWidth + 6))
                            text: row.r.label; textFormat: Text.PlainText; elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                            font.family: root.fUi; font.pixelSize: 11; font.bold: true; font.italic: row.r.state === "done"
                            color: row.dim ? Kit.dark(0.55) : Kit.dark(1)
                        }
                        Text {
                            id: word
                            x: lab.x + lab.width + 6; anchors.baseline: lab.baseline
                            text: row.r.word.toUpperCase()
                            font.family: root.fUi; font.pixelSize: 8; font.bold: true; font.letterSpacing: 0.5
                            color: row.r.state === "working" ? "#138a66" : row.r.state === "awaiting" ? "#7a5c00" : Kit.dark(0.55)
                        }
                        Item {
                            x: 44; y: 19; width: row.bw - 100; height: 14; clip: true
                            Glyph { visible: row.r.say; name: "note"; y: 2; width: 10; height: 10 }
                            Text {
                                id: pre
                                x: row.r.say ? 13 : 0; height: 14; verticalAlignment: Text.AlignVCenter
                                text: row.r.pre; font.family: root.fUi; font.pixelSize: 10; color: Kit.dark(0.72)
                            }
                            Text {
                                id: mono
                                x: pre.x + pre.implicitWidth; height: 14; verticalAlignment: Text.AlignVCenter
                                width: Math.min(implicitWidth, Math.max(0, parent.width - x)); elide: Text.ElideRight
                                text: row.r.mono; textFormat: Text.PlainText
                                font.family: root.fMono; font.pixelSize: 10; color: row.dim ? Kit.dark(0.55) : Kit.dark(1)
                            }
                            Text {
                                x: mono.x + mono.width; height: 14; verticalAlignment: Text.AlignVCenter
                                width: Math.max(0, parent.width - x); elide: Text.ElideRight
                                text: Buddy.fill(row.r.post, root.now - row.r.activeMs); textFormat: Text.PlainText
                                font.family: root.fUi; font.pixelSize: 10; font.italic: row.r.say
                                color: row.r.state === "done" ? Kit.dark(0.38) : row.r.state === "idle" ? Kit.dark(0.55) : Kit.dark(0.72)
                            }
                        }
                        Item {
                            visible: row.r.pct >= 0
                            x: row.bw - 49; y: 3; width: 42; height: 18
                            Rectangle {
                                width: 42; height: 6; radius: 3; clip: true
                                color: Kit.dark(0.16); border.width: 1; border.color: Kit.dark(0.28)
                                Rectangle {
                                    width: Math.round(42 * row.r.pct / 100); height: 6; radius: 3
                                    color: row.r.tone === "hot" ? root.livery.paletteUrgent : row.r.tone === "warn" ? root.k.awaiting : root.k.working
                                    Rectangle {
                                        width: parent.width; height: 4; radius: 2
                                        gradient: Gradient { GradientStop { position: 0; color: Kit.white(0.65) } GradientStop { position: 1; color: Kit.white(0) } }
                                    }
                                }
                            }
                            Text { y: 8; width: 42; height: 10; horizontalAlignment: Text.AlignRight; text: row.r.pct + "%"; font.family: root.fUi; font.pixelSize: 9; color: Kit.dark(0.55) }
                        }
                        HoverHandler {
                            id: hov
                            onHoveredChanged: {
                                if (hovered && row.r.tip) tipTimer.restart()
                                else { tipTimer.stop(); if (root.tip === row.r.tip) root.tip = null }
                            }
                        }
                        Timer { id: tipTimer; interval: 500; onTriggered: { root.tipTop = 29 + row.y + 1 - list.contentY; root.tip = row.r.tip } }
                        MouseArea { anchors.fill: parent; enabled: row.clickable; cursorShape: Qt.PointingHandCursor; onClicked: root.focusRow(row.r.clickId) }
                    }

                    Rectangle {
                        visible: !!row.r.knock
                        x: row.bx; y: 37; width: row.bw; height: 30
                        bottomLeftRadius: 3; bottomRightRadius: 3
                        border.width: 1; border.color: root.edgeGold
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.rgba(232 / 255, 207 / 255, 106 / 255, 0.18) }
                            GradientStop { position: 1; color: Qt.rgba(232 / 255, 207 / 255, 106 / 255, 0.10) }
                        }
                        Rectangle {
                            x: 43; y: 4; height: 20; width: Math.max(0, pills.x - 6 - x)
                            color: "#ffffff"; border.width: 1; border.color: Kit.dark(0.42)
                            Rectangle { x: 1; y: 1; width: parent.width - 2; height: 1; color: Kit.dark(0.18) }
                            Rectangle { x: 1; y: 1; width: 1; height: parent.height - 2; color: Kit.dark(0.18) }
                            Text {
                                x: 6; width: parent.width - 11; anchors.verticalCenter: parent.verticalCenter
                                text: row.r.knock ? row.r.knock.cmd : ""; textFormat: Text.PlainText; elide: Text.ElideRight
                                font.family: root.fMono; font.pixelSize: 10; color: Kit.dark(1)
                            }
                        }
                        Row {
                            id: pills
                            x: parent.width - 7 - width; y: 4; spacing: 6
                            Pill {
                                visible: !!row.r.knock && row.r.knock.mode !== "terminal"
                                label: "Approve"; color: root.livery.paletteHot
                                live: !!row.r.knock && row.r.knock.mode === "verdict"
                                onClicked: root.verdict(row.r, "approve")
                            }
                            Pill {
                                visible: !!row.r.knock && row.r.knock.mode !== "terminal"
                                label: "Deny"; color: root.livery.notifUrgent
                                live: !!row.r.knock && row.r.knock.mode === "verdict"
                                onClicked: root.verdict(row.r, "deny")
                            }
                            Pill {
                                visible: !!row.r.knock && row.r.knock.mode === "terminal"
                                label: "Answer in terminal ↗"; color: "#ffffff"
                                live: row.clickable
                                onClicked: root.focusRow(row.r.clickId)
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.model.total === 0
            x: 1; y: 1; width: 355; height: 486
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            text: "Nobody's in the room."; font.family: root.fUi; font.pixelSize: 11; color: Kit.dark(0.55)
        }

        // A9 scrollbar
        Item {
            id: sb
            x: 356; y: 1; width: 15; height: 486
            readonly property real span: list.contentHeight - list.height
            readonly property real th: Math.max(20, Math.round(456 * list.height / Math.max(list.contentHeight, 1)))
            Rectangle { anchors.fill: parent; color: "#dcebee" }
            Item {
                anchors.fill: parent; clip: true
                Shape {
                    anchors.fill: parent
                    ShapePath { strokeColor: Kit.dark(0.05); strokeWidth: 1; fillColor: "transparent"; PathSvg { path: root.hatch(15, 486) } }
                }
            }
            Rectangle { width: 1; height: 486; color: Kit.dark(0.55) }
            Rectangle { x: 1; width: 1; height: 486; color: Kit.dark(0.10) }
            ArrowBox { y: 0; up: true; onClicked: list.contentY = Math.max(0, list.contentY - 37) }
            ArrowBox { y: 471; up: false; onClicked: list.contentY = Math.min(Math.max(0, sb.span), list.contentY + 37) }
            Rectangle {
                id: thumb
                visible: sb.span > 0
                x: 1; width: 14; height: sb.th
                y: 15 + (sb.span > 0 ? Math.round((456 - sb.th) * list.contentY / sb.span) : 0)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#d6f2f6" }
                    GradientStop { position: 0.55; color: "#a8dde6" }
                    GradientStop { position: 1; color: "#85c9d4" }
                }
                Rectangle { width: 14; height: 1; color: Kit.dark(0.7) }
                Rectangle { y: thumb.height - 1; width: 14; height: 1; color: Kit.dark(0.7) }
                Rectangle { y: 1; width: 14; height: 1; color: Kit.white(0.85) }
                Rectangle { y: 1; width: 1; height: thumb.height - 2; color: Kit.white(0.85) }
                Rectangle { x: 13; y: 1; width: 1; height: thumb.height - 2; color: Kit.dark(0.25) }
                Repeater {
                    model: 4
                    Item {
                        required property int index
                        Rectangle { x: 2; y: Math.round(thumb.height / 2) - 5 + 3 * index; width: 9; height: 1; color: Kit.white(0.95) }
                        Rectangle { x: 2; y: Math.round(thumb.height / 2) - 4 + 3 * index; width: 9; height: 1; color: Kit.dark(0.55) }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    property real grab: 0
                    onPressed: function (m) { grab = m.y }
                    onPositionChanged: function (m) {
                        var span = 456 - thumb.height
                        if (span <= 0 || sb.span <= 0) return
                        var top = Math.max(0, Math.min(span, thumb.y - 15 + m.y - grab))
                        list.contentY = sb.span * top / span
                    }
                }
            }
        }

        // A13 divider
        Item {
            x: 1; y: 487; width: 370; height: 9
            Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "#e7f1f3" } GradientStop { position: 1; color: "#d2e3e7" } } }
            Rectangle { width: 370; height: 1; color: Kit.dark(0.35) }
            Rectangle { y: 8; width: 370; height: 1; color: Kit.dark(0.2) }
            Repeater {
                model: 9
                Item {
                    required property int index
                    Rectangle { x: 172 + 3 * index; y: 2; width: 1; height: 5; color: Kit.white(0.95) }
                    Rectangle { x: 173 + 3 * index; y: 2; width: 1; height: 5; color: Kit.dark(0.5) }
                }
            }
        }

        // A14 room header
        Item {
            x: 1; y: 496; width: 370; height: 20
            Glyph { name: "join"; x: 8; y: 4 }
            Text { id: roomT; x: 25; height: 20; verticalAlignment: Text.AlignVCenter; text: "Room"; font.family: root.fUi; font.pixelSize: 11; font.bold: true; color: Kit.dark(1) }
            Text {
                x: roomT.x + roomT.implicitWidth + 5; height: 20; verticalAlignment: Text.AlignVCenter
                text: root.host === "" ? "" : "#" + root.host; textFormat: Text.PlainText
                font.family: root.fUi; font.pixelSize: 10; color: Kit.dark(0.55)
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 8; height: 20; verticalAlignment: Text.AlignVCenter
                text: "joins · leaves · states · herald"; font.family: root.fUi; font.pixelSize: 10; color: Kit.dark(0.55)
            }
        }

        // A15 room log
        Rectangle { x: 6; y: 515; width: 360; height: 130; color: "transparent"; border.width: 1; border.color: Kit.dark(0.18) }
        Rectangle {
            x: 7; y: 516; width: 358; height: 128; color: "#ffffff"
            Rectangle { width: 358; height: 1; color: Kit.dark(0.6) }
            Rectangle { width: 1; height: 128; color: Kit.dark(0.6) }
            Rectangle { x: 1; y: 1; width: 356; height: 1; color: Kit.dark(0.15) }
            Rectangle { x: 1; y: 1; width: 1; height: 126; color: Kit.dark(0.15) }
            Flickable {
                id: logView
                x: 1; y: 4; width: 356; height: 120
                clip: true
                contentWidth: 356
                contentHeight: Math.max(height, logCol.height)
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                function toEnd() { logView.contentY = Math.max(0, logView.contentHeight - logView.height) }
                onContentHeightChanged: if (root.logStick) logView.toEnd()
                Column {
                    id: logCol
                    y: Math.max(0, logView.height - height)
                    width: 356
                    Repeater {
                        model: root.feed
                        delegate: Item {
                            id: ln
                            required property var modelData
                            readonly property var l: modelData
                            readonly property bool ask: l.kind === "ask"
                            readonly property bool open: ask && !!root.model.byId[l.sid] && Buddy.str(root.model.byId[l.sid].state) === "awaiting"
                            width: 356; height: 17
                            Rectangle {
                                visible: ln.ask; anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: Qt.rgba(232 / 255, 207 / 255, 106 / 255, 0.32) }
                                    GradientStop { position: 1; color: Qt.rgba(232 / 255, 207 / 255, 106 / 255, 0.08) }
                                }
                            }
                            Text { x: 6; width: 38; height: 17; verticalAlignment: Text.AlignVCenter; text: "[" + Buddy.hm(ln.l.t) + "]"; font.family: root.fMono; font.pixelSize: 9; color: Kit.dark(0.38) }
                            Glyph { visible: ln.l.glyph !== ""; x: 48; y: 2; name: ln.l.glyph }
                            Orb { visible: ln.l.orb !== ""; x: 48; y: 2; st: ln.l.orb; ring: false }
                            Text {
                                id: nk
                                x: 64; width: Math.min(implicitWidth, 150); height: 17; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                                text: ln.l.nick; textFormat: Text.PlainText
                                font.family: root.fUi; font.pixelSize: 10; font.bold: true; color: ln.l.color
                            }
                            Text { id: asks; visible: ln.ask; x: nk.x + nk.width + 4; height: 17; verticalAlignment: Text.AlignVCenter; text: "asks ·"; font.family: root.fUi; font.pixelSize: 10; color: Kit.dark(1) }
                            Text {
                                id: tool
                                visible: ln.ask; x: asks.x + asks.implicitWidth + 4; height: 17; verticalAlignment: Text.AlignVCenter
                                text: ln.l.tool; textFormat: Text.PlainText; font.family: root.fMono; font.pixelSize: 10; color: Kit.dark(1)
                            }
                            Text {
                                x: ln.ask ? tool.x + tool.implicitWidth + 4 : nk.x + nk.width + 4
                                width: Math.max(0, (ln.open ? go.x - 4 : 350) - x); height: 17
                                elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                                text: ln.l.text; textFormat: Text.PlainText
                                font.family: root.fUi; font.pixelSize: 10; color: ln.ask ? Kit.dark(1) : Kit.dark(0.72)
                            }
                            Text {
                                id: go
                                visible: ln.open; x: 350 - implicitWidth; height: 17; verticalAlignment: Text.AlignVCenter
                                text: "row ↑"; font.family: root.fUi; font.pixelSize: 10; font.underline: true; color: "#7a5c00"
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.reveal(ln.l.sid) }
                            }
                        }
                    }
                }
            }
        }

        // A16 foot
        Item {
            x: 1; y: 644; width: 370; height: 34
            Rectangle {
                x: 6; y: 6; height: 22; width: termRow.implicitWidth + 22; radius: 4
                border.width: 1; border.color: Kit.dark(0.8)
                gradient: Gradient {
                    GradientStop { position: 0; color: tm.pressed ? "#cfe2e6" : "#ffffff" }
                    GradientStop { position: 0.55; color: "#e2eff1" }
                    GradientStop { position: 1; color: tm.pressed ? "#ffffff" : "#cfe2e6" }
                }
                Rectangle { x: 1; y: 1; width: parent.width - 2; height: 1; color: "#ffffff" }
                Row {
                    id: termRow
                    x: 11; height: 22; spacing: 5
                    Glyph { name: "term"; width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter }
                    Text { height: 22; verticalAlignment: Text.AlignVCenter; text: "New terminal"; font.family: root.fUi; font.pixelSize: 11; font.bold: true; color: Kit.dark(1) }
                }
                MouseArea { id: tm; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.newTerminal() }
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 6; height: 34; verticalAlignment: Text.AlignVCenter
                text: root.model.total + (root.model.total === 1 ? " session" : " sessions") + (root.host === "" ? "" : " · " + root.host)
                textFormat: Text.PlainText; font.family: root.fUi; font.pixelSize: 10; color: Kit.dark(0.55)
            }
        }
    }

    // ── Elsewhere tooltip (window coordinates) ───────────────────────────
    Rectangle {
        visible: root.tip !== null
        z: 10
        x: 20; width: 300
        height: tipCol.implicitHeight + 12
        y: root.tipTop + 39 + height > 700 ? root.tipTop - height - 2 : root.tipTop + 39
        radius: 7; color: "#ffffff"; border.width: 1; border.color: "#1d1d1d"
        Column {
            id: tipCol
            x: 7; y: 6; width: parent.width - 14; spacing: 2
            Text { id: tipT; width: parent.width; wrapMode: Text.Wrap; textFormat: Text.PlainText; text: root.tip ? root.tip.title : ""; font.family: root.fUi; font.pixelSize: 11; font.bold: true; color: Kit.dark(1) }
            Text { id: tipS; visible: text !== ""; width: parent.width; wrapMode: Text.Wrap; textFormat: Text.PlainText; text: root.tip ? root.tip.say : ""; font.family: root.fUi; font.pixelSize: 10; font.italic: true; color: Kit.dark(0.72) }
        }
    }
}
