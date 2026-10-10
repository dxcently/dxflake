import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Pipewire
import "../.."
import "Kit.js" as Kit

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
        function onRawEvent(e) { settle.restart() }
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { settle.restart() }
    }
    Timer { id: settle; interval: 60; onTriggered: root.tick++ }

    readonly property int rigPeek: parseInt(Quickshell.env("AOIDE_RIG_PEEK") || "-1")

    property var sessByAddr: ({})
    property int awaitingCount: 0
    property int workingCount: 0

    property string coverPath: Quickshell.env("AOIDE_WALLPAPER") || ""
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
                root.coverPath = (d && d.path && (!d.song || d.song === root.livery.songName)) ? "" + d.path : baked
            } catch (e) { root.coverPath = baked }
        }
        onLoadFailed: root.coverPath = Quickshell.env("AOIDE_WALLPAPER") || ""
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
        return p
    }

    function build(screenName) {
        root.tick
        var wss = (Hyprland.workspaces && Hyprland.workspaces.values) ? Hyprland.workspaces.values : []
        var tops = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : []
        var front = Hyprland.activeToplevel ? Hyprland.activeToplevel.address : ""
        var rows = [], drawers = [], lists = {}, exists = {}
        for (var i = 0; i < wss.length; i++) {
            var w = wss[i]
            if (!w) continue
            exists[w.id] = true
            if (!w.monitor || w.monitor.name !== screenName) continue
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
                active: w.active === true,
                urgent: w.urgent === true,
                awaiting: aw,
                working: wk,
                ghost: false
            }
            if (w.id > 0) rows.push(m)
            else if (m.wins > 0 || w.active) drawers.push(m)
        }
        for (var n = 1; n <= 8; n++)
            if (!exists[n]) rows.push({ id: n, name: "" + n, ws: null, wins: 0, icons: [], active: false, urgent: false, awaiting: 0, working: 0, ghost: true })
        rows.sort(function (a, b) { return a.id - b.id })
        drawers.sort(function (a, b) { return a.name < b.name ? -1 : 1 })
        return { rows: rows, drawers: drawers, lists: lists }
    }

    function nextEmpty(rows) {
        var used = {}
        for (var i = 0; i < rows.length; i++) if (rows[i].wins > 0 || rows[i].active) used[rows[i].id] = true
        var wss = Hyprland.workspaces.values
        for (var k = 0; k < wss.length; k++) if (wss[k].id > 0) {
            var occupied = false
            for (var q = 0; q < Hyprland.toplevels.values.length; q++) {
                var t = Hyprland.toplevels.values[q]
                if (t.workspace && t.workspace.id === wss[k].id) { occupied = true; break }
            }
            if (occupied || wss[k].active) used[wss[k].id] = true
        }
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
        win.hotId = -1
        win.hotBtn = null
        if (root.flyout === "start") sm.reset()
        if (root.dock && typeof root.dock.hide === "function") root.dock.hide()
        var menu = riceSlot._item
        if (menu && menu.open) menu.open = false
    }
    readonly property bool flyoutOpen: root.flyout !== "" || (!!root.dock && !!root.dock.shown)
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
        function onOpenChanged() { var menu = riceSlot._item; if (menu && menu.open) root.flyout = "" }
    }

    readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    readonly property var sinkAudio: root.sink && root.sink.audio ? root.sink.audio : null
    readonly property real volLevel: root.sinkAudio ? root.sinkAudio.volume : 0
    readonly property bool volMuted: root.sinkAudio ? root.sinkAudio.muted : false
    readonly property bool volSilent: !root.sinkAudio || root.volMuted || root.volLevel <= 0
    function setVolume(v) {
        if (!root.sinkAudio) return
        root.sinkAudio.volume = Math.max(0, Math.min(1, v))
        if (v > 0 && root.sinkAudio.muted) root.sinkAudio.muted = false
    }
    function nudgeVolume(delta) { root.setVolume(root.volLevel + delta) }
    function runDetached(name) { Quickshell.execDetached(["systemd-run", "--user", "--scope", name]) }

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
        running: root.flyout === "network"
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
        source: src ? (src.indexOf("/") === 0 ? "file://" + src : src) : ""
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
        readonly property bool lit: m.active
        readonly property real faceW: occ ? 56 : 38
        readonly property alias hovered: ma.containsMouse
        width: occ ? Kit.buttonWidth : Kit.emptyWidth
        height: Kit.barHeight

        Rectangle {
            visible: b.m.wins >= 3
            x: 6; y: 2; width: 56; height: 36; radius: 3
            color: Kit.white(0.10); border.width: 1; border.color: Kit.white(0.18)
        }
        Rectangle {
            visible: b.m.wins >= 2
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

        Icon { visible: b.occ && src.length > 0; x: 4; y: 4; width: 28; height: 28; src: b.m.icons.length > 0 ? b.m.icons[0] : "" }
        Icon { visible: b.occ && src.length > 0; x: 37; y: 6; width: 14; height: 14; src: b.m.icons.length > 1 ? b.m.icons[1] : "" }
        Icon { visible: b.occ && src.length > 0 && b.m.icons.length <= 3; x: 37; y: 22; width: 14; height: 14; src: b.m.icons.length > 2 ? b.m.icons[2] : "" }
        Chip {
            visible: b.m.icons.length > 3
            x: 37; y: 22; width: 15; h: 14; px: 9
            label: "+" + (b.m.icons.length - 2)
        }

        Chip {
            x: b.occ ? 1 : 12
            y: b.occ ? 24 : 13
            label: "" + b.m.id
        }
        Dot {
            visible: b.occ && (b.m.awaiting > 0 || b.m.working > 0)
            x: 22; y: 24
            tone: b.m.awaiting > 0 ? root.kit.awaiting : root.kit.working
            label: b.m.awaiting > 0 ? "❚❚" : (b.m.working > 1 ? "" + b.m.working : "●")
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (b.m.ws) b.m.ws.activate()
                else {
                    if (win.screen) Hyprland.dispatch("focusmonitor " + win.screen.name)
                    Hyprland.dispatch("workspace " + b.m.id)
                }
            }
        }
    }

    component Drawer: Item {
        id: dr
        required property var m
        readonly property bool open: m.active
        width: 40
        height: open ? 38 : 36
        y: open ? 2 : 4
        Svg {
            d: "M0 " + dr.height + " V4 a4 4 0 0 1 4 -4 H36 a4 4 0 0 1 4 4 V" + dr.height + " Z"
            fill: dr.open ? "transparent" : Kit.white(0.05)
        }
        Rectangle {
            visible: dr.open
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Kit.white(0.16) }
                GradientStop { position: 1; color: Kit.white(0.06) }
            }
        }
        Svg {
            d: "M0.5 " + (dr.height - 0.5) + " V4.5 a4 4 0 0 1 4 -4 H35.5 a4 4 0 0 1 4 4 V" + (dr.height - 0.5) + " Z"
            stroke: Kit.white(0.20)
        }
        Svg {
            visible: dr.open
            d: "M0.8 5 a4.2 4.2 0 0 1 4.2 -4.2 H35 a4.2 4.2 0 0 1 4.2 4.2"
            stroke: Kit.cyan
            sw: 2
        }
        Item {
            x: 3; y: 3 - (dr.open ? 0 : 0)
            Svg { d: "M3 4 H11.5 a1.5 1.5 0 0 1 1.5 1.5 V11 a1.5 1.5 0 0 1 -1.5 1.5 H3 a1.5 1.5 0 0 1 -1.5 -1.5 V5.5 a1.5 1.5 0 0 1 1.5 -1.5 Z"; stroke: Kit.white(0.7) }
            Svg { d: "M5 2 H13 a1.5 1.5 0 0 1 1.5 1.5 V9 a1.5 1.5 0 0 1 -1.5 1.5 H5 a1.5 1.5 0 0 1 -1.5 -1.5 V3.5 a1.5 1.5 0 0 1 1.5 -1.5 Z"; stroke: "#ffffff"; fill: Kit.dark(0.6) }
        }
        Icon { x: 20; y: 4; width: 16; height: 16; src: dr.m.icons.length > 0 ? dr.m.icons[0] : "" }
        Chip { x: 2; y: 22; px: 9; h: 11; label: dr.m.name.substring(0, 3) }
        MouseArea {
            anchors.fill: parent
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
            src: ar.entry ? (Quickshell.iconPath(ar.entry.icon, true) || Quickshell.iconPath("application-x-executable", true)) : ""
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
        signal activated()
        width: parent ? parent.width : 132
        height: rh
        Rectangle {
            anchors.fill: parent
            radius: 2
            color: prMa.containsMouse ? (pr.plate ? Kit.accent(0.10) : Kit.white(0.12)) : "transparent"
            border.width: 1
            border.color: prMa.containsMouse && !pr.plate ? Kit.white(0.40) : "transparent"
        }
        Text {
            visible: pr.plate
            x: 9
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
            cursorShape: pr.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: pr.activated()
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
        grabFocus: true
        onVisibleChanged: {
            if (fy.visible || root.flyout !== fy.name) return
            root.flyoutGone = fy.name
            root.flyoutGoneAt = Date.now()
            root.flyout = ""
        }
        Shortcut { sequence: "Escape"; enabled: fy.visible; onActivated: root.flyout = "" }
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

        Item {
            anchors.fill: parent
            clip: true
            Image {
                id: frostSrc
                visible: false
                width: win.screen ? win.screen.width : win.width
                height: win.screen ? win.screen.height : 1080
                y: Kit.barHeight - height
                source: root.coverPath.length > 0 ? "file://" + root.coverPath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
            }
            MultiEffect {
                source: frostSrc
                x: frostSrc.x; y: frostSrc.y
                width: frostSrc.width; height: frostSrc.height
                blurEnabled: true
                blur: 1.0
                blurMax: 48
                saturation: 0.35
            }
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
                    x: 13.5; y: 9
                    Svg { d: "M5 2 v15"; stroke: "#ffffff"; sw: 2.2; cap: ShapePath.RoundCap }
                    Svg { d: Kit.ell(3, 17.5, 3.6, 2.7, -20); fill: "#ffffff"; stroke: Kit.withA("#081e2b", 0.45) }
                    Svg { d: "M6 2 c3 0 3 2.2 6 2.2"; stroke: "#4fd8e6"; sw: 1.8; cap: ShapePath.RoundCap }
                    Svg { d: "M6 5 c3 0 3 2.2 6 2.2"; stroke: "#ffffff"; sw: 1.8; cap: ShapePath.RoundCap }
                    Svg { d: "M6 8 c3 0 3 2.2 6 2.2"; stroke: "#2aa3b8"; sw: 1.8; cap: ShapePath.RoundCap }
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
            height: Kit.barHeight
            spacing: 2
            Repeater {
                model: win.model.rows
                onItemAdded: function (i, item) { if (item.m.id === root.rigPeek) win.rigBtn = item }
                WsButton {
                    required property var modelData
                    m: modelData
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
                    width: 40; height: Kit.barHeight
                    Drawer { m: slot.modelData }
                }
            }
            Item {
                width: 28; height: Kit.barHeight
                Item {
                    y: 2; width: 28; height: 36
                    Svg {
                        d: "M3.5 0.5 H24.5 a3 3 0 0 1 3 3 V32.5 a3 3 0 0 1 -3 3 H3.5 a3 3 0 0 1 -3 -3 V3.5 a3 3 0 0 1 3 -3 Z"
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
                        var n = root.nextEmpty(win.model.rows)
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
            readonly property real k: win.screen ? 240 / win.screen.width : 0.125
            readonly property int miniH: win.screen ? Math.round(240 * win.screen.height / win.screen.width) : 135
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
                        Image {
                            anchors.fill: parent
                            source: root.coverPath.length > 0 ? "file://" + root.coverPath : ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 480
                            asynchronous: true
                        }
                        Repeater {
                            model: peek.visible && peek.ws ? peek.ws.toplevels : null
                            Item {
                                id: tile
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject
                                readonly property bool placed: !!(ipc && ipc.at && ipc.size && win.screen)
                                visible: placed && !ipc.hidden
                                z: placed && ipc.floating ? 1 : 0
                                x: placed ? (ipc.at[0] - win.screen.x) * peek.k : 0
                                y: placed ? (ipc.at[1] - win.screen.y) * peek.k : 0
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
            Svg { x: 3; y: 12; d: "M1.5 5.5 h3 l4 -3 v11 l-4 -3 h-3 z"; fill: "#ffffff" }
            Svg { visible: !root.volSilent; x: 3; y: 12; d: "M11 5 a4 4 0 0 1 0 6"; stroke: "#ffffff"; sw: 1.3; cap: ShapePath.RoundCap }
            Svg { visible: !root.volSilent && root.volLevel >= 0.5; x: 3; y: 12; d: "M13.2 3 a7 7 0 0 1 0 10"; stroke: "#ffffff"; sw: 1.3; cap: ShapePath.RoundCap }
            Svg { visible: root.volSilent; x: 3; y: 12; d: "M11.5 5.5 l4.5 5 M16 5.5 l-4.5 5"; stroke: "#ffffff"; sw: 1.3; cap: ShapePath.RoundCap }
        }
        Cell {
            id: net
            anchors.right: vol.left
            lit: root.flyout === "network"
            onClicked: root.toggleFlyout("network")
            Svg { x: 3; y: 12; d: "M3.5 1.5 H14.5 a1 1 0 0 1 1 1 V9.5 a1 1 0 0 1 -1 1 H3.5 a1 1 0 0 1 -1 -1 V2.5 a1 1 0 0 1 1 -1 Z"; stroke: "#ffffff"; fill: Kit.dark(1) }
            Svg { x: 3; y: 12; d: "M4 3 H14 V9 H4 Z"; fill: Kit.withA("#2aa3b8", 0.8) }
            Svg { x: 3; y: 12; d: "M9 10.5 v2.5 M5 14.5 h8"; stroke: "#ffffff"; sw: 1.4 }
        }
        Cell {
            id: flag
            anchors.right: net.left
            lit: root.flyout === "action"
            onClicked: root.toggleFlyout("action")
            Svg { x: 4; y: 12; d: "M3 1.5 v13.5"; stroke: "#ffffff"; sw: 1.5 }
            Svg { x: 4; y: 12; d: "M3.5 2.5 c3 -1.5 5 1.5 9.5 0 v7 c-4.5 1.5 -6.5 -1.5 -9.5 0 z"; fill: Kit.white(0.9) }
            Dot {
                visible: root.heraldCount > 0
                x: 14; y: 22; d: 9
                tone: root.kit.urgent
            }
        }
        Cell {
            id: agents
            anchors.right: flag.left
            onClicked: if (root.dock && root.dock.toggle) root.dock.toggle()
            Svg { x: 3; y: 12; d: "M3 4.5 H11 a1.5 1.5 0 0 1 1.5 1.5 V12 a1.5 1.5 0 0 1 -1.5 1.5 H3 a1.5 1.5 0 0 1 -1.5 -1.5 V6 a1.5 1.5 0 0 1 1.5 -1.5 Z"; stroke: Kit.white(0.7) }
            Svg { x: 3; y: 12; d: "M7 1.5 H15 a1.5 1.5 0 0 1 1.5 1.5 V9 a1.5 1.5 0 0 1 -1.5 1.5 H7 a1.5 1.5 0 0 1 -1.5 -1.5 V3 a1.5 1.5 0 0 1 1.5 -1.5 Z"; stroke: "#ffffff"; fill: Kit.dark(1) }
            Svg { x: 3; y: 12; d: "M7.5 4 l2 1.8 -2 1.8"; stroke: "#ffffff"; sw: 1.3 }
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
            width: 18
            anchors.right: agents.left
            Svg { x: 4.5; y: 17; d: "M1 5 l3.5 -3.5 L8 5"; stroke: "#ffffff"; sw: 1.4 }
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
            implicitWidth: 84
            implicitHeight: 308
            Rim {
                width: 84
                height: 302
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: function (w) { root.nudgeVolume(w.angleDelta.y / 120 * 0.02) }
                }
                Plate { x: 7; y: 7; width: 70; height: 288 }
                Text {
                    x: 7; y: 16; width: 70; height: 15
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: root.sink ? (root.sink.nickname || root.sink.description || root.sink.name) : "No output"
                    elide: Text.ElideRight
                    color: Kit.ink
                    font: Kit.bodyFont(11)
                    textFormat: Text.PlainText
                }
                Rectangle { x: 7; y: 35.5; width: 70; height: 1; color: Kit.dark(0.15) }
                Svg { x: 32; y: 44.4; d: "M2 7 h4 l5 -4 v14 l-5 -4 H2 z"; fill: Kit.ink; transform: Scale { xScale: 0.9045; yScale: 0.9045 } }
                Svg { x: 32; y: 44.4; d: "M14 6.5 a5 5 0 0 1 0 7 M16.5 4 a8.5 8.5 0 0 1 0 12"; stroke: Kit.ink; sw: 1.6; cap: ShapePath.RoundCap; transform: Scale { xScale: 0.9045; yScale: 0.9045 } }
                Rectangle { id: track; x: 39; y: 76.5; width: 6; height: 135.7; radius: 3; color: Kit.dark(0.20); border.width: 1; border.color: Kit.dark(0.25) }
                Rectangle {
                    id: fill
                    readonly property real fillH: track.height * Math.min(1, root.volLevel)
                    x: 39; y: track.y + track.height - fillH; width: 6; height: fillH
                    radius: 3
                    color: root.volMuted ? Kit.dark(0.35) : "#25bbcf"
                }
                Rectangle {
                    x: 33; y: fill.y - 5; width: 18; height: 10
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
                MouseArea {
                    x: 29; y: track.y - 6; width: 26; height: track.height + 12
                    enabled: !!root.sinkAudio
                    cursorShape: Qt.PointingHandCursor
                    onPressed: function (m) { root.setVolume(1 - (m.y - 6) / track.height) }
                    onPositionChanged: function (m) { if (pressed) root.setVolume(1 - (m.y - 6) / track.height) }
                }
                Text {
                    x: 7; y: 220.3; width: 70; height: 16.2
                    horizontalAlignment: Text.AlignHCenter
                    text: root.sinkAudio ? "" + Math.round(root.volLevel * 100) : "–"
                    color: Kit.ink
                    font: Kit.bodyFont(12)
                    textFormat: Text.PlainText
                }
                Rectangle {
                    x: 25; y: 244.4; width: 34; height: 23.7
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
                    Svg { x: 9; y: 4.9; d: "M1 5 h3 l4 -3 v10 l-4 -3 H1 z"; fill: Kit.ink }
                    Svg { visible: !root.volMuted; x: 9; y: 4.9; d: "M11 4.5 a3.5 3.5 0 0 1 0 5"; stroke: Kit.ink; sw: 1.4 }
                    Svg { visible: root.volMuted; x: 9; y: 4.9; d: "M10.5 4.5 l4 5 M14.5 4.5 l-4 5"; stroke: Kit.ink; sw: 1.4; cap: ShapePath.RoundCap }
                    MouseArea {
                        id: muteMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !!root.sinkAudio
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.sinkAudio.muted = !root.sinkAudio.muted
                    }
                }
                Rectangle {
                    x: 8; y: 268.2; width: 68; height: 25.8
                    color: Kit.accent(0.10)
                    Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: Kit.dark(0.15) }
                    Text {
                        id: mixerText
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 5; height: 15
                        verticalAlignment: Text.AlignVCenter
                        text: "Mixer"
                        color: Kit.ink
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                    Rectangle { visible: mixerMa.containsMouse; x: mixerText.x; y: 19; width: mixerText.width; height: 1; color: Kit.ink }
                    MouseArea {
                        id: mixerMa
                        anchors.fill: parent
                        hoverEnabled: true
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
            grabFocus: false
            readonly property int rise: 24
            implicitWidth: 440
            implicitHeight: startFly.rise + 560

            HyprlandFocusGrab {
                windows: [startFly]
                active: startFly.visible
                onCleared: {
                    root.flyoutGone = "start"
                    root.flyoutGoneAt = Date.now()
                    root.flyout = ""
                }
            }

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
                    function shutdownDialog() {
                        root.flyout = ""
                        if (root.powermenu) root.powermenu.show()
                    }

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
                        Shape {
                            x: 10; y: 10; width: 44; height: 44
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: "transparent"
                                fillGradient: LinearGradient {
                                    x1: 0; y1: 6; x2: 0; y2: 24
                                    GradientStop { position: 0; color: "#25bbcf" }
                                    GradientStop { position: 1; color: "#a99cf6" }
                                }
                                PathSvg { path: Kit.ell(22, 15, 9, 9, 0) }
                            }
                            ShapePath {
                                strokeColor: "transparent"
                                fillGradient: LinearGradient {
                                    x1: 0; y1: 25; x2: 0; y2: 42
                                    GradientStop { position: 0; color: "#25bbcf" }
                                    GradientStop { position: 1; color: "#a99cf6" }
                                }
                                PathSvg { path: "M6 42c0-11 7-17 16-17s16 6 16 17z" }
                            }
                            ShapePath {
                                strokeColor: "transparent"
                                fillColor: Kit.white(0.5)
                                PathSvg { path: Kit.ell(20, 11, 6, 3.5, 0) }
                            }
                        }
                    }

                    Plate {
                        visible: sm.powerOpen
                        x: 296; y: 514 - height; width: 132
                        height: powCol.height + 10
                        Column {
                            id: powCol
                            x: 1; y: 5; width: 130
                            PaneRow { plate: true; rh: 26; label: "Switch user"; enabled: false }
                            PaneRow { plate: true; rh: 26; label: "Log off"; onActivated: sm.power("logout") }
                            PaneRow { plate: true; rh: 26; label: "Sleep"; onActivated: sm.power("suspend") }
                            PaneRow { plate: true; rh: 26; label: "Hibernate"; onActivated: sm.power("hibernate") }
                            PaneRow { plate: true; rh: 26; label: "Restart"; onActivated: sm.power("reboot") }
                            PaneRow { plate: true; rh: 26; label: "Shut down…"; onActivated: sm.shutdownDialog() }
                        }
                    }

                    Item {
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
                                onClicked: sm.powerOpen = !sm.powerOpen
                            }
                        }
                        Rectangle { anchors.fill: parent; radius: 3; color: "transparent"; border.width: 1; border.color: Kit.white(0.35) }
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
            anchors.right: more.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
