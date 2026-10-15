import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import "../.."
import "Kit.js" as Kit
import "Rice.js" as Rice
import "Power.js" as Power

Item {
    id: root

    required property var livery
    required property var bridge
    property var shared: null
    property var powermenu: null
    property var dock: null
    property var stagingEngine: null

    readonly property var kit: Kit.make(root.livery)

    implicitHeight: 0
    width: parent ? parent.width : implicitWidth

    property int tick: 0
    Connections {
        target: Hyprland
        function onRawEvent(e) {
            if (e.name === "activespecial") { Hyprland.refreshWorkspaces(); Hyprland.refreshMonitors() }
            settle.restart()
        }
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { settle.restart() }
    }
    Timer { id: settle; interval: 60; onTriggered: root.tick++ }

    readonly property int rigPeek: parseInt(Quickshell.env("AOIDE_RIG_PEEK") || "-1")
    readonly property string bust: "?v=" + Date.now()
    readonly property string appGlyph: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/song/songbook/barcarolle/icons/launcher/finder-app.svg" + root.bust
    readonly property string iconDir: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/song/songbook/barcarolle/icons/"
    readonly property string trayDir: root.iconDir + "tray/"

    property var sessByAddr: ({})
    property int awaitingCount: 0
    property int workingCount: 0

    property string coverPath: Quickshell.env("AOIDE_WALLPAPER") || ""
    property bool coverTile: false
    FileView {
        path: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/song/stage/cover.json"
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var baked = Quickshell.env("AOIDE_WALLPAPER") || ""
            try {
                var d = JSON.parse(text())
                var applies = !!(d && d.path && (!d.song || d.song === root.livery.songName))
                root.coverPath = applies ? "" + d.path : baked
                root.coverTile = applies && d.pick === true && d.tile === true
            } catch (e) { root.coverPath = baked; root.coverTile = false }
        }
        onLoadFailed: { root.coverPath = Quickshell.env("AOIDE_WALLPAPER") || ""; root.coverTile = false }
    }
    FileView {
        id: stage
        path: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/state/stage/sessions.json"
        watchChanges: true
        blockLoading: false
        printErrors: false
        onLoaded: root.parseStage()
        onFileChanged: reload()
    }
    property int heraldCount: 0
    FileView {
        path: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/state/stage/herald.json"
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { root.heraldCount = (JSON.parse(text()).notifications || []).length } catch (e) {}
        }
        onLoadFailed: root.heraldCount = 0
    }

    function bare(addr) { return ("" + (addr || "")).toLowerCase().replace(/^0x/, "") }

    function parseStage() {
        var by = {}, aw = 0, wk = 0
        try {
            var o = JSON.parse(stage.text())
            var l = (o && o.sessions) ? o.sessions : []
            for (var i = 0; i < l.length; i++) {
                var st = ("" + (l[i].state || "")).toLowerCase()
                if (st === "awaiting") aw++
                if (st === "working") wk++
                if (l[i].windowAddress) by[root.bare(l[i].windowAddress)] = { state: st, tool: ("" + (l[i].tool || "")).split(":")[0].trim() }
            }
        } catch (err) {}
        root.sessByAddr = by
        root.awaitingCount = aw
        root.workingCount = wk
    }

    function iconFor(cls) {
        if (!cls) return ""
        var e = DesktopEntries.heuristicLookup(cls)
        var p = e && e.icon ? Quickshell.iconPath(e.icon, true) : ""
        if (!p) p = Quickshell.iconPath(cls, true)
        if (!p) p = Quickshell.iconPath(cls.toLowerCase(), true)
        if (!p) p = Quickshell.iconPath("application-x-executable", true)
        if (!p) p = root.appGlyph
        return p
    }
    readonly property var trayArt: ({ "Claude_status_icon_1": root.iconDir + "agents/claude.svg", "Fcitx": root.trayDir + "apps/fcitx.svg" })
    function trayPics(item) {
        var id = "" + (item.id || ""), title = "" + (item.title || "")
        var e = (id && (DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id))) || (title && DesktopEntries.heuristicLookup(title))
        var p = e && e.icon ? Quickshell.iconPath(e.icon, true) : ""
        var out = p ? [p] : []
        if (root.trayArt[id]) out.push(root.trayArt[id])
        return out
    }

    function build(screenName) {
        root.tick
        if (!screenName) return { rows: [], drawers: [], lists: {} }
        var wss = (Hyprland.workspaces && Hyprland.workspaces.values) ? Hyprland.workspaces.values : []
        var tops = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : []
        var mons = (Hyprland.monitors && Hyprland.monitors.values) ? Hyprland.monitors.values : []
        var front = Hyprland.activeToplevel ? Hyprland.activeToplevel.address : ""
        var rows = [], drawers = [], lists = {}
        for (var i = 0; i < wss.length; i++) {
            var w = wss[i]
            if (!w) continue
            var shown = null
            for (var q = 0; w.id < 0 && q < mons.length; q++) {
                var sp = mons[q].lastIpcObject ? mons[q].lastIpcObject.specialWorkspace : null
                if (sp && sp.name === w.name) shown = mons[q]
            }
            if (!shown && !w.monitor) continue
            var mon = shown ? shown.name : w.monitor.name
            var away = mon !== screenName
            var list = []
            for (var j = 0; j < tops.length; j++) {
                var t = tops[j]
                if ((t.workspace ? t.workspace.id : -1) !== w.id) continue
                var c = Kit.className(t)
                var fh = t.lastIpcObject && t.lastIpcObject.focusHistoryID !== undefined ? t.lastIpcObject.focusHistoryID : 999
                var se = root.sessByAddr[root.bare(t.address)]
                list.push({
                    address: t.address, cls: c, title: t.title || c, icon: root.iconFor(c),
                    front: t.address === front, rank: t.address === front ? -1 : fh,
                    state: se ? se.state : "", tool: se ? se.tool : ""
                })
            }
            list.sort(function (a, b) { return a.rank - b.rank })
            var aw = 0, wk = 0
            for (var k = 0; k < list.length; k++) {
                if (list[k].state === "awaiting") aw++
                if (list[k].state === "working") wk++
            }
            lists[w.id] = list
            var m = {
                id: w.id,
                name: ("" + w.name).replace(/^special:/, ""),
                ws: w,
                wins: list.length,
                icons: list.map(function (x) { return x.icon }),
                active: w.id < 0 ? !!shown : w.active === true,
                urgent: w.urgent === true,
                awaiting: aw,
                working: wk,
                mon: mon,
                away: away
            }
            if (m.wins === 0 && !m.active && !(w.lastIpcObject && w.lastIpcObject.ispersistent)) continue
            if (w.id > 0) rows.push(m)
            else drawers.push(m)
        }
        rows.sort(function (a, b) { return a.id - b.id })
        drawers.sort(function (a, b) { return a.name < b.name ? -1 : 1 })
        return { rows: rows, drawers: drawers, lists: lists }
    }

    function nextEmpty() {
        var used = {}
        var wss = Hyprland.workspaces.values
        for (var k = 0; k < wss.length; k++) used[wss[k].id] = true
        var n = 1
        while (used[n]) n++
        return n
    }

    property date now: new Date()
    Timer {
        interval: Kit.tickInterval
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    property string flyout: ""
    property string flyoutGone: ""
    property real flyoutGoneAt: 0
    property string volView: "main"
    property string volPickKind: "out"
    property string volBack: "main"
    readonly property int volH: 305
    readonly property int volW: root.volView === "list" ? 200 : root.volView === "mixer" ? 360 : 84
    property string trayTip: ""
    property int trayCount: 0
    function recountTray() {
        var n = SystemTray.items.values.length
        if (n === 0 && root.flyout === "tray") root.flyout = ""
        root.trayCount = n
    }
    Connections {
        target: SystemTray.items
        function onObjectInsertedPost() { root.recountTray() }
        function onObjectRemovedPost() { root.recountTray() }
    }
    Component.onCompleted: root.recountTray()

    function toggleFlyout(name) {
        if (root.flyout === name) { root.flyout = ""; return }
        if (root.flyoutGone === name && Date.now() - root.flyoutGoneAt <= 250) return
        var was = root.flyout
        root.flyout = ""
        if (was === "") root.flyout = name
        else Qt.callLater(function () { root.flyout = name })
    }
    onFlyoutChanged: {
        if (root.flyout === "") return
        if (root.flyout === "volume") root.volView = "main"
        win.hotId = -1
        win.hotBtn = null
        if (root.flyout === "start") sm.reset()
        if (root.dock && typeof root.dock.hide === "function") root.dock.hide()
        var menu = riceSlot._item
        if (menu && menu.open) menu.open = false
        root.claimFlyouts()
    }
    property string flyoutShown: ""
    readonly property bool catching: root.flyoutShown !== "" || (!!riceSlot._item && !!riceSlot._item.open)
    function dropFlyouts() {
        root.flyout = ""
        var menu = riceSlot._item
        if (menu && menu.open) menu.open = false
    }
    function claimFlyouts() {
        var other = Kit.hub.flyoutBar
        if (other && other !== root) { try { other.dropFlyouts() } catch (e) {} }
        Kit.hub.flyoutBar = root
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.catching
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "aoide-catch"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.dropFlyouts()
            }
        }
    }
    readonly property bool flyoutOpen: root.flyout !== "" || (!!root.dock && !!root.dock.shown && root.dock.targetScreen === win.screen)
    onFlyoutOpenChanged: {
        if (!win.screen) return
        Kit.hub.open = Kit.hub.open || {}
        Kit.hub.open[win.screen.name] = root.flyoutOpen
    }
    Connections {
        target: root.dock
        ignoreUnknownSignals: true
        function onShownChanged() { if (root.dock && root.dock.shown) root.flyout = "" }
    }
    Connections {
        target: riceSlot._item
        ignoreUnknownSignals: true
        function onOpenChanged() { var menu = riceSlot._item; if (menu && menu.open) { root.flyout = ""; root.claimFlyouts() } }
    }

    readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    readonly property var mic: Pipewire.ready ? Pipewire.defaultAudioSource : null
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    PwObjectTracker { objects: root.mic ? [root.mic] : [] }
    readonly property var sinkAudio: root.sink && root.sink.audio ? root.sink.audio : null
    readonly property real volLevel: root.sinkAudio ? root.sinkAudio.volume : 0
    readonly property bool volMuted: root.sinkAudio ? root.sinkAudio.muted : false
    readonly property bool volSilent: !root.sinkAudio || root.volMuted || root.volLevel <= 0
    function setNodeVolume(n, v) {
        var a = n && n.audio
        if (!a) return
        a.volume = Math.max(0, Math.min(1, v))
        if (v > 0 && a.muted) a.muted = false
    }
    function setNodeMuted(n, m) { if (n && n.audio) n.audio.muted = m }
    function pickSink(n) { if (n) Pipewire.preferredDefaultAudioSink = n }
    function pickSource(n) { if (n) Pipewire.preferredDefaultAudioSource = n }
    function setVolume(v) { root.setNodeVolume(root.sink, v) }
    function nudgeVolume(delta) { root.setVolume(root.volLevel + delta) }
    function runDetached(name) { Quickshell.execDetached(["systemd-run", "--user", "--scope", name]) }

    property int pwEpoch: 0
    Connections {
        target: Pipewire.nodes
        function onObjectInsertedPost() { root.pwEpoch++ }
        function onObjectRemovedPost() { root.pwEpoch++ }
    }
    function pwNodes(want) {
        var epoch = root.pwEpoch
        var vals = Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values ? Pipewire.nodes.values : []
        var o = []
        for (var i = 0; i < vals.length; i++) {
            var n = vals[i]
            if (!n || !(n.type & PwNodeType.Audio)) continue
            if (want === "stream") { if (n.isStream) o.push(n); continue }
            if (!n.isStream && n.isSink === (want === "out")) o.push(n)
        }
        return o
    }
    readonly property var outNodes: root.pwNodes("out")
    readonly property var inNodes: root.pwNodes("in")
    readonly property var streamNodes: root.pwNodes("stream")
    PwObjectTracker { objects: root.outNodes.concat(root.inNodes, root.streamNodes) }
    readonly property var appNodes: {
        var o = []
        for (var i = 0; i < root.streamNodes.length; i++) {
            var n = root.streamNodes[i]
            var p = n.properties || ({})
            if (!n.ready || ("" + p["stream.monitor"]) === "true") continue
            if ((n.type & PwNodeType.AudioOutStream) !== PwNodeType.AudioOutStream) continue
            o.push(n)
        }
        return o
    }
    function nodeLabel(n) {
        var s = "" + (n.nickname || n.description || n.name || "")
        return s.length > 0 ? s : "node " + n.id
    }
    function nodeGloss(n) {
        var s = "" + (n.name || "")
        var dot = s.lastIndexOf(".")
        var tail = dot >= 0 ? s.substring(dot + 1) : s
        return tail.length > 18 ? tail.substring(0, 17) + "…" : tail
    }
    function streamLabel(n) {
        var p = n.properties || ({})
        var s = "" + (p["application.name"] || n.description || n.name || "")
        return s.length > 0 ? s : "node " + n.id
    }
    function devPic(n, out) {
        if (!out) return root.trayDir + "dev-mic.svg"
        var p = n && n.properties ? n.properties : ({})
        var s = ("" + (n ? n.name : "") + " " + (n ? n.nickname : "")).toLowerCase()
        var ff = ("" + (p["device.form-factor"] || "")).toLowerCase()
        if (ff === "tv" || ff === "monitor" || s.indexOf("hdmi") >= 0 || s.indexOf("displayport") >= 0) return root.trayDir + "dev-hdmi.svg"
        if (/headphone|headset|hands-free/.test(ff) || /headphone|headset|arctis/.test(s)) return root.trayDir + "dev-headphones.svg"
        return root.trayDir + "dev-speakers.svg"
    }
    function appPic(n) {
        var p = n.properties || ({})
        return root.iconFor("" + (p["application.process.binary"] || p["application.name"] || ""))
    }
    function openList(kind, back) {
        root.volPickKind = kind
        root.volBack = back
        root.volView = "list"
    }

    property bool netUp: false
    property string netName: ""
    property string netKind: "wired"
    property string netAccess: ""
    property bool netViaRoute: false
    FileView { id: routeFile; path: "/proc/net/route"; blockLoading: true; printErrors: false }
    function netScan() {
        var devs = Networking.devices && Networking.devices.values ? Networking.devices.values : []
        var up = false, name = "", kind = "wired", route = devs.length === 0
        for (var i = 0; i < devs.length && !up; i++) {
            if (!devs[i].connected) continue
            up = true
            name = devs[i].name
            kind = devs[i].type === DeviceType.Wifi ? "wifi" : "wired"
            var nets = kind === "wifi" && devs[i].networks ? devs[i].networks.values : []
            for (var k = 0; k < nets.length; k++) if (nets[k].connected) { name = nets[k].name; break }
        }
        if (route) {
            routeFile.reload()
            var lines = ("" + routeFile.text()).split("\n")
            for (var j = 1; j < lines.length && !up; j++) {
                var f = lines[j].trim().split(/\s+/)
                if (f.length > 1 && f[1] === "00000000") { up = true; name = f[0]; kind = /^wl/.test(f[0]) ? "wifi" : "wired" }
            }
        }
        var access = "No network access"
        if (up) {
            var c = Networking.connectivity
            access = route ? "Network access"
                   : c === NetworkConnectivity.Full ? "Internet access"
                   : c === NetworkConnectivity.Limited ? "Limited access"
                   : c === NetworkConnectivity.Portal ? "Sign-in required"
                   : c === NetworkConnectivity.None ? "No Internet access" : "Network access"
        }
        root.netUp = up
        root.netName = name
        root.netKind = kind
        root.netAccess = access
        root.netViaRoute = route
    }
    Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.netScan()
    }

    component Svg: Shape {
        id: sv
        property string d: ""
        property color stroke: "transparent"
        property real sw: 1
        property color fill: "transparent"
        property int cap: ShapePath.FlatCap
        property bool dash: false
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: sv.stroke
            strokeWidth: sv.sw
            fillColor: sv.fill
            capStyle: sv.cap
            strokeStyle: sv.dash ? ShapePath.DashLine : ShapePath.SolidLine
            dashPattern: [3, 3]
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: sv.d }
        }
    }

    component Glow: Item {
        id: gl
        property real rx: 20
        property real ry: 10
        property real cx: width / 2
        property color tint: Kit.withA(Kit.cyan, 0.55)
        clip: true
        Shape {
            x: gl.cx - gl.rx
            y: gl.height - gl.rx
            width: gl.rx * 2
            height: gl.rx
            preferredRendererType: Shape.CurveRenderer
            transform: Scale { origin.x: 0; origin.y: gl.rx; yScale: gl.ry / gl.rx }
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: gl.rx; centerY: gl.rx; centerRadius: gl.rx
                    focalX: gl.rx; focalY: gl.rx
                    GradientStop { position: 0; color: gl.tint }
                    GradientStop { position: 1; color: Kit.withA(gl.tint, 0) }
                }
                PathSvg { path: "M0 0 H" + (gl.rx * 2) + " V" + gl.rx + " H0 Z" }
            }
        }
    }

    component Chip: Rectangle {
        id: chip
        property string label: ""
        property int px: 11
        property int h: 13
        height: h
        width: Math.max(15, num.implicitWidth + 4)
        radius: 2
        color: Kit.dark(0.90)
        Text {
            id: num
            anchors.centerIn: parent
            text: chip.label
            color: "#ffffff"
            font: Kit.boldFont(chip.px)
            textFormat: Text.PlainText
        }
    }

    readonly property var screenNo: {
        var s = [], rows = [], no = {}, n = 1
        for (var i = 0; i < Quickshell.screens.length; i++) s.push(Quickshell.screens[i])
        s.sort(function (a, b) { return a.y - b.y })
        for (var j = 0; j < s.length; j++) {
            var r = rows[rows.length - 1]
            if (r && s[j].y < r.end) { r.list.push(s[j]); r.end = Math.max(r.end, s[j].y + s[j].height) }
            else rows.push({ end: s[j].y + s[j].height, list: [s[j]] })
        }
        for (var k = 0; k < rows.length; k++) {
            rows[k].list.sort(function (a, b) { return a.x - b.x || a.y - b.y })
            for (var t = 0; t < rows[k].list.length; t++) no[rows[k].list[t].name] = n++
        }
        return no
    }

    component ScreenMap: Rectangle {
        id: sm
        property string mon: ""
        readonly property var box: {
            var s = Quickshell.screens, x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
            for (var i = 0; i < s.length; i++) {
                x0 = Math.min(x0, s[i].x); y0 = Math.min(y0, s[i].y)
                x1 = Math.max(x1, s[i].x + s[i].width); y1 = Math.max(y1, s[i].y + s[i].height)
            }
            var k = Math.min(32 / (x1 - x0), 11 / (y1 - y0)), small = Infinity
            for (var j = 0; j < s.length; j++)
                small = Math.min(small, Math.max(2, Math.round(s[j].width * k) - 1), Math.max(2, Math.round(s[j].height * k) - 1))
            return { x: x0, y: y0, k: k, w: (x1 - x0) * k, h: (y1 - y0) * k, small: small }
        }
        readonly property bool legible: box.small >= 4
        readonly property int pos: root.screenNo[sm.mon] || 0
        width: legible ? Math.round(box.w) + 4 : Math.max(17, nr.implicitWidth + 6)
        height: legible ? Math.round(box.h) + 4 : 15
        radius: 2
        color: legible ? Kit.dark(0.90) : "transparent"
        Repeater {
            model: Quickshell.screens
            Rectangle {
                required property var modelData
                visible: sm.legible
                x: 2 + Math.round((modelData.x - sm.box.x) * sm.box.k)
                y: 2 + Math.round((modelData.y - sm.box.y) * sm.box.k)
                width: Math.max(2, Math.round(modelData.width * sm.box.k) - 1)
                height: Math.max(2, Math.round(modelData.height * sm.box.k) - 1)
                color: modelData.name === sm.mon ? Kit.cyan : "transparent"
                border.width: 1
                border.color: modelData.name === sm.mon ? "#ffffff" : Kit.white(0.55)
            }
        }
        Rectangle {
            visible: !sm.legible
            width: sm.width; height: 12
            radius: 2
            color: Kit.dark(0.90)
            border.width: 1
            border.color: Kit.cyan
            Text {
                id: nr
                anchors.centerIn: parent
                text: sm.pos ? "" + sm.pos : "?"
                color: Kit.cyan
                font: Kit.boldFont(10)
                textFormat: Text.PlainText
            }
        }
        Rectangle { visible: !sm.legible; x: Math.round((sm.width - 3) / 2); y: 12; width: 3; height: 1; color: Kit.cyan }
        Rectangle { visible: !sm.legible; x: Math.round((sm.width - 9) / 2); y: 13; width: 9; height: 2; radius: 1; color: Kit.cyan }
    }

    component Dot: Item {
        id: dot
        property color tone: root.kit.working
        property string label: ""
        property real d: 12
        property real labelPx: 8
        width: d
        height: d
        Rectangle { x: -2.5; y: -2.5; width: dot.d + 5; height: dot.d + 5; radius: width / 2; color: Kit.dark(1) }
        Rectangle { x: -1.5; y: -1.5; width: dot.d + 3; height: dot.d + 3; radius: width / 2; color: "#ffffff" }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: dot.tone
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: Kit.white(0.55) }
                    GradientStop { position: 0.6; color: Kit.white(0) }
                    GradientStop { position: 1; color: Kit.white(0) }
                }
            }
        }
        Text {
            anchors.centerIn: parent
            text: dot.label
            color: root.kit.ink
            font: Kit.heavyFont(dot.labelPx)
            textFormat: Text.PlainText
        }
    }

    component Icon: Image {
        property string src: ""
        source: src ? (src.indexOf("/") === 0 ? "file://" + src + root.bust : src) : ""
        sourceSize: Qt.size(64, 64)
        smooth: true
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        visible: src.length > 0
    }

    component WsButton: Item {
        id: b
        required property var m
        readonly property bool occ: m.wins > 0
        readonly property bool lit: m.active && !m.away
        property bool compact: false
        readonly property real faceW: (occ || m.away) && !compact ? 56 : 38
        readonly property alias hovered: ma.containsMouse
        width: (occ || m.away) && !compact ? Kit.buttonWidth : Kit.emptyWidth
        height: Kit.barHeight
        opacity: m.away && !hovered ? 0.55 : 1

        Rectangle {
            visible: !b.compact && b.m.wins >= 3
            x: 6; y: 2; width: 56; height: 36; radius: 3
            color: Kit.white(0.10); border.width: 1; border.color: Kit.white(0.18)
        }
        Rectangle {
            visible: !b.compact && b.m.wins >= 2
            x: 3; y: 2; width: 56; height: 36; radius: 3
            color: Kit.white(0.10); border.width: 1; border.color: Kit.white(0.18)
        }

        Item {
            id: face
            x: 0; y: 2; width: b.faceW; height: 36
            readonly property bool hot: ma.containsMouse && !b.lit

            Rectangle {
                x: -1; y: -1; width: parent.width + 2; height: parent.height + 2; radius: 4
                color: "transparent"; border.width: 1
                border.color: b.occ ? Kit.dark(b.lit ? 0.5 : 0.6) : "transparent"
            }
            Rectangle {
                anchors.fill: parent
                radius: 3
                color: face.hot ? Kit.white(0.10) : "transparent"
                gradient: face.hot || !b.occ ? null : normal
                Gradient {
                    id: normal
                    GradientStop { position: 0; color: Kit.white(b.lit ? 0.16 : 0.05) }
                    GradientStop { position: 1; color: Kit.white(b.lit ? 0.06 : 0.02) }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: Kit.white(b.lit ? 0.45 : (face.hot ? 0.35 : (b.occ ? 0.20 : 0.14)))
            }
            Item {
                anchors.fill: parent
                clip: true
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: Kit.white(0.10) }
                        GradientStop { position: 0.5; color: Kit.white(0.03) }
                        GradientStop { position: 0.5; color: Kit.white(0) }
                        GradientStop { position: 1; color: Kit.white(0) }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    visible: b.m.urgent
                    color: Qt.rgba(242 / 255, 166 / 255, 94 / 255, 0.85)
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        height: parent.height / 2
                        gradient: Gradient {
                            GradientStop { position: 0; color: Kit.white(0.25) }
                            GradientStop { position: 1; color: Kit.white(0) }
                        }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    visible: !b.m.urgent && b.occ && (b.m.awaiting > 0 || b.m.working > 0)
                    color: b.m.awaiting > 0 ? Qt.rgba(232 / 255, 207 / 255, 106 / 255, 0.26)
                                            : Qt.rgba(59 / 255, 220 / 255, 172 / 255, 0.22)
                }
                Glow {
                    visible: b.lit
                    x: parent.width * 0.10; width: parent.width * 0.80
                    height: parent.height
                    rx: width / 2; ry: 10
                }
                Glow {
                    visible: face.hot
                    anchors.fill: parent
                    cx: Math.max(0, Math.min(face.width, ma.mouseX))
                    rx: 40; ry: 30
                    tint: Kit.withA(Kit.cyan, 0.35)
                }
            }
        }

        Icon { id: lead; visible: !b.compact && b.occ && src.length > 0; x: b.m.icons.length > 1 ? 4 : (b.faceW - width) / 2; y: b.m.away ? 2 : 4; width: b.m.away ? 20 : 28; height: width; src: b.m.icons.length > 0 ? b.m.icons[0] : "" }
        Icon { visible: !b.compact && b.occ && src.length > 0; x: 37; y: 6; width: 14; height: 14; src: b.m.icons.length > 1 ? b.m.icons[1] : "" }
        Icon { visible: !b.compact && b.occ && src.length > 0 && b.m.icons.length <= 3; x: 37; y: 22; width: 14; height: 14; src: b.m.icons.length > 2 ? b.m.icons[2] : "" }
        Chip {
            visible: !b.compact && b.m.icons.length > 3
            x: 37; y: 22; width: 15; h: 14; px: 9
            label: "+" + (b.m.icons.length - 2)
        }

        Chip {
            id: num
            x: b.compact ? Math.round((b.faceW - width) / 2) : b.occ ? 1 : Math.round((b.faceW - width - (mark.visible ? mark.width + 2 : 0)) / 2)
            y: b.compact ? 2 + Math.round((36 - 15 - mark.height) / 2) : b.occ ? 24 : 13
            label: "" + b.m.id
        }
        ScreenMap {
            id: mark
            visible: b.m.away
            mon: b.m.mon
            x: b.compact ? Math.round((b.faceW - width) / 2) : num.x + num.width + 2
            y: b.compact ? num.y + num.height + 2 : num.y + num.height - height
        }
        Dot {
            visible: b.occ && !b.m.away && (b.m.awaiting > 0 || b.m.working > 0)
            x: lead.x + 18; y: 24
            tone: b.m.awaiting > 0 ? root.kit.awaiting : root.kit.working
            label: b.m.awaiting > 0 ? "❚❚" : (b.m.working > 1 ? "" + b.m.working : "●")
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (b.m.ws) b.m.ws.activate()
        }
    }

    component Drawer: Item {
        id: dr
        required property var m
        readonly property bool open: m.active && !m.away
        readonly property bool elsewhere: m.active && m.away
        readonly property bool low: elsewhere && drMap.width > 21
        readonly property string tab: "M0.5 " + (height - 0.5) + " V4.5 a4 4 0 0 1 4 -4 H35.5 a4 4 0 0 1 4 4 V" + (height - 0.5) + " Z"
        readonly property int more: m.wins - (elsewhere ? 1 : 2)
        width: 46
        height: open ? 38 : 36
        y: open ? 2 : 4
        opacity: elsewhere && !dma.containsMouse ? 0.55 : 1
        Svg { visible: dr.m.wins >= 3; x: 6; d: dr.tab; fill: Kit.white(0.10); stroke: Kit.white(0.18) }
        Svg { visible: dr.m.wins >= 2; x: 3; d: dr.tab; fill: Kit.white(0.10); stroke: Kit.white(0.18) }
        Svg {
            d: "M0 " + dr.height + " V4 a4 4 0 0 1 4 -4 H36 a4 4 0 0 1 4 4 V" + dr.height + " Z"
            fill: dr.open ? "transparent" : Kit.white(0.05)
        }
        Rectangle {
            visible: dr.open
            width: 40; height: dr.height
            gradient: Gradient {
                GradientStop { position: 0; color: Kit.white(0.16) }
                GradientStop { position: 1; color: Kit.white(0.06) }
            }
        }
        Glow { visible: dr.open; x: 4; width: 32; height: dr.height; rx: width / 2; ry: 10 }
        Svg {
            visible: dr.open
            x: -1; y: -1
            d: "M0.5 " + (dr.height + 1) + " V4.5 a4 4 0 0 1 4 -4 H37.5 a4 4 0 0 1 4 4 V" + (dr.height + 1)
            stroke: Kit.dark(0.5)
        }
        Svg { d: dr.tab; stroke: Kit.white(dr.open ? 0.45 : 0.20) }
        ScreenMap { id: drMap; visible: dr.elsewhere; mon: dr.m.mon; x: dr.low ? Math.round((40 - width) / 2) : 1; y: dr.low ? dr.height - 1 - height : 3 }
        Icon {
            x: dr.elsewhere ? (dr.low ? 3 : 22) : (dr.m.wins === 1 ? 12 : 3)
            y: 4; width: 16; height: 16
            src: dr.m.icons.length > 0 ? dr.m.icons[0] : ""
        }
        Icon { x: 21; y: 4; width: 16; height: 16; src: !dr.elsewhere && dr.m.icons.length > 1 ? dr.m.icons[1] : "" }
        Chip { id: drName; visible: !dr.low; x: 2; y: 22; px: 9; h: 11; label: dr.m.name.substring(0, 3) }
        Chip {
            visible: dr.more > 0
            x: dr.low ? 38 - width : Math.max(drName.x + drName.width + 1, 38 - width)
            y: dr.low ? 7 : 22
            px: 9; h: 11
            label: "+" + dr.more
        }
        MouseArea {
            id: dma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("togglespecialworkspace " + dr.m.name)
        }
    }

    component Cell: Item {
        id: cell
        property bool lit: false
        signal clicked()
        signal wheeled(real dy)
        width: 24
        height: Kit.barHeight
        Rectangle {
            anchors.fill: parent
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: Kit.white(0.32)
            visible: hover.hovered || cell.lit
        }
        HoverHandler { id: hover }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: cell.clicked()
            onWheel: function (w) { cell.wheeled(w.angleDelta.y) }
        }
    }

    component ShadowText: Item {
        id: st
        property string text: ""
        property font font
        implicitWidth: top.implicitWidth
        implicitHeight: 15
        property alias horizontalAlignment: top.horizontalAlignment
        Text { x: 0; y: 1.5; height: 15; verticalAlignment: Text.AlignVCenter; text: st.text; font: st.font; color: Kit.withA("#000000", 0.45); textFormat: Text.PlainText; horizontalAlignment: top.horizontalAlignment; width: st.width }
        Text { id: top; height: 15; verticalAlignment: Text.AlignVCenter; text: st.text; font: st.font; color: "#ffffff"; textFormat: Text.PlainText; width: st.width }
    }

    component AppRow: Item {
        id: ar
        property var entry: null
        property string label: entry ? entry.name : ""
        property string sub: ""
        property bool sel: false
        signal activated()
        width: parent ? parent.width : 266
        height: 36
        Rectangle {
            anchors.fill: parent
            radius: 2
            color: ar.sel ? Kit.accent(0.22) : (arMa.containsMouse ? Kit.accent(0.10) : "transparent")
            border.width: 1
            border.color: ar.sel ? Kit.dark(0.55) : "transparent"
        }
        Icon {
            x: 9; y: 2; width: 32; height: 32
            src: ar.entry ? (Quickshell.iconPath(ar.entry.icon, true) || Quickshell.iconPath("application-x-executable", true) || root.appGlyph) : ""
        }
        Column {
            x: 51
            width: parent.width - 51 - 28
            anchors.verticalCenter: parent.verticalCenter
            Text {
                width: parent.width
                text: ar.label
                elide: Text.ElideRight
                color: Kit.ink
                font: Kit.bodyFont(12)
                textFormat: Text.PlainText
            }
            Text {
                visible: ar.sub !== ""
                width: parent.width
                text: ar.sub
                elide: Text.ElideRight
                color: Kit.dark(0.72)
                font: Kit.bodyFont(11)
                textFormat: Text.PlainText
            }
        }
        Text {
            anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
            text: "\u25B6"
            opacity: 0.55
            color: Kit.ink
            font: Kit.bodyFont(10)
            textFormat: Text.PlainText
        }
        MouseArea {
            id: arMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ar.activated()
        }
    }

    component PaneRow: Item {
        id: pr
        property string label: ""
        property real rh: 30
        property bool plate: false
        property bool lit: false
        property real textX: 9
        signal activated()
        signal context()
        width: parent ? parent.width : 132
        height: rh
        Rectangle {
            anchors.fill: parent
            radius: 2
            color: prMa.containsMouse || pr.lit ? (pr.plate ? Kit.accent(0.10) : Kit.white(0.12)) : "transparent"
            border.width: 1
            border.color: (prMa.containsMouse || pr.lit) && !pr.plate ? Kit.white(0.40) : "transparent"
        }
        Text {
            visible: pr.plate
            x: pr.textX
            width: pr.width - pr.textX - 6
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
            text: pr.label
            color: pr.enabled ? Kit.ink : Kit.dark(0.40)
            font: Kit.bodyFont(12)
            textFormat: Text.PlainText
        }
        ShadowText {
            visible: !pr.plate
            x: 13
            anchors.verticalCenter: parent.verticalCenter
            text: pr.label
            font: Kit.bodyFont(12)
        }
        MouseArea {
            id: prMa
            anchors.fill: parent
            hoverEnabled: pr.enabled
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: pr.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: function (mouse) { if (mouse.button === Qt.RightButton) pr.context(); else pr.activated() }
        }
    }

    component PowerRow: Item {
        id: pw
        property string action: ""
        property string label: Power.find(pw.action) ? Power.find(pw.action).name + (pw.more ? "\u2026" : "") : ""
        property string pic: pw.action
        property bool more: false
        signal activated()
        width: parent ? parent.width : 218
        height: 30
        Rectangle {
            anchors.fill: parent
            radius: 2
            color: pwMa.containsMouse ? Kit.accent(0.10) : "transparent"
        }
        Icon {
            x: 9; y: 5; width: 20; height: 20
            sourceSize: Qt.size(20, 20)
            opacity: pw.enabled ? 1 : 0.4
            src: root.iconDir + "power/" + pw.pic + ".svg"
        }
        Column {
            x: 38
            width: pw.width - 38 - 6
            anchors.verticalCenter: parent.verticalCenter
            Text {
                width: parent.width
                text: pw.label
                elide: Text.ElideRight
                color: pw.enabled ? Kit.ink : Kit.dark(0.40)
                font: Kit.bodyFont(12)
                textFormat: Text.PlainText
            }
        }
        MouseArea {
            id: pwMa
            anchors.fill: parent
            hoverEnabled: pw.enabled
            cursorShape: pw.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: pw.activated()
        }
    }

    component Rim: Rectangle {
        id: rm
        radius: 3
        color: Kit.rimTint()
        border.width: 1
        border.color: Kit.dark(0.85)
        Item {
            anchors.fill: parent
            anchors.margins: 1
            clip: true
            Svg { d: Kit.streaks(rm.width - 2, rm.height - 2); fill: Kit.white(0.035) }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: Kit.white(0.35)
        }
        Rectangle {
            x: 1; y: 1; width: parent.width - 2; height: 24
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0; color: Kit.white(0.22) }
                GradientStop { position: 1; color: Kit.white(0.06) }
            }
        }
    }

    component Plate: Rectangle {
        radius: 2
        color: Kit.plate()
        border.width: 1
        border.color: Kit.dark(0.55)
    }

    component PlateButton: Rectangle {
        id: pb
        property string label: ""
        signal activated()
        height: 26
        radius: 2
        color: "#ffffff"
        border.width: 1
        border.color: pbMa.containsMouse ? Kit.accent(1) : Kit.dark(0.55)
        Text {
            anchors.centerIn: parent
            text: pb.label
            color: Kit.ink
            font: Kit.bodyFont(12)
            textFormat: Text.PlainText
        }
        MouseArea {
            id: pbMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.activated()
        }
    }

    component Flyout: PopupWindow {
        id: fy
        required property string name
        required property Item cell
        property bool gate: true
        property bool flushRight: false
        property bool flushLeft: false
        visible: root.flyout === fy.name && fy.gate
        color: "transparent"
        anchor.item: fy.cell
        anchor.edges: fy.flushRight ? Edges.Top | Edges.Right : fy.flushLeft ? Edges.Top | Edges.Left : Edges.Top
        anchor.gravity: fy.flushRight ? Edges.Top | Edges.Left : fy.flushLeft ? Edges.Top | Edges.Right : Edges.Top
        anchor.adjustment: PopupAdjustment.Slide
        grabFocus: false
        property bool holdEscape: false
        onVisibleChanged: {
            if (fy.visible) root.flyoutShown = fy.name
            else if (root.flyoutShown === fy.name) root.flyoutShown = ""
            if (fy.visible || root.flyout !== fy.name) return
            root.flyoutGone = fy.name
            root.flyoutGoneAt = Date.now()
            root.flyout = ""
        }
        Shortcut { sequence: "Escape"; enabled: fy.visible && !fy.holdEscape; onActivated: root.flyout = "" }
        HyprlandFocusGrab {
            windows: [fy]
            active: fy.visible && fy.backingWindowVisible
            onCleared: {
                root.flyoutGone = fy.name
                root.flyoutGoneAt = Date.now()
                root.flyout = ""
            }
        }
    }

    component VolCol: Item {
        id: vc
        property var node: null
        property string label: ""
        property string picture: ""
        property bool headed: false
        property bool metering: false
        readonly property var audio: vc.node && vc.node.audio ? vc.node.audio : null
        readonly property real level: vc.audio ? vc.audio.volume : 0
        readonly property bool muted: vc.audio ? vc.audio.muted === true : false
        signal headerClicked()
        width: 68
        height: 272

        PwNodePeakMonitor { id: pk; node: vc.node; enabled: vc.metering }

        Rectangle { x: 0; y: 16; width: 68; height: 48; color: hdrMa.containsMouse ? Kit.accent(0.12) : "transparent" }
        Icon { x: 18; y: 16; width: 32; height: 32; src: vc.picture }
        Text {
            x: 6; y: 48; width: 56; height: 16
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: vc.label
            color: Kit.ink
            font: Kit.bodyFont(11)
            textFormat: Text.PlainText
        }
        MouseArea {
            id: hdrMa
            x: 0; y: 16; width: 68; height: 48
            enabled: vc.headed
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: vc.headerClicked()
        }
        Rectangle { x: 0; y: 72; width: 68; height: 1; color: Kit.dark(0.15) }

        Rectangle {
            id: track
            x: 27; y: 88; width: 6; height: 120
            radius: 3
            color: Kit.dark(0.20)
            border.width: 1
            border.color: Kit.dark(0.25)
        }
        Rectangle {
            id: fill
            readonly property real fillH: Math.round(track.height * Math.min(1, vc.level))
            x: 27; y: track.y + track.height - fillH; width: 6; height: fillH
            radius: 3
            gradient: Gradient {
                GradientStop { position: 0; color: vc.muted ? "#d5dde0" : "#a6f0f7" }
                GradientStop { position: 0.5; color: vc.muted ? "#8e9ba0" : "#25bbcf" }
                GradientStop { position: 1; color: vc.muted ? "#5f6e73" : "#11707e" }
            }
        }
        Rectangle { x: 27; y: fill.y + 2; width: 1; height: Math.max(0, fill.fillH - 4); color: Kit.white(0.55) }
        Rectangle {
            x: 21; y: fill.y - 5; width: 18; height: 10
            radius: 2
            border.width: 1
            border.color: Kit.dark(0.55)
            gradient: Gradient {
                GradientStop { position: 0; color: "#ffffff" }
                GradientStop { position: 0.5; color: "#dfeef0" }
                GradientStop { position: 0.5; color: "#c9e3e7" }
                GradientStop { position: 1; color: "#eaf5f6" }
            }
        }

        Rectangle {
            x: 42; y: 88; width: 5; height: 120
            color: Kit.dark(0.12)
            border.width: 1
            border.color: Kit.dark(0.25)
        }
        Rectangle {
            x: 43; width: 3
            height: vc.muted ? 0 : Math.round(Math.min(1, pk.peak) * 118)
            y: 207 - height
            gradient: Gradient {
                GradientStop { position: 0; color: "#c6f7b4" }
                GradientStop { position: 1; color: "#2f9e46" }
            }
        }

        Text {
            x: 0; y: 216; width: 68; height: 16
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: vc.audio ? "" + Math.round(vc.level * 100) : "–"
            color: Kit.ink
            font: Kit.bodyFont(12)
            textFormat: Text.PlainText
        }
        MouseArea {
            x: 18; y: 82; width: 24; height: 132
            enabled: !!vc.audio
            cursorShape: Qt.PointingHandCursor
            onPressed: function (m) { root.setNodeVolume(vc.node, 1 - (m.y - 6) / track.height) }
            onPositionChanged: function (m) { if (pressed) root.setNodeVolume(vc.node, 1 - (m.y - 6) / track.height) }
            onWheel: function (w) { root.setNodeVolume(vc.node, vc.level + w.angleDelta.y / 120 * 0.02) }
        }

        Rectangle {
            x: 17; y: 240; width: 34; height: 24
            radius: 3
            border.width: 1
            border.color: Kit.dark(0.55)
            gradient: Gradient {
                GradientStop { position: 0; color: "#ffffff" }
                GradientStop { position: 0.5; color: "#e3f1f3" }
                GradientStop { position: 0.5; color: "#d3e9ec" }
                GradientStop { position: 1; color: "#f0f8f9" }
            }
            Rectangle { anchors.fill: parent; radius: 3; color: muteMa.containsMouse ? Kit.accent(0.15) : "transparent" }
            Icon { x: 9; y: 4; width: 16; height: 16; src: root.trayDir + (vc.muted ? "btn-speaker-muted.svg" : "btn-speaker.svg") }
            MouseArea {
                id: muteMa
                anchors.fill: parent
                hoverEnabled: true
                enabled: !!vc.audio
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setNodeMuted(vc.node, !vc.muted)
            }
        }
    }

    component NetGlyph: Item {
        id: ng
        property string kind: "wired"
        width: 18
        height: 16
        Svg { visible: ng.kind === "wired"; d: "M3.5 1.5 H14.5 a1 1 0 0 1 1 1 V9.5 a1 1 0 0 1 -1 1 H3.5 a1 1 0 0 1 -1 -1 V2.5 a1 1 0 0 1 1 -1 Z"; stroke: Kit.ink; fill: Kit.dark(1) }
        Svg { visible: ng.kind === "wired"; d: "M4 3 H14 V9 H4 Z"; fill: Kit.withA("#2aa3b8", 0.8) }
        Svg { visible: ng.kind === "wired"; d: "M9 10.5 v2.5 M5 14.5 h8"; stroke: Kit.ink; sw: 1.4 }
        Svg { visible: ng.kind === "wifi"; d: "M1.5 6 a10 10 0 0 1 15 0 M4 8.8 a6.5 6.5 0 0 1 10 0 M6.6 11.4 a3 3 0 0 1 4.8 0"; stroke: Kit.ink; sw: 1.5; cap: ShapePath.RoundCap }
        Svg { visible: ng.kind === "wifi"; d: "M9 13.2 m-1.4 0 a1.4 1.4 0 1 0 2.8 0 a1.4 1.4 0 1 0 -2.8 0"; fill: Kit.ink }
    }

    component NetRow: Item {
        id: nr
        property string kind: "wired"
        property string name: ""
        property string tag: ""
        width: parent ? parent.width : 286
        height: 26
        NetGlyph { x: 8; y: 5; kind: nr.kind }
        Text {
            x: 34
            width: parent.width - 34 - nrTag.width - 16
            anchors.verticalCenter: parent.verticalCenter
            text: nr.name
            elide: Text.ElideRight
            color: Kit.ink
            font: Kit.bodyFont(12)
            textFormat: Text.PlainText
        }
        Text {
            id: nrTag
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: nr.tag
            color: Kit.dark(0.72)
            font: Kit.bodyFont(10)
            textFormat: Text.PlainText
        }
    }

    Item {
        id: gadgets
        function make(c) {
            if (c.status === Component.Error) console.warn("[barcarolle] DesktopGadgets:", c.errorString())
            else if (c.status === Component.Ready)
                c.createObject(gadgets, { livery: root.livery, bridge: root.bridge, stagingEngine: root.stagingEngine, bar: win })
        }
        Component.onCompleted: {
            var c = Qt.createComponent(Kit.helper("DesktopGadgets"))
            if (c.status === Component.Loading) c.statusChanged.connect(function () { gadgets.make(c) })
            else gadgets.make(c)
        }
    }

    PanelWindow {
        id: win
        screen: QsWindow.window ? QsWindow.window.screen : null
        anchors { bottom: true; left: true; right: true }
        implicitHeight: Kit.barHeight
        exclusiveZone: Kit.barHeight
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "aoide-bar"

        property var model: ({ rows: [], drawers: [], lists: {} })
        property var lists: ({})
        property string sig: ""
        function refresh() {
            var nm = root.build(win.screen ? win.screen.name : "")
            win.lists = nm.lists
            var s = JSON.stringify(nm, function (k, v) { return k === "ws" || k === "lists" ? undefined : v })
            if (s === win.sig) return
            win.sig = s
            win.model = nm
        }
        Connections {
            target: root
            function onTickChanged() { win.refresh() }
        }
        onScreenChanged: refresh()
        Component.onCompleted: refresh()
        readonly property var fit: {
            var rows = win.model.rows, wide = 0, slim = 0, keep = 0
            var tail = 13 + 2 + (46 + 2) * win.model.drawers.length + 28
            var room = more.x - 6 - Kit.stripLeft
            for (var i = 0; i < rows.length; i++) {
                var w = rows[i].away || rows[i].wins > 0 ? Kit.buttonWidth : Kit.emptyWidth
                wide += w + 2
                slim += (rows[i].away ? Kit.emptyWidth : w) + 2
                if (slim - 2 <= room) keep = slim - 2
            }
            return { room: room, compact: wide + tail > room, clip: slim + tail > room, keep: keep }
        }

        property int hotId: -1
        property Item hotBtn: null
        property Item rigBtn: null
        readonly property int peekId: hotId >= 0 ? hotId : (rigBtn ? root.rigPeek : -1)
        readonly property Item peekBtn: hotId >= 0 ? hotBtn : rigBtn
        readonly property var peekList: peekId >= 0 && lists[peekId] ? lists[peekId] : []
        function hover(btn, on) {
            if (on && btn.occ) { hotId = btn.m.id; hotBtn = btn; peekHide.stop() }
            else if (!on && hotBtn === btn) peekHide.restart()
        }
        Timer {
            id: peekHide
            interval: 250
            onTriggered: if (!peekHover.hovered) { win.hotId = -1; win.hotBtn = null }
        }

        Rectangle { anchors.fill: parent; color: Kit.dark(0.64) }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Kit.white(0.10) }
                GradientStop { position: 0.5; color: Kit.white(0.04) }
                GradientStop { position: 0.5; color: Kit.white(0) }
                GradientStop { position: 1; color: Kit.white(0) }
            }
        }
        Svg { d: Kit.streaks(win.width, Kit.barHeight); fill: Kit.white(0.035); preferredRendererType: Shape.CurveRenderer }
        Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: Kit.dark(0.85) }
        Rectangle { x: 0; y: 1; width: parent.width; height: 1; color: Kit.white(0.30) }

        Item {
            id: orb
            x: 0; y: 0; width: Kit.orbWidth; height: Kit.barHeight
            MouseArea { anchors.fill: parent; z: 1; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleFlyout("start") }
            Item {
                id: orbArt
                x: 7; y: 0; width: 40; height: 40
                layer.enabled: true
                visible: false
                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: "transparent"
                        fillGradient: RadialGradient {
                            centerX: 20; centerY: 24.32; centerRadius: 21.6
                            focalX: 20; focalY: 24.32
                            GradientStop { position: 0; color: "#2aa3b8" }
                            GradientStop { position: 0.55; color: "#0f4a5e" }
                            GradientStop { position: 1; color: "#081e2b" }
                        }
                        PathSvg { path: Kit.ell(20, 20, 18, 18, 0) }
                    }
                }
                Shape {
                    x: 9; y: 29; width: 22; height: 22
                    preferredRendererType: Shape.CurveRenderer
                    transform: Scale { yScale: 8 / 22 }
                    ShapePath {
                        strokeColor: "transparent"
                        fillGradient: RadialGradient {
                            centerX: 11; centerY: 22; centerRadius: 11
                            focalX: 11; focalY: 22
                            GradientStop { position: 0; color: Kit.withA(Kit.cyan, 0.6) }
                            GradientStop { position: 1; color: Kit.withA(Kit.cyan, 0) }
                        }
                        PathSvg { path: Kit.ell(11, 11, 11, 11, 0) }
                    }
                }
                Svg { d: Kit.ell(20, 20, 17.5, 17.5, 0); stroke: Kit.white(0.35) }
                Svg { d: Kit.ell(20, 20, 18.5, 18.5, 0); stroke: Kit.dark(0.85) }
                Item {
                    x: 15.77; y: 8
                    Svg { d: Kit.clef; stroke: Kit.withA("#081e2b", 0.55); sw: 2.2 }
                    Svg { d: Kit.clef; stroke: "#c3d0d9"; sw: 0.9 }
                    Shape {
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: "transparent"
                            fillGradient: LinearGradient {
                                x1: 0; y1: 0; x2: 0; y2: 24
                                GradientStop { position: 0; color: "#ffffff" }
                                GradientStop { position: 0.45; color: "#d6e0e8" }
                                GradientStop { position: 0.55; color: "#9fb1bf" }
                                GradientStop { position: 1; color: "#e4ebf0" }
                            }
                            PathSvg { path: Kit.clef }
                        }
                    }
                }
                Shape {
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: "transparent"
                        fillGradient: LinearGradient {
                            x1: 0; y1: 2.5; x2: 0; y2: 17.5
                            GradientStop { position: 0; color: Kit.white(0.6) }
                            GradientStop { position: 1; color: Kit.white(0.04) }
                        }
                        PathSvg { path: Kit.ell(20, 10, 14, 7.5, 0) }
                    }
                }
            }
            MultiEffect {
                x: 7; y: root.flyout === "start" ? 1 : 0; width: 40; height: 40
                source: orbArt
                brightness: root.flyout === "start" ? -0.14 : 0
                shadowEnabled: true
                shadowColor: Kit.withA(Kit.cyan, root.flyout === "start" ? 0.75 : 0.45)
                shadowBlur: 0.5
                shadowOpacity: 1
                autoPaddingEnabled: true
            }
        }

        Row {
            id: strip
            x: Kit.stripLeft
            y: 0
            width: win.fit.clip ? win.fit.keep : implicitWidth
            clip: win.fit.clip
            height: Kit.barHeight
            spacing: 2
            Repeater {
                model: win.model.rows
                onItemAdded: function (i, item) { if (item.m.id === root.rigPeek) win.rigBtn = item }
                WsButton {
                    required property var modelData
                    m: modelData
                    compact: modelData.away && win.fit.compact
                    onHoveredChanged: win.hover(this, hovered)
                }
            }
            Item {
                width: 13; height: Kit.barHeight
                Rectangle { x: 6; y: 8; width: 1; height: 24; color: Kit.dark(0.85) }
                Rectangle { x: 7; y: 8; width: 1; height: 24; color: Kit.white(0.18) }
            }
            Repeater {
                model: win.model.drawers
                Item {
                    id: slot
                    required property var modelData
                    width: 46; height: Kit.barHeight
                    Drawer { m: slot.modelData }
                }
            }
            Item {
                width: 28; height: Kit.barHeight
                Item {
                    y: 5; width: 28; height: 32
                    Svg {
                        d: "M3.5 0.5 H24.5 a3 3 0 0 1 3 3 V28.5 a3 3 0 0 1 -3 3 H3.5 a3 3 0 0 1 -3 -3 V3.5 a3 3 0 0 1 3 -3 Z"
                        stroke: Kit.white(0.35)
                        dash: true
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Kit.white(0.85)
                        font: Kit.lightFont(20)
                        textFormat: Text.PlainText
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var n = root.nextEmpty()
                        if (win.screen) Hyprland.dispatch("focusmonitor " + win.screen.name)
                        Hyprland.dispatch("workspace " + n)
                    }
                }
            }
        }

        PopupWindow {
            id: peek
            visible: win.peekBtn !== null && win.peekList.length > 0 && root.flyout === ""
            color: "transparent"
            anchor.item: win.peekBtn
            anchor.edges: Edges.Top | Edges.Left
            anchor.gravity: Edges.Top | Edges.Right
            anchor.adjustment: PopupAdjustment.Slide
            implicitWidth: 300
            implicitHeight: rim.height + 6

            readonly property int agents: {
                var n = 0
                for (var i = 0; i < win.peekList.length; i++)
                    if (win.peekList[i].state && win.peekList[i].state !== "idle") n++
                return n
            }
            readonly property int count: win.peekList.length
            readonly property var ws: win.peekBtn && win.peekBtn.m ? win.peekBtn.m.ws : null
            readonly property var scr: {
                var n = ws && ws.monitor ? ws.monitor.name : ""
                var s = Quickshell.screens
                for (var i = 0; i < s.length; i++) if (s[i].name === n) return s[i]
                return win.screen
            }
            readonly property bool scrolling: !!ws && ws.lastIpcObject.tiledLayout === "scrolling"
            function onOutput(ipc) {
                var s = peek.scr
                if (!s) return true
                return ipc.at[0] < s.x + s.width && ipc.at[0] + ipc.size[0] > s.x
                    && ipc.at[1] < s.y + s.height && ipc.at[1] + ipc.size[1] > s.y
            }
            readonly property int outside: {
                var n = 0
                if (scrolling) {
                    var ts = ws.toplevels.values
                    for (var i = 0; i < ts.length; i++) {
                        var ipc = ts[i].lastIpcObject
                        if (ipc && ipc.at && ipc.size && !ipc.hidden && !peek.onOutput(ipc)) n++
                    }
                }
                return n
            }
            readonly property real k: scr ? 240 / scr.width : 0.125
            readonly property int miniH: scr ? Math.round(240 * scr.height / scr.width) : 135
            onVisibleChanged: if (visible) Hyprland.refreshToplevels()
            onWsChanged: if (visible) Hyprland.refreshToplevels()
            Timer { id: peekClock; interval: 66; repeat: true; running: peek.visible }

            Rectangle {
                id: rim
                width: 300
                height: 6 + 26 + 4 + mini.height + 4 + plate.height + 6
                radius: 3
                color: Qt.rgba(42 / 255, 163 / 255, 184 / 255, 0.58)
                border.width: 1
                border.color: Kit.dark(0.85)
                HoverHandler { id: peekHover }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: Kit.white(0.35)
                }
                Rectangle {
                    x: 1; y: 1; width: parent.width - 2; height: 24
                    radius: 2
                    gradient: Gradient {
                        GradientStop { position: 0; color: Kit.white(0.22) }
                        GradientStop { position: 1; color: Kit.white(0.06) }
                    }
                }
                Rectangle {
                    id: head
                    x: 6; y: 6; width: 288; height: 26
                    radius: 2
                    color: Kit.dark(0.80)
                    Text {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#ffffff"
                        font: Kit.boldFont(12)
                        textFormat: Text.PlainText
                        text: "Workspace " + win.peekId + " · " + peek.count + (peek.count === 1 ? " window" : " windows")
                              + (peek.agents > 0 ? " · " + peek.agents + (peek.agents === 1 ? " agent" : " agents") : "")
                    }
                }
                Rectangle {
                    id: mini
                    x: 29; y: 36; width: 242; height: peek.miniH + 2
                    radius: 2
                    color: Kit.dark(0.80)
                    border.width: 1
                    border.color: Kit.dark(0.55)
                    Item {
                        x: 1; y: 1; width: 240; height: peek.miniH
                        clip: true
                        Loader {
                            anchors.fill: parent
                            Component.onCompleted: setSource(Kit.helper("CoverArt"), {
                                source: Qt.binding(function () { return root.coverPath.length > 0 ? "file://" + root.coverPath : "" }),
                                tile: Qt.binding(function () { return root.coverTile }),
                                screenWidth: Qt.binding(function () { return peek.scr ? peek.scr.width : 1920 }),
                                cropWidth: 480
                            })
                        }
                        Repeater {
                            model: peek.visible && peek.ws ? peek.ws.toplevels : null
                            Item {
                                id: tile
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject
                                readonly property bool placed: !!(ipc && ipc.at && ipc.size && peek.scr)
                                visible: placed && !ipc.hidden && (!peek.scrolling || peek.onOutput(ipc))
                                z: placed && ipc.floating ? 1 : 0
                                x: placed ? (ipc.at[0] - peek.scr.x) * peek.k : 0
                                y: placed ? (ipc.at[1] - peek.scr.y) * peek.k : 0
                                width: placed ? ipc.size[0] * peek.k : 0
                                height: placed ? ipc.size[1] * peek.k : 0
                                ScreencopyView {
                                    id: sv
                                    anchors.fill: parent
                                    captureSource: tile.modelData.wayland
                                    live: false
                                    Component.onCompleted: captureFrame()
                                    Connections { target: peekClock; function onTriggered() { sv.captureFrame() } }
                                }
                                Icon {
                                    visible: !sv.hasContent
                                    anchors.centerIn: parent
                                    width: 16; height: 16
                                    src: root.iconFor(Kit.className(tile.modelData))
                                }
                            }
                        }
                    }
                    Chip {
                        visible: peek.outside > 0
                        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 4; bottomMargin: 4 }
                        px: 10; h: 14
                        label: "+" + peek.outside
                    }
                }
                Rectangle {
                    id: plate
                    x: 6; y: mini.y + mini.height + 4; width: 288
                    height: 6 + peek.count * 28
                    radius: 2
                    color: Qt.rgba(245 / 255, 251 / 255, 251 / 255, 0.97)
                    border.width: 1
                    border.color: Kit.dark(0.55)
                    Column {
                        x: 1; y: 3; width: parent.width - 2
                        Repeater {
                            model: win.peekList
                            Item {
                                id: row
                                required property var modelData
                                width: parent.width
                                height: 28
                                Rectangle {
                                    anchors.fill: parent
                                    color: rowMa.containsMouse ? Qt.rgba(37 / 255, 187 / 255, 207 / 255, 0.10) : "transparent"
                                }
                                Rectangle {
                                    visible: row.modelData.front
                                    x: 0; y: 0; width: 2; height: parent.height
                                    color: "#25bbcf"
                                }
                                Icon { x: 9; y: 6; width: 16; height: 16; src: row.modelData.icon }
                                Text {
                                    x: 33
                                    width: stateRow.x - 8 - 33
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.title
                                    elide: Text.ElideRight
                                    color: root.kit.ink
                                    font: Kit.bodyFont(12)
                                    textFormat: Text.PlainText
                                }
                                Row {
                                    id: stateRow
                                    visible: row.modelData.state !== "" && row.modelData.state !== "idle"
                                    anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
                                    spacing: 8
                                    Item {
                                        width: 12; height: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 6
                                            color: row.modelData.state === "awaiting" ? root.kit.awaiting : root.kit.working
                                            border.width: 1
                                            border.color: Kit.dark(0.55)
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: width / 2
                                                gradient: Gradient {
                                                    GradientStop { position: 0; color: Kit.white(0.55) }
                                                    GradientStop { position: 0.6; color: Kit.white(0) }
                                                }
                                            }
                                        }
                                        Rectangle { visible: row.modelData.state === "awaiting"; x: 3.5; y: 3; width: 1.5; height: 6; color: root.kit.ink }
                                        Rectangle { visible: row.modelData.state === "awaiting"; x: 6.5; y: 3; width: 1.5; height: 6; color: root.kit.ink }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: row.modelData.state + (row.modelData.tool ? " · " + row.modelData.tool : "")
                                        color: Kit.dark(0.72)
                                        font: Kit.bodyFont(11)
                                        textFormat: Text.PlainText
                                    }
                                }
                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Hyprland.dispatch("focuswindow address:0x" + root.bare(row.modelData.address))
                                        win.hotBtn = null
                                        win.hotId = -1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: sliver
            anchors { right: parent.right; top: parent.top; topMargin: 2; bottom: parent.bottom }
            width: 15
            color: sliverMa.containsMouse ? Kit.white(0.10) : "transparent"
            Rectangle { x: 0; y: 0; width: 1; height: parent.height; color: Kit.dark(0.85) }
            Rectangle { x: 1; y: 0; width: 1; height: parent.height; color: Kit.white(0.18) }
            MouseArea { id: sliverMa; anchors.fill: parent; hoverEnabled: true }
        }

        Cell {
            id: clock
            anchors.right: sliver.left
            width: 76
            lit: root.flyout === "calendar"
            onClicked: root.toggleFlyout("calendar")
            Column {
                anchors.centerIn: parent
                ShadowText { width: 76; horizontalAlignment: Text.AlignHCenter; text: Qt.formatTime(root.now, "h:mm AP"); font: Kit.bodyFont(12) }
                ShadowText { width: 76; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(root.now, "M/d/yyyy"); font: Kit.bodyFont(12) }
            }
        }

        Cell {
            id: vol
            anchors { right: clock.left; rightMargin: 4 }
            lit: root.flyout === "volume"
            onClicked: root.toggleFlyout("volume")
            onWheeled: function (dy) { root.nudgeVolume(dy / 120 * 0.02) }
            Icon {
                x: 4; y: 12; width: 16; height: 16
                src: root.trayDir + (root.volSilent ? "tray-vol-mute.svg" : root.volLevel >= 0.5 ? "tray-vol-high.svg" : "tray-vol-low.svg")
            }
        }
        Cell {
            id: net
            anchors.right: vol.left
            lit: root.flyout === "network"
            onClicked: root.toggleFlyout("network")
            Icon { x: 4; y: 12; width: 16; height: 16; src: root.trayDir + (root.netUp ? "tray-net-up.svg" : "tray-net-down.svg") }
        }
        Cell {
            id: flag
            anchors.right: net.left
            lit: root.flyout === "action"
            onClicked: root.toggleFlyout("action")
            Icon { x: 4; y: 12; width: 16; height: 16; src: root.trayDir + "tray-flag.svg" }
            Dot {
                visible: root.heraldCount > 0
                x: 14; y: 22; d: 9
                tone: root.kit.urgent
            }
        }
        Cell {
            id: agents
            anchors.right: flag.left
            lit: !!root.dock && !!root.dock.shown && root.dock.targetScreen === win.screen
            onClicked: if (root.dock && root.dock.toggle) root.dock.toggle(win.screen)
            Icon { x: 4; y: 12; width: 16; height: 16; src: root.trayDir + "tray-agents.svg" }
            Dot {
                visible: root.awaitingCount > 0
                x: 14; y: 6; d: 11
                tone: root.kit.awaiting
                label: "" + root.awaitingCount
            }
            Rectangle {
                visible: root.workingCount > 0
                x: 3; y: 26; width: 4; height: 4; radius: 2
                color: root.kit.working
            }
        }
        Cell {
            id: more
            width: root.trayCount > 0 ? 18 : 0
            visible: root.trayCount > 0
            anchors.right: riceSlot.left
            lit: root.flyout === "tray"
            onClicked: { root.trayTip = ""; root.toggleFlyout("tray") }
            Icon { x: 4; y: 15; width: 10; height: 10; src: root.trayDir + "tray-more.svg" }
        }

        Flyout {
            name: "tray"
            cell: more
            gate: root.trayCount > 0
            implicitWidth: trayRim.width
            implicitHeight: trayRim.height + 6
            Rim {
                id: trayRim
                width: trayPlate.width + 14
                height: trayPlate.height + 14
                Plate {
                    id: trayPlate
                    x: 7
                    y: 7
                    width: 168
                    height: trayGrid.height + 32
                    color: Kit.dark(0.64)
                    Rectangle {
                        anchors.fill: parent
                        radius: 2
                        gradient: Gradient {
                            GradientStop { position: 0; color: Kit.white(0.10) }
                            GradientStop { position: 0.5; color: Kit.white(0.04) }
                            GradientStop { position: 0.5; color: Kit.white(0) }
                            GradientStop { position: 1; color: Kit.white(0) }
                        }
                    }
                    Grid {
                        id: trayGrid
                        x: 4
                        y: 4
                        columns: 4
                        Repeater {
                            model: SystemTray.items
                            delegate: Item {
                                id: tc
                                required property var modelData
                                readonly property bool noIcon: {
                                    var s = tc.modelData ? "" + (tc.modelData.icon || "") : ""
                                    return s === "" || (s.indexOf("image://qspixmap/") === 0 && s.slice(-2) === "/0")
                                        || (s.indexOf("image://icon/") === 0 && Quickshell.iconPath(s.slice(13), true) === "")
                                }
                                width: 40
                                height: 40
                                readonly property string label: tc.modelData
                                    ? "" + (tc.modelData.tooltipTitle || tc.modelData.title || tc.modelData.id || "") : ""
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 2
                                    color: tcMa.containsMouse ? Kit.accent(0.22) : "transparent"
                                    border.width: 1
                                    border.color: tcMa.containsMouse ? Kit.white(0.40) : "transparent"
                                }
                                readonly property var pics: (tc.noIcon ? [] : ["" + tc.modelData.icon]).concat(root.trayPics(tc.modelData))
                                property int tried: 0
                                onPicsChanged: tc.tried = 0
                                readonly property string pic: tc.tried < tc.pics.length ? tc.pics[tc.tried] : ""
                                Icon {
                                    id: tcIcon
                                    x: 12
                                    y: 12
                                    width: 16
                                    height: 16
                                    src: tc.pic
                                    onStatusChanged: if (status === Image.Error) tc.tried += 1
                                }
                                Svg {
                                    visible: tc.pic === ""
                                    x: 12
                                    y: 12
                                    d: "M2.5 3.5 H13.5 V12.5 H2.5 Z"
                                    stroke: Kit.white(0.6)
                                    fill: Kit.white(0.12)
                                    sw: 1
                                }
                                QsMenuAnchor {
                                    id: tcMenu
                                    menu: tc.modelData ? tc.modelData.menu : null
                                    anchor.item: tc
                                    anchor.edges: Edges.Top
                                    anchor.gravity: Edges.Top
                                    onClosed: root.flyout = ""
                                }
                                MouseArea {
                                    id: tcMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.trayTip = tc.label
                                    onExited: if (root.trayTip === tc.label) root.trayTip = ""
                                    onClicked: function (mouse) {
                                        var m = tc.modelData
                                        if (!m) return
                                        if (m.hasMenu) { tcMenu.open(); return }
                                        root.flyout = ""
                                        if (mouse.button === Qt.RightButton) m.secondaryActivate()
                                        else m.activate()
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        x: 4
                        y: trayGrid.height + 8
                        width: 160
                        height: 1
                        color: Kit.white(0.18)
                    }
                    Text {
                        x: 4
                        y: trayGrid.height + 12
                        width: 160
                        height: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: root.flyout === "tray" ? root.trayTip : ""
                        color: "#ffffff"
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                }
            }
        }

        Flyout {
            name: "calendar"
            cell: clock
            flushRight: true
            gate: !!root.stagingEngine && root.stagingEngine.resolveSong(root.livery.songName, "calendar") !== ""
            implicitWidth: calRim.width
            implicitHeight: calRim.height + 6
            Rim {
                id: calRim
                width: calBody.implicitWidth + 14
                height: calBody.implicitHeight + 14
                WidgetSlot {
                    id: calBody
                    x: 7
                    y: 7
                    livery: root.livery
                    bridge: root.bridge
                    stagingEngine: root.stagingEngine
                    slot: "calendar"
                }
            }
        }

        Flyout {
            name: "action"
            cell: flag
            gate: !!root.stagingEngine && root.stagingEngine.resolveSong(root.livery.songName, "herald-center") !== ""
            implicitWidth: acRim.width
            implicitHeight: acRim.height + 6
            Rim {
                id: acRim
                width: acBody.implicitWidth + 14
                height: acBody.implicitHeight + 14
                WidgetSlot {
                    id: acBody
                    x: 7
                    y: 7
                    livery: root.livery
                    bridge: root.bridge
                    stagingEngine: root.stagingEngine
                    slot: "herald-center"
                }
            }
        }

        Flyout {
            name: "volume"
            cell: vol
            implicitWidth: volRim.width
            implicitHeight: volRim.height + 6
            Rim {
                id: volRim
                width: root.volW
                height: root.volH
                MouseArea {
                    anchors.fill: parent
                    enabled: root.volView === "main"
                    acceptedButtons: Qt.NoButton
                    onWheel: function (w) { root.nudgeVolume(w.angleDelta.y / 120 * 0.02) }
                }
                Plate { x: 7; y: 8; width: volRim.width - 14; height: volRim.height - 16 }

                VolCol {
                    visible: root.volView === "main"
                    x: 8
                    node: root.sink
                    label: root.sink ? root.nodeLabel(root.sink) : "No output"
                    picture: root.devPic(root.sink, true)
                    headed: true
                    metering: root.flyout === "volume" && root.volView === "main"
                    onHeaderClicked: root.openList("out", "main")
                }
                Rectangle {
                    visible: root.volView === "main"
                    x: 8; y: 272; width: 68; height: 24
                    color: Kit.accent(0.10)
                    Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: Kit.dark(0.15) }
                    Text {
                        id: mixerText
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 4; height: 16
                        verticalAlignment: Text.AlignVCenter
                        text: "Mixer"
                        color: Kit.ink
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                    Rectangle { visible: mixerMa.containsMouse; x: mixerText.x; y: 18; width: mixerText.width; height: 1; color: Kit.ink }
                    MouseArea {
                        id: mixerMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.volView = "mixer"
                    }
                }

                Text {
                    visible: root.volView === "list"
                    x: 16; y: 16; width: volRim.width - 32; height: 16
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: root.volPickKind === "in" ? "Input device" : "Output device"
                    color: Kit.ink
                    font: Kit.boldFont(11)
                    textFormat: Text.PlainText
                }
                Rectangle { visible: root.volView === "list"; x: 8; y: 40; width: volRim.width - 16; height: 1; color: Kit.dark(0.15) }
                ListView {
                    id: devList
                    visible: root.volView === "list"
                    x: 8; y: 44; width: volRim.width - 16; height: 224
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.volPickKind === "in" ? root.inNodes : root.outNodes
                    delegate: Item {
                        id: pick
                        required property var modelData
                        readonly property bool current: {
                            var c = root.volPickKind === "in" ? root.mic : root.sink
                            return !!c && c.id === pick.modelData.id
                        }
                        width: devList.width
                        height: 34
                        Rectangle {
                            anchors.fill: parent
                            color: pickMa.containsMouse ? Kit.accent(0.15) : pick.current ? Kit.accent(0.10) : "transparent"
                        }
                        Rectangle { visible: pick.current; x: 0; y: 0; width: 2; height: parent.height; color: "#25bbcf" }
                        Icon { x: 6; y: 9; width: 16; height: 16; src: root.devPic(pick.modelData, root.volPickKind !== "in") }
                        Text {
                            x: 30; y: 4; width: pick.width - 34; height: 15
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: root.nodeLabel(pick.modelData)
                            color: Kit.ink
                            font: Kit.bodyFont(11)
                            textFormat: Text.PlainText
                        }
                        Text {
                            x: 30; y: 19; width: pick.width - 34; height: 13
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: root.nodeGloss(pick.modelData)
                            color: Kit.dark(0.6)
                            font: Kit.bodyFont(9)
                            textFormat: Text.PlainText
                        }
                        MouseArea {
                            id: pickMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.volPickKind === "in") root.pickSource(pick.modelData)
                                else root.pickSink(pick.modelData)
                                root.volView = root.volBack
                            }
                        }
                    }
                }
                Text {
                    visible: root.volView === "list" && devList.count === 0
                    x: 8; y: 120; width: devList.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "No devices"
                    color: Kit.dark(0.6)
                    font: Kit.bodyFont(11)
                    textFormat: Text.PlainText
                }
                Rectangle {
                    visible: root.volView === "list"
                    x: 8; y: 272; width: volRim.width - 16; height: 24
                    color: Kit.accent(0.10)
                    Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: Kit.dark(0.15) }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 4; height: 16
                        verticalAlignment: Text.AlignVCenter
                        text: "Back"
                        color: Kit.ink
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.volView = root.volBack
                    }
                }

                VolCol {
                    visible: root.volView === "mixer"
                    x: 16
                    node: root.sink
                    label: root.sink ? root.nodeLabel(root.sink) : "No output"
                    picture: root.devPic(root.sink, true)
                    headed: true
                    metering: root.flyout === "volume" && root.volView === "mixer"
                    onHeaderClicked: root.openList("out", "mixer")
                }
                VolCol {
                    visible: root.volView === "mixer"
                    x: 92
                    node: root.mic
                    label: root.mic ? root.nodeLabel(root.mic) : "No input"
                    picture: root.devPic(root.mic, false)
                    headed: true
                    metering: root.flyout === "volume" && root.volView === "mixer"
                    onHeaderClicked: root.openList("in", "mixer")
                }
                Rectangle { visible: root.volView === "mixer"; x: 168; y: 16; width: 1; height: 248; color: Kit.dark(0.15) }
                MouseArea { visible: root.volView === "mixer"; x: 176; y: 0; width: 168; height: 272; acceptedButtons: Qt.NoButton; onWheel: function (w) { appCols.contentX = Math.max(0, Math.min(appCols.contentWidth - appCols.width, appCols.contentX - w.angleDelta.y)) } }
                ListView {
                    id: appCols
                    visible: root.volView === "mixer"
                    x: 176; y: 0; width: 168; height: 272
                    orientation: ListView.Horizontal
                    spacing: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.appNodes
                    delegate: VolCol {
                        required property var modelData
                        node: modelData
                        label: root.streamLabel(modelData)
                        picture: root.appPic(modelData)
                        metering: root.flyout === "volume" && root.volView === "mixer"
                    }
                }
                Text {
                    visible: root.volView === "mixer" && appCols.count === 0
                    x: 176; y: 120; width: 168
                    horizontalAlignment: Text.AlignHCenter
                    text: "No apps playing"
                    color: Kit.dark(0.6)
                    font: Kit.bodyFont(11)
                    textFormat: Text.PlainText
                }
                Rectangle {
                    visible: root.volView === "mixer"
                    x: 8; y: 272; width: volRim.width - 16; height: 24
                    color: Kit.accent(0.10)
                    Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: Kit.dark(0.15) }
                    Text {
                        x: 8; y: 4; height: 16
                        verticalAlignment: Text.AlignVCenter
                        text: "Back"
                        color: Kit.ink
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                    MouseArea {
                        x: 0; y: 0; width: 56; height: parent.height
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.volView = "main"
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 8
                        y: 4; height: 16
                        verticalAlignment: Text.AlignVCenter
                        text: "Advanced…"
                        color: Kit.ink
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                    MouseArea {
                        anchors.right: parent.right; y: 0; width: 84; height: parent.height
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.flyout = ""; root.runDetached("pavucontrol") }
                    }
                }
            }
        }

        Flyout {
            name: "network"
            cell: net
            implicitWidth: 300
            implicitHeight: netRim.height + 6
            Rim {
                id: netRim
                width: 300
                height: 7 + 26 + netPlate.height + 7
                Rectangle {
                    x: 7; y: 7; width: 286; height: 26
                    radius: 2
                    bottomLeftRadius: 0
                    bottomRightRadius: 0
                    color: Kit.dark(0.80)
                    Text {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.netUp ? "Currently connected to:" : "Not connected"
                        color: "#ffffff"
                        font: Kit.boldFont(12)
                        textFormat: Text.PlainText
                    }
                }
                Plate {
                    id: netPlate
                    readonly property int count: Math.max(1, Networking.devices && Networking.devices.values ? Networking.devices.values.length : 0)
                    x: 7; y: 33; width: 286
                    height: 58 + 29 + count * 26 + 4 + 26 + 2
                    topLeftRadius: 0
                    topRightRadius: 0
                    NetGlyph { x: 12; y: 12; kind: root.netKind; visible: root.netUp; transform: Scale { xScale: 2; yScale: 2 } }
                    Text {
                        x: 56; y: 11; width: parent.width - 56 - 12
                        text: root.netUp ? root.netName : "No network connection"
                        elide: Text.ElideRight
                        color: Kit.ink
                        font: Kit.boldFont(12)
                        textFormat: Text.PlainText
                    }
                    Text {
                        x: 56; y: 29; width: parent.width - 56 - 12
                        text: root.netAccess
                        elide: Text.ElideRight
                        color: Kit.dark(0.72)
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                    Item {
                        x: 4; y: 58; width: parent.width - 8; height: 26
                        Text { x: 8; y: 6; text: "Connections"; color: Kit.dark(0.72); font: Kit.boldFont(12); textFormat: Text.PlainText }
                        Rectangle { x: 0; y: 25; width: parent.width; height: 1; color: Kit.dark(0.20) }
                    }
                    Column {
                        x: 1; y: 87; width: parent.width - 2
                        Repeater {
                            model: Networking.devices
                            NetRow {
                                required property var modelData
                                readonly property bool wired: modelData.type === DeviceType.Wired
                                kind: wired ? "wired" : "wifi"
                                name: modelData.name
                                tag: modelData.connected
                                     ? (wired && modelData.linkSpeed > 0 ? "Connected · " + (modelData.linkSpeed >= 1000 ? modelData.linkSpeed / 1000 + " Gbps" : modelData.linkSpeed + " Mbps") : "Connected")
                                     : (modelData.state === ConnectionState.Connecting ? "Connecting…" : "Not connected")
                            }
                        }
                        NetRow {
                            visible: root.netViaRoute
                            height: visible ? 26 : 0
                            kind: root.netKind
                            name: root.netUp ? root.netName : "No network devices"
                            tag: root.netUp ? "Connected" : ""
                        }
                    }
                    Rectangle {
                        x: 1; y: parent.height - 1 - 26; width: parent.width - 2; height: 26
                        color: Kit.accent(0.10)
                        Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: Kit.dark(0.15) }
                        Text {
                            id: sharingText
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 5; height: 15
                            verticalAlignment: Text.AlignVCenter
                            text: "Open Network and Sharing Center"
                            color: Kit.ink
                            font: Kit.bodyFont(11)
                            textFormat: Text.PlainText
                        }
                        Rectangle { visible: sharingMa.containsMouse; x: sharingText.x; y: 19; width: sharingText.width; height: 1; color: Kit.ink }
                        MouseArea {
                            id: sharingMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.flyout = ""; root.runDetached("nm-connection-editor") }
                        }
                    }
                }
            }
        }

        Flyout {
            id: startFly
            name: "start"
            cell: orb
            flushLeft: true
            readonly property int rise: 24
            implicitWidth: Math.max(sm.x + ctxPlate.x + ctxPlate.width, sm.x + powerPlate.x + powerPlate.width)
            implicitHeight: startFly.rise + 560
            holdEscape: sm.ctxRow !== null
            mask: Region {
                width: 440; height: startFly.implicitHeight
                Region { item: sm.stageOpen ? stagePlate : null }
                Region { item: sm.powerOpen ? powerPlate : null }
                Region { item: sm.ctxRow !== null ? ctxPlate : null }
            }
            Shortcut { sequence: "Escape"; enabled: startFly.visible && sm.ctxRow !== null; onActivated: sm.ctxRow = null }

            Rim {
                y: startFly.rise
                width: 440
                height: 560
                topLeftRadius: 6
                topRightRadius: 6
                bottomLeftRadius: 0
                bottomRightRadius: 0

                Item {
                    id: sm
                    x: 1; y: 1; width: 438; height: 558

                    property bool allMode: false
                    property bool powerOpen: false
                    property string faceBust: root.bust
                    function pickPicture() {
                        picFly.refresh()
                        root.toggleFlyout("picture")
                    }

                    readonly property var pins: {
                        root.tick
                        if (!startFly.visible) return []
                        var defs = [["kitty", "Terminal", "kitty"], ["zen", "Zen", ""], null, ["codium", "VSCodium", ""],
                                    ["md.obsidian.Obsidian", "Obsidian", ""], ["vesktop", "Vesktop", ""], ["thunar", "Files", ""],
                                    ["com.github.th-ch.youtube-music", "Pear Desktop", ""], ["org.pulseaudio.pavucontrol", "Volume Control", ""],
                                    ["thunar-settings", "Settings", ""]]
                        var out = []
                        for (var i = 0; i < defs.length; i++) {
                            if (defs[i] === null) { out.push({ rule: true }); continue }
                            var e = sm.entryById(defs[i][0])
                            if (e) out.push({ rule: false, entry: e, label: defs[i][1], sub: defs[i][2] })
                        }
                        return out
                    }
                    readonly property var settingsEntry: { root.tick; return startFly.visible ? sm.entryById("thunar-settings") : null }
                    readonly property var results: startFly.visible ? sm.listFor(searchField.text) : []

                    function entryById(id) { return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id) }
                    function listFor(q) {
                        root.tick
                        var all = DesktopEntries.applications.values, out = [], needle = ("" + q).toLowerCase().trim()
                        for (var i = 0; i < all.length; i++) {
                            var e = all[i]
                            if (e.noDisplay) continue
                            if (needle && (("" + e.name).toLowerCase().indexOf(needle) < 0 && ("" + e.genericName).toLowerCase().indexOf(needle) < 0)) continue
                            out.push(e)
                        }
                        out.sort(function (a, b) {
                            if (needle) {
                                var pa = ("" + a.name).toLowerCase().indexOf(needle) === 0 ? 0 : 1
                                var pb = ("" + b.name).toLowerCase().indexOf(needle) === 0 ? 0 : 1
                                if (pa !== pb) return pa - pb
                            }
                            return ("" + a.name).toLowerCase() < ("" + b.name).toLowerCase() ? -1 : 1
                        })
                        return out
                    }
                    function reset() {
                        searchField.text = ""
                        sm.allMode = false
                        sm.powerOpen = false
                        sm.stageOpen = false
                        sm.ctxRow = null
                        Qt.callLater(function () { searchField.forceActiveFocus() })
                    }
                    function launch(e) {
                        if (!e || !e.command || e.command.length === 0) return
                        Quickshell.execDetached(Kit.scopeArgv(e))
                        root.flyout = ""
                    }
                    function openDir(sub) {
                        var h = Quickshell.env("HOME")
                        Quickshell.execDetached(["xdg-open", sub ? h + "/" + sub : h])
                        root.flyout = ""
                    }
                    function power(action) {
                        root.bridge.sendCommand({ cmd: "power", action: action })
                        root.flyout = ""
                    }
                    function shutdownDialog(action) {
                        root.flyout = ""
                        if (root.powermenu) root.powermenu.show(action)
                    }

                    property bool stageOpen: false
                    property var riceAnswer: null
                    property int riceAsked: 0
                    property bool ricePending: false
                    readonly property string riceKey: root.livery.riceMode + "/" + root.livery.songName + "/" + ((root.livery.modeRaw && root.livery.modeRaw.draft) || "")
                    onRiceKeyChanged: sm.ricePending = false
                    Timer { interval: 10000; running: sm.ricePending; onTriggered: sm.ricePending = false }
                    readonly property var stageRows: sm.ricePending ? [Rice.waiting(null)] : Rice.switchRows(sm.riceAnswer, root.livery.riceMode)
                    readonly property var draftRows: sm.ricePending || !Rice.ready(sm.riceAnswer) ? [] : [{
                        head: "drafts" + (sm.riceAnswer.draftsSong ? " · " + sm.riceAnswer.draftsSong : ""),
                        label: "", mark: "", live: false, kind: "", name: "", here: false
                    }].concat(Rice.draftRows(sm.riceAnswer), [Rice.newDraft(), Rice.saveDraft(root.livery.riceMode)])
                    function stage() {
                        sm.powerOpen = false
                        sm.ctxRow = null
                        sm.stageOpen = !sm.stageOpen
                        if (!sm.stageOpen) return
                        sm.riceAnswer = null
                        sm.riceAsk()
                    }
                    function riceAsk() {
                        var ask = ++sm.riceAsked
                        root.bridge.riceMenu(function (a) { if (ask === sm.riceAsked) sm.riceAnswer = a })
                    }
                    function rice(row) {
                        if (Rice.act(root.bridge, row)) sm.ricePending = true
                        root.flyout = ""
                    }
                    property var ctxRow: null
                    property real ctxY: 0
                    property bool ctxConfirm: false
                    readonly property var dropRow: sm.ctxRow ? Rice.dropDraft(sm.ctxRow) : null
                    function context(row, item) {
                        sm.ctxRow = row
                        sm.ctxConfirm = false
                        sm.ctxY = item.mapToItem(sm, 0, 0).y - 5
                    }
                    function drop() {
                        Rice.act(root.bridge, sm.dropRow)
                        sm.ctxRow = null
                        dropRefresh.restart()
                    }
                    Timer { id: dropRefresh; interval: 1000; onTriggered: if (sm.stageOpen) sm.riceAsk() }

                    Plate {
                        x: 8; y: 8; width: 276; height: 504

                        Column {
                            x: 5; y: 7; width: 266
                            visible: !sm.allMode && searchField.text === ""
                            Repeater {
                                model: sm.pins
                                Loader {
                                    required property var modelData
                                    width: 266
                                    height: modelData.rule ? 11 : 36
                                    sourceComponent: modelData.rule ? ruleC : rowC
                                    Component {
                                        id: rowC
                                        AppRow {
                                            entry: modelData.entry
                                            label: modelData.label
                                            sub: modelData.sub
                                            onActivated: sm.launch(modelData.entry)
                                        }
                                    }
                                    Component {
                                        id: ruleC
                                        Item {
                                            Rectangle { x: 8; y: 5; width: 250; height: 1; color: Kit.dark(0.20) }
                                        }
                                    }
                                }
                            }
                        }

                        ListView {
                            id: appList
                            x: 5; y: 7; width: 266; height: 458
                            visible: sm.allMode || searchField.text !== ""
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: sm.results
                            delegate: AppRow {
                                required property var modelData
                                required property int index
                                width: ListView.view.width
                                entry: modelData
                                sel: searchField.text !== "" && index === 0
                                onActivated: sm.launch(modelData)
                            }
                            Text {
                                visible: appList.count === 0
                                x: 9; y: 8
                                text: "No programs"
                                color: Kit.dark(0.55)
                                font: Kit.bodyFont(12)
                                textFormat: Text.PlainText
                            }
                        }

                        Item {
                            x: 5; y: 467; width: 266; height: 30
                            Rectangle {
                                anchors.fill: parent
                                radius: 2
                                color: allMa.containsMouse ? Kit.accent(0.10) : "transparent"
                                border.width: 1
                                border.color: "transparent"
                            }
                            Text {
                                x: 9
                                anchors.verticalCenter: parent.verticalCenter
                                text: sm.allMode ? "\u25C2 Back" : "All Programs"
                                color: Kit.ink
                                font: Kit.boldFont(12)
                                textFormat: Text.PlainText
                            }
                            Text {
                                visible: !sm.allMode
                                anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
                                text: "\u25B8"
                                color: Kit.ink
                                font: Kit.bodyFont(12)
                                textFormat: Text.PlainText
                            }
                            MouseArea {
                                id: allMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { searchField.text = ""; sm.allMode = !sm.allMode }
                            }
                        }
                    }

                    Rectangle {
                        x: 8; y: 520; width: 276; height: 32
                        radius: 2
                        color: "#ffffff"
                        border.width: 1
                        border.color: Kit.dark(0.55)
                        Rectangle {
                            x: 1; y: 1; width: parent.width - 2; height: 3
                            gradient: Gradient {
                                GradientStop { position: 0; color: Kit.dark(0.12) }
                                GradientStop { position: 1; color: Kit.dark(0) }
                            }
                        }
                        TextInput {
                            id: searchField
                            x: 11
                            width: parent.width - 11 - 34
                            anchors.verticalCenter: parent.verticalCenter
                            color: Kit.ink
                            font: Kit.bodyFont(12)
                            clip: true
                            selectByMouse: true
                            onTextChanged: if (text !== "") sm.allMode = false
                            Keys.onReturnPressed: if (text !== "") sm.launch(sm.results[0])
                            Keys.onEnterPressed: if (text !== "") sm.launch(sm.results[0])
                            Keys.onEscapePressed: root.flyout = ""
                            Text {
                                visible: searchField.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search programs"
                                color: Kit.dark(0.72)
                                font.family: Kit.family
                                font.pixelSize: 12
                                font.italic: true
                                textFormat: Text.PlainText
                            }
                        }
                        Svg { x: 251; y: 8; d: Kit.ell(6.5, 6.5, 4.5, 4.5, 0); stroke: Kit.dark(0.72); sw: 1.6 }
                        Svg { x: 251; y: 8; d: "M10 10 l4.5 4.5"; stroke: Kit.dark(0.72); sw: 2; cap: ShapePath.RoundCap }
                    }

                    Rectangle {
                        id: rightPane
                        x: 292; y: 8; width: 140; height: 504
                        radius: 2
                        color: Kit.dark(0.80)
                        ShadowText {
                            y: 40
                            width: 140
                            horizontalAlignment: Text.AlignHCenter
                            text: Quickshell.env("USER")
                            font: Kit.boldFont(13)
                        }
                        Column {
                            id: paneCol
                            x: 4; y: 70; width: 132
                            PaneRow { label: "Home"; onActivated: sm.openDir("") }
                            PaneRow { label: "Documents"; onActivated: sm.openDir("Documents") }
                            PaneRow { label: "Pictures"; onActivated: sm.openDir("Pictures") }
                            PaneRow { label: "Music"; onActivated: sm.openDir("Music") }
                            PaneRow { label: "Downloads"; onActivated: sm.openDir("Downloads") }
                            Item { width: 132; height: 13; Rectangle { x: 8; y: 6; width: 116; height: 1; color: Kit.white(0.18) } }
                            PaneRow { label: "Terminal"; onActivated: sm.launch(sm.entryById("kitty")) }
                            PaneRow {
                                visible: sm.settingsEntry !== null
                                height: visible ? rh : 0
                                label: "Settings"
                                onActivated: sm.launch(sm.settingsEntry)
                            }
                            PaneRow {
                                id: stageRow
                                label: "Stage"
                                lit: sm.stageOpen
                                enabled: !!root.bridge && typeof root.bridge.riceMenu === "function"
                                opacity: enabled ? 1 : 0.55
                                onActivated: sm.stage()
                                ShadowText {
                                    anchors { right: parent.right; rightMargin: 9; verticalCenter: parent.verticalCenter }
                                    text: "\u25B8"
                                    font: Kit.bodyFont(12)
                                }
                            }
                        }
                    }

                    Plate {
                        id: stagePlate
                        visible: sm.stageOpen
                        width: 220
                        height: stageCol.height + 10
                        x: sm.width + 3
                        y: Math.min(rightPane.y + paneCol.y + stageRow.y + (stageRow.height - 26) / 2 - stageCol.y, sm.height + 1 - height)
                        Column {
                            id: stageCol
                            x: 1; y: 5; width: parent.width - 2
                            Repeater {
                                model: sm.stageRows.concat(sm.draftRows)
                                PaneRow {
                                    id: stageItem
                                    required property var modelData
                                    plate: true; rh: modelData.head !== undefined ? 30 : 26; textX: 24
                                    label: modelData.label
                                    enabled: modelData.live
                                    lit: sm.ctxRow !== null && sm.ctxRow.kind === modelData.kind && sm.ctxRow.name === modelData.name
                                    onActivated: sm.rice(modelData)
                                    onContext: if (modelData.kind === "enter") sm.context(modelData, stageItem)
                                    Rectangle { visible: modelData.head !== undefined; x: 8; y: 5; width: parent.width - 16; height: 1; color: Kit.dark(0.20) }
                                    Text {
                                        visible: modelData.head !== undefined
                                        x: 9; y: 10; height: 20
                                        verticalAlignment: Text.AlignVCenter
                                        text: modelData.head || ""
                                        color: Kit.dark(0.72)
                                        font: Kit.boldFont(12)
                                        textFormat: Text.PlainText
                                    }
                                    Text { x: 9; anchors.verticalCenter: parent.verticalCenter; text: modelData.mark; color: Kit.ink; font: Kit.heavyFont(12); textFormat: Text.PlainText }
                                }
                            }
                        }
                    }

                    MouseArea {
                        visible: sm.ctxRow !== null
                        z: 50
                        x: -sm.x; y: -sm.y - startFly.rise
                        width: startFly.width; height: startFly.height
                        acceptedButtons: Qt.AllButtons
                        onPressed: sm.ctxRow = null
                    }

                    Plate {
                        id: ctxPlate
                        visible: sm.ctxRow !== null
                        z: 51
                        width: 220
                        height: ctxCol.height + 10
                        x: stagePlate.x + stagePlate.width + 3
                        y: Math.max(-startFly.rise - sm.y, Math.min(sm.ctxY, sm.height + 1 - height))
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                        Column {
                            id: ctxCol
                            x: 1; y: 5; width: parent.width - 2
                            PaneRow {
                                visible: !sm.ctxConfirm
                                height: visible ? rh : 0
                                plate: true; rh: 26; textX: 24
                                label: sm.dropRow ? sm.dropRow.label : ""
                                enabled: !!sm.dropRow && sm.dropRow.live
                                onActivated: sm.ctxConfirm = true
                            }
                            Text {
                                visible: sm.ctxConfirm
                                x: 9; width: parent.width - 18
                                topPadding: 4; bottomPadding: 8
                                wrapMode: Text.Wrap
                                text: sm.ctxRow ? "Delete " + sm.ctxRow.name + "? It can't be undone" : ""
                                color: Kit.ink
                                font: Kit.bodyFont(12)
                                textFormat: Text.PlainText
                            }
                            Row {
                                visible: sm.ctxConfirm
                                x: parent.width - width - 8
                                height: visible ? 30 : 0
                                spacing: 8
                                PlateButton { width: 64; label: "Delete"; onActivated: sm.drop() }
                                PlateButton { width: 64; label: "Cancel"; onActivated: sm.ctxRow = null }
                            }
                        }
                    }

                    Item {
                        x: 330; y: -24; width: 64; height: 64
                        Rectangle { x: 0; y: 2; width: 64; height: 64; radius: 4; color: Kit.withA("#000000", 0.20) }
                        Rectangle { x: -1; y: -1; width: 66; height: 66; radius: 5; color: "transparent"; border.width: 1; border.color: Kit.dark(0.85) }
                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            border.width: 1
                            border.color: Kit.white(0.60)
                            gradient: Gradient {
                                GradientStop { position: 0; color: Kit.white(0.55) }
                                GradientStop { position: 0.45; color: Kit.white(0.12) }
                                GradientStop { position: 1; color: Qt.rgba(42 / 255, 163 / 255, 184 / 255, 0.45) }
                            }
                        }
                        Rectangle {
                            x: 4; y: 4; width: 56; height: 56
                            radius: 2
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#0f5b78" }
                                GradientStop { position: 1; color: "#0a2c3e" }
                            }
                        }
                        Image {
                            id: faceImg
                            x: 8; y: 8; width: 48; height: 48
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(48, 48)
                            smooth: true
                            asynchronous: true
                            property int tryIndex: 0
                            readonly property var candidates: [
                                "file://" + picFly.face + sm.faceBust,
                                "file://" + picFly.fallback + sm.faceBust
                            ]
                            source: candidates[tryIndex]
                            onStatusChanged: if (status === Image.Error && tryIndex < candidates.length - 1) tryIndex++
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sm.pickPicture()
                        }
                    }

                    Plate {
                        id: powerPlate
                        visible: sm.powerOpen
                        width: 220
                        height: powCol.height + 10
                        x: sm.width + 3
                        y: Math.max(-startFly.rise - 1, lockBox.y + lockBox.height - height)
                        Column {
                            id: powCol
                            x: 1; y: 5; width: parent.width - 2
                            PowerRow { label: "Switch user"; pic: "switch-user"; enabled: false }
                            PowerRow { action: "logout"; onActivated: sm.shutdownDialog("logout") }
                            PowerRow { action: "suspend"; onActivated: sm.power("suspend") }
                            PowerRow { action: "hibernate"; onActivated: sm.power("hibernate") }
                            PowerRow { action: "reboot"; onActivated: sm.shutdownDialog("reboot") }
                            PowerRow { action: "shutdown"; more: true; onActivated: sm.shutdownDialog() }
                        }
                    }

                    Item {
                        id: lockBox
                        x: 296; y: 520; width: 132; height: 32
                        Rectangle { x: -1; y: -1; width: 134; height: 34; radius: 4; color: "transparent"; border.width: 1; border.color: Kit.dark(0.85) }
                        Rectangle {
                            x: 0; y: 0; width: 100; height: 32
                            topLeftRadius: 3; bottomLeftRadius: 3
                            color: lockMa.containsMouse ? Qt.rgba(42 / 255, 163 / 255, 184 / 255, 0.55) : Kit.dark(0.80)
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; top: parent.top }
                                height: 16
                                topLeftRadius: 3
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Kit.white(0.22) }
                                    GradientStop { position: 1; color: Kit.white(0.06) }
                                }
                            }
                            Rectangle { x: 99; y: 0; width: 1; height: 32; color: Kit.dark(0.85) }
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Item {
                                    width: 12; height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    Svg { d: "M1.5 6 h9 a0.5 0.5 0 0 1 0.5 0.5 V12 a1.5 1.5 0 0 1 -1.5 1.5 h-7 a1.5 1.5 0 0 1 -1.5 -1.5 V6.5 a0.5 0.5 0 0 1 0.5 -0.5 z"; fill: "#ffffff" }
                                    Svg { d: "M3 6 V4 a3 3 0 0 1 6 0 v2"; stroke: "#ffffff"; sw: 1.6 }
                                }
                                ShadowText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Lock"
                                    font: Kit.bodyFont(12)
                                }
                            }
                            MouseArea {
                                id: lockMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sm.power("lock")
                            }
                        }
                        Rectangle {
                            x: 100; y: 0; width: 32; height: 32
                            topRightRadius: 3; bottomRightRadius: 3
                            color: moreMa.containsMouse || sm.powerOpen ? Qt.rgba(42 / 255, 163 / 255, 184 / 255, 0.55) : Kit.dark(0.80)
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; top: parent.top }
                                height: 16
                                topRightRadius: 3
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Kit.white(0.22) }
                                    GradientStop { position: 1; color: Kit.white(0.06) }
                                }
                            }
                            Svg { x: 12; y: 11; d: "M1 1l5 4-5 4z"; fill: "#ffffff" }
                            MouseArea {
                                id: moreMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { sm.stageOpen = false; sm.powerOpen = !sm.powerOpen }
                            }
                        }
                        Rectangle { anchors.fill: parent; radius: 3; color: "transparent"; border.width: 1; border.color: Kit.white(0.35) }
                    }
                }
            }
        }

        Flyout {
            id: picFly
            name: "picture"
            cell: orb
            flushLeft: true
            readonly property int rise: 24
            readonly property string home: Quickshell.env("HOME") || ""
            readonly property string face: picFly.home + "/.face"
            readonly property string songDir: root.iconDir + "user/"
            readonly property string fallback: picFly.songDir + "chrome-sash.svg"
            readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (picFly.home + "/.cache")) + "/barcarolle/picture"
            readonly property var songTiles: [
                { path: picFly.fallback, key: picFly.cacheDir + "/chrome-sash.png", song: true },
                { path: picFly.songDir + "silhouette.svg", key: picFly.cacheDir + "/silhouette.png", song: true },
                { path: picFly.songDir + "pixel-face.svg", key: picFly.cacheDir + "/pixel-face.png", song: true }
            ]
            property string pictDir: picFly.home + "/Pictures/avatars"
            readonly property string shownDir: picFly.home !== "" && picFly.pictDir.indexOf(picFly.home + "/") === 0 ? "~" + picFly.pictDir.substring(picFly.home.length) : picFly.pictDir
            property var folderTiles: []
            readonly property var listed: picFly.songTiles.concat(picFly.folderTiles)
            property var hashes: ({})
            readonly property string faceHash: picFly.hashes[picFly.face] || ""
            readonly property bool faceListed: {
                for (var i = 0; i < picFly.listed.length; i++) if (picFly.hashes[picFly.listed[i].key] === picFly.faceHash) return true
                return false
            }
            readonly property var handTiles: picFly.faceHash === "" || picFly.faceListed ? [] : [{ path: picFly.face, key: picFly.face, song: false, hand: true }]
            readonly property var tiles: picFly.handTiles.concat(picFly.listed)
            property string picked: ""
            property string note: ""
            property string snapTarget: ""
            property string probing: ""
            property bool snapping: false
            readonly property string keepScript: 'ext=img; case $(od -An -N12 -tx1 -- "$2" | tr -d " \\n") in 89504e47*) ext=png ;; ffd8ff*) ext=jpg ;; 47494638*) ext=gif ;; 52494646????????57454250*) ext=webp ;; esac; mkdir -p -- "$1" && { [ ! -e "$1/previous-$3.$ext" ] || exit 3; } && cp -- "$2" "$1/previous-$3.$ext"'
            implicitWidth: 360
            implicitHeight: picFly.rise + 340

            component PicRun: Process {
                id: pr
                property var done: null
                property int code: -1
                property int halves: 0
                property bool began: false
                stdout: StdioCollector {
                    id: prOut
                    waitForEnd: true
                    onStreamFinished: pr.half()
                }
                onStarted: pr.began = true
                onExited: function (exitCode) { pr.code = exitCode; pr.half() }
                onRunningChanged: if (!pr.running && !pr.began && pr.done) pr.finish(127, "")
                function run(argv, cb) {
                    if (pr.running) return false
                    pr.done = cb
                    pr.halves = 0
                    pr.code = -1
                    pr.began = false
                    pr.command = argv
                    pr.running = true
                    return true
                }
                function half() {
                    pr.halves++
                    if (pr.halves === 2) pr.finish(pr.code, prOut.text)
                }
                function finish(c, text) {
                    var f = pr.done
                    pr.done = null
                    pr.halves = 0
                    if (f) f(c, text)
                }
            }

            PicRun { id: picRead }
            PicRun { id: picAct }

            Component.onCompleted: picRead.run(["xdg-user-dir", "PICTURES"], function (code, text) {
                var d = ("" + text).trim()
                if (code === 0 && d !== "") picFly.pictDir = d + "/avatars"
            })

            function isCurrent(t) {
                if (picFly.faceHash === "") return t.song && t.path === picFly.fallback
                return picFly.hashes[t.key] === picFly.faceHash
            }
            function tileFor(path) {
                for (var i = 0; i < picFly.tiles.length; i++) if (picFly.tiles[i].path === path) return picFly.tiles[i]
                return null
            }
            function refresh() {
                if (picRead.running) return
                picFly.note = ""
                picRead.run(["find", picFly.pictDir, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", "-o", "-iname", "*.gif", ")"], function (code, text) {
                    picFly.folderTiles = ("" + text).split("\n").filter(function (p) { return p !== "" }).sort().map(function (p) { return { path: p, key: p, song: false } })
                    picFly.hashTiles()
                })
            }
            function digest(paths, cb) {
                var argv = ["sha256sum", "--", picFly.face]
                for (var i = 0; i < paths.length; i++) argv.push(paths[i])
                return picRead.run(argv, function (code, text) {
                    var h = {}, lines = ("" + text).split("\n")
                    for (var j = 0; j < lines.length; j++) {
                        var sp = lines[j].indexOf("  ")
                        if (sp > 0) h[lines[j].substring(sp + 2)] = lines[j].substring(0, sp)
                    }
                    cb(h)
                })
            }
            function hashTiles() {
                picFly.digest(picFly.listed.map(function (t) { return t.key }), function (h) {
                    picFly.hashes = h
                    picFly.picked = ""
                    for (var k = 0; k < picFly.tiles.length; k++) {
                        if (picFly.isCurrent(picFly.tiles[k])) { picFly.picked = picFly.tiles[k].path; break }
                    }
                })
            }
            function failed(more) {
                picFly.snapping = false
                picFly.probing = ""
                picFly.note = "Could not change the picture." + (more || "")
            }
            function keep(then) {
                var argv = ["sh", "-c", picFly.keepScript, "sh", picFly.pictDir, picFly.face, Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss")]
                if (!picAct.run(argv, function (code) {
                    if (code === 0) then()
                    else if (code === 3) picFly.failed(" Try again in a second.")
                    else picFly.failed()
                })) picFly.failed()
            }
            function install(src) {
                var keys = picFly.listed.map(function (t) { return t.key })
                if (!picFly.digest(keys, function (h) {
                    var mine = h[picFly.face]
                    if (mine === undefined || keys.some(function (k) { return h[k] === mine })) return picFly.place(src)
                    picFly.keep(function () { picFly.place(src) })
                })) picFly.failed()
            }
            function place(src) {
                if (!picAct.run(["cp", "--remove-destination", "--", src, picFly.face], function (code) {
                    if (code !== 0) return picFly.failed()
                    sm.faceBust = "?v=" + Date.now()
                    faceImg.tryIndex = 0
                    root.flyout = ""
                })) picFly.failed()
            }
            function capture() {
                picFly.snapping = false
                snap.grabToImage(function (r) {
                    if (!r || !r.saveToFile(picFly.snapTarget)) return picFly.failed()
                    picFly.install(picFly.snapTarget)
                })
            }
            function stage(t) {
                if (!t.song) {
                    picFly.probing = t.path
                    probeImg.source = ""
                    probeImg.source = "file://" + t.path + root.bust
                    return
                }
                picAct.run(["mkdir", "-p", "--", picFly.cacheDir], function (code) {
                    if (code !== 0) return picFly.failed()
                    picFly.snapTarget = t.key
                    picFly.snapping = true
                    snapImg.source = ""
                    snapImg.source = "file://" + t.path + root.bust
                })
            }
            function apply() {
                var t = picFly.picked === "" ? null : picFly.tileFor(picFly.picked)
                if (!t || picRead.running || picAct.running) return
                if (picFly.isCurrent(t)) { root.flyout = ""; return }
                picFly.note = ""
                picFly.stage(t)
            }
            function folderArgv(entry, dir) {
                if (!entry || !entry.command || entry.command.length === 0) return []
                var out = [], filled = false
                for (var i = 0; i < entry.command.length; i++) {
                    var a = "" + entry.command[i]
                    if (/^%[ikc]$/.test(a)) continue
                    if (/%[UuFf]/.test(a)) { a = a.replace(/%[UuFf]/g, dir); filled = true }
                    out.push(a)
                }
                if (!filled) out.push(dir)
                return out
            }
            function openFolder() {
                picAct.run(["mkdir", "-p", "--", picFly.pictDir], function (code) {
                    if (code !== 0) { picFly.note = "Could not create " + picFly.pictDir; return }
                    picRead.run(["xdg-mime", "query", "default", "inode/directory"], function (c, text) {
                        var id = c === 0 ? ("" + text).trim().replace(/\.desktop$/, "") : ""
                        var argv = id === "" ? [] : picFly.folderArgv(DesktopEntries.byId(id), picFly.pictDir)
                        if (argv.length > 0) Quickshell.execDetached(Kit.scopeArgv({ command: argv }))
                        else Quickshell.execDetached(["xdg-open", picFly.pictDir])
                        root.flyout = ""
                    })
                })
            }

            Item {
                id: snap
                x: -300; y: 0
                width: 256; height: 256
                Image {
                    id: snapImg
                    anchors.fill: parent
                    sourceSize: Qt.size(256, 256)
                    asynchronous: false
                    fillMode: Image.PreserveAspectFit
                    onStatusChanged: if (status === Image.Ready && picFly.snapping) picFly.capture(); else if (status === Image.Error && picFly.snapping) picFly.failed()
                }
            }
            Image {
                id: probeImg
                x: -300; y: 300
                width: 1; height: 1
                asynchronous: false
                onStatusChanged: {
                    if (picFly.probing === "") return
                    if (status === Image.Ready) {
                        var p = picFly.probing
                        picFly.probing = ""
                        picFly.install(p)
                    } else if (status === Image.Error) picFly.failed()
                }
            }

            Rim {
                y: picFly.rise
                width: 360
                height: 340
                topLeftRadius: 6
                topRightRadius: 6
                bottomLeftRadius: 0
                bottomRightRadius: 0

                ShadowText {
                    x: 12; y: 4
                    width: 336
                    text: "Change your picture"
                    font: Kit.boldFont(12)
                }
                Plate {
                    x: 8; y: 30; width: 344; height: 262

                    GridView {
                        id: tileGrid
                        x: 8; y: 8; width: 328; height: 164
                        cellWidth: 82; cellHeight: 82
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: picFly.tiles
                        delegate: Item {
                            required property var modelData
                            width: 82; height: 82
                            readonly property bool sel: picFly.picked === modelData.path
                            readonly property bool cur: picFly.isCurrent(modelData)
                            Rectangle {
                                x: 6; y: 6; width: 70; height: 70
                                radius: 2
                                color: sel ? Kit.accent(0.22) : "transparent"
                                border.width: cur ? 2 : 1
                                border.color: cur ? Kit.accent(1) : (sel ? Kit.dark(0.55) : "transparent")
                            }
                            Image {
                                x: 9; y: 9; width: 64; height: 64
                                source: "file://" + modelData.path + root.bust
                                sourceSize: Qt.size(64, 64)
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                            }
                            Rectangle {
                                visible: modelData.hand === true
                                x: 9; y: 57; width: 64; height: 16
                                color: Kit.white(0.85)
                                Text {
                                    anchors.centerIn: parent
                                    text: "Current"
                                    color: Kit.ink
                                    font: Kit.bodyFont(10)
                                    textFormat: Text.PlainText
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: picFly.picked = modelData.path
                            }
                        }
                    }
                    Text {
                        visible: picFly.folderTiles.length === 0
                        x: 12; y: 180
                        text: "No pictures in this folder yet."
                        color: Kit.dark(0.72)
                        font: Kit.bodyFont(12)
                        textFormat: Text.PlainText
                    }
                    Row {
                        x: 12; y: 202
                        Text {
                            text: "Put pictures in "
                            color: Kit.ink
                            font: Kit.bodyFont(12)
                            textFormat: Text.PlainText
                        }
                        Text {
                            text: picFly.shownDir
                            color: Kit.ink
                            font.family: Kit.family
                            font.pixelSize: 12
                            font.underline: true
                            textFormat: Text.PlainText
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: picFly.openFolder()
                            }
                        }
                    }
                    Text {
                        x: 12; y: 228; width: 320
                        text: picFly.note
                        color: Kit.ink
                        font: Kit.bodyFont(12)
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }
                Rectangle {
                    x: 160; y: 300; width: 124; height: 26
                    radius: 2
                    color: "#ffffff"
                    border.width: 1
                    border.color: changeMa.containsMouse ? Kit.accent(1) : Kit.dark(0.55)
                    opacity: picFly.picked === "" ? 0.5 : 1
                    Text {
                        anchors.centerIn: parent
                        text: "Change Picture"
                        color: Kit.ink
                        font: Kit.boldFont(12)
                        textFormat: Text.PlainText
                    }
                    MouseArea {
                        id: changeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: picFly.apply()
                    }
                }
                Rectangle {
                    x: 292; y: 300; width: 60; height: 26
                    radius: 2
                    color: "#ffffff"
                    border.width: 1
                    border.color: cancelMa.containsMouse ? Kit.accent(1) : Kit.dark(0.55)
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Kit.ink
                        font: Kit.bodyFont(12)
                        textFormat: Text.PlainText
                    }
                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.flyout = ""
                    }
                }
            }
        }
        WidgetSlot {
            id: riceSlot
            livery: root.livery
            bridge: root.bridge
            stagingEngine: root.stagingEngine
            slot: "ricemode"
            anchors.right: agents.left
            anchors.top: parent.top
        }
    }
}
