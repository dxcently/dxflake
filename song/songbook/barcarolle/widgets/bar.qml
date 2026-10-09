import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
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
        property alias hovered: cma.containsMouse
        signal clicked()
        width: 24
        height: Kit.barHeight
        Rectangle {
            anchors.fill: parent
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: Kit.white(0.32)
            visible: cma.containsMouse
        }
        MouseArea {
            id: cma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: cell.clicked()
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
                x: 7; y: 0; width: 40; height: 40
                source: orbArt
                shadowEnabled: true
                shadowColor: Kit.withA(Kit.cyan, 0.45)
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
            visible: win.peekBtn !== null && win.peekList.length > 0
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

            Rectangle {
                id: rim
                width: 300
                height: 6 + 26 + plate.height + 6
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
                    id: plate
                    x: 6; y: 32; width: 288
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
                                        win.hotId = -1
                                        win.hotBtn = null
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

        Item {
            id: clock
            anchors { right: sliver.left; top: parent.top; bottom: parent.bottom }
            width: 76
            Rectangle {
                anchors.fill: parent
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: Kit.white(0.32)
                visible: clockMa.containsMouse
            }
            Column {
                anchors.centerIn: parent
                ShadowText { width: 76; horizontalAlignment: Text.AlignHCenter; text: Qt.formatTime(root.now, "h:mm AP"); font: Kit.bodyFont(12) }
                ShadowText { width: 76; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(root.now, "M/d/yyyy"); font: Kit.bodyFont(12) }
            }
            MouseArea { id: clockMa; anchors.fill: parent; hoverEnabled: true }
        }

        Cell {
            id: vol
            anchors { right: clock.left; rightMargin: 4 }
            Svg { x: 3; y: 12; d: "M1.5 5.5 h3 l4 -3 v11 l-4 -3 h-3 z"; fill: "#ffffff" }
            Svg { x: 3; y: 12; d: "M11 5 a4 4 0 0 1 0 6 M13.2 3 a7 7 0 0 1 0 10"; stroke: "#ffffff"; sw: 1.3; cap: ShapePath.RoundCap }
        }
        Cell {
            id: net
            anchors.right: vol.left
            Svg { x: 3; y: 12; d: "M3.5 1.5 H14.5 a1 1 0 0 1 1 1 V9.5 a1 1 0 0 1 -1 1 H3.5 a1 1 0 0 1 -1 -1 V2.5 a1 1 0 0 1 1 -1 Z"; stroke: "#ffffff"; fill: Kit.dark(1) }
            Svg { x: 3; y: 12; d: "M4 3 H14 V9 H4 Z"; fill: Kit.withA("#2aa3b8", 0.8) }
            Svg { x: 3; y: 12; d: "M9 10.5 v2.5 M5 14.5 h8"; stroke: "#ffffff"; sw: 1.4 }
        }
        Cell {
            id: flag
            anchors.right: net.left
            Svg { x: 4; y: 12; d: "M3 1.5 v13.5"; stroke: "#ffffff"; sw: 1.5 }
            Svg { x: 4; y: 12; d: "M3.5 2.5 c3 -1.5 5 1.5 9.5 0 v7 c-4.5 1.5 -6.5 -1.5 -9.5 0 z"; fill: Kit.white(0.9) }
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

        WidgetSlot {
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
