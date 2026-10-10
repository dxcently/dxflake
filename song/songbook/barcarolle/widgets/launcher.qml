import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Kit.js" as Kit
import "Emoji.js" as Emoji
import "Kaomoji.js" as Kaomoji

PanelWindow {
    id: root

    required property var livery
    required property var bridge
    required property var clipboard
    required property var ledger

    readonly property string aoideRoot: Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")
    readonly property string g3Dir: "file://" + root.aoideRoot + "/song/songbook/barcarolle/icons/launcher/"
    readonly property string bust: "?v=" + Date.now()
    readonly property string fSys: Qt.fontFamilies().indexOf("Tahoma") >= 0 ? "Tahoma" : Kit.family
    readonly property string fSmall: Qt.fontFamilies().indexOf("Verdana") >= 0 ? "Verdana" : Kit.family
    readonly property string fKao: "Noto Sans CJK JP"
    readonly property int bleed: 12

    readonly property var pl: ({
        face: "#dddddd", hi: "#ffffff", sh: "#8a8a8a", line: "#1d1d1d", hdr: "#ececec", track: "#c9c9c9",
        sel: "#0f6d80", selLine: "#0a4a58", thumbA: "#c3f0f4", thumbB: "#8fd9e3", thumbLine: "#1d4f5a"
    })
    readonly property var geoms: ({
        top: { cw: 70, ch: 58, cols: 4 },
        apps: { cw: 66, ch: 60, cols: 4 },
        clip: { cw: 88, ch: 60, cols: 3 },
        emoji: { cw: 33, ch: 33, cols: 8 },
        kaomoji: { cw: 264, ch: 20, cols: 1 },
        search: { cw: 66, ch: 60, cols: 4 },
        sub: { cw: 66, ch: 60, cols: 4 }
    })
    readonly property var folders: [
        { kind: "folder", key: "apps", name: "Applications", icon: root.g3Dir + "finder-folder-apps.svg" + root.bust },
        { kind: "folder", key: "clip", name: "Clipboard", icon: root.g3Dir + "finder-folder-clipboard.svg" + root.bust },
        { kind: "folder", key: "emoji", name: "Emoji", icon: root.g3Dir + "finder-folder-emoji.svg" + root.bust },
        { kind: "folder", key: "kaomoji", name: "Kaomoji", icon: root.g3Dir + "finder-folder-kaomoji.svg" + root.bust }
    ]
    readonly property var subs: ({ emoji: root.folderItems(Emoji.folders), kaomoji: root.folderItems(Kaomoji.folders) })
    function folderItems(list) {
        return list.map(function (f) {
            return { kind: "folder", key: f.key, name: f.name, emblem: f.emblem, icon: root.g3Dir + "finder-folder.svg" + root.bust }
        })
    }
    function keyIndex(list, key) {
        for (var i = 0; i < list.length; i++) if (list[i].key === key) return i
        return -1
    }

    // ── window: the front drawing plus a bleed for the pop-in overshoot, centred by the compositor ──
    property var targetScreen: null
    readonly property string focusName: {
        var mon = Hyprland.focusedMonitor
        return mon ? mon.name : ""
    }
    function focusedScreen() {
        for (var i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === root.focusName) return Quickshell.screens[i]
        return null
    }

    screen: root.targetScreen
    implicitWidth: 504 + 2 * root.bleed
    implicitHeight: 456 + 2 * root.bleed
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: root.shown || gs.g3o > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "aoide-launcher"
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: hit }
    Item { id: hit; x: root.bleed; y: root.bleed; width: 504; height: 456 }

    GlobalShortcut {
        appid: "aoide"
        name: "launcher"
        description: "Summon the Aoide app launcher"
        onPressed: root.toggle()
    }
    GlobalShortcut {
        appid: "aoide"
        name: "clipboard"
        description: "Open clipboard history in the Grimoire"
        onPressed: root.openClipboard()
    }
    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: root.hide()
    }
    Shortcut { sequence: "Escape"; enabled: root.shown; onActivated: root.hide() }

    // ── the G3 timeline ──
    property bool shown: false
    property real t: 0
    property var tracks: []
    property var from: ({})
    readonly property var names: ["g3o", "g3s", "lo", "bo", "bx", "so", "sy", "br", "no", "co"]
    readonly property var openTracks: [
        ["g3o", 0, 0, 60, 1, "lin"], ["g3s", 0, 0.12, 170, 1.04, "outCubic"], ["g3s", 170, 1.04, 230, 1, "inOutQuad"],
        ["lo", 180, 0, 180, 1, "step"], ["lo", 205, 1, 205, 0.25, "step"], ["lo", 230, 0.25, 230, 1, "step"],
        ["bo", 200, 0, 230, 1, "outQuad"], ["bx", 200, 0.1, 250, 1, "outCubic"],
        ["so", 250, 0, 250, 1, "step"], ["no", 250, 0, 250, 1, "step"], ["sy", 250, 0.02, 330, 1, "outCubic"],
        ["bo", 250, 1, 300, 0, "lin"],
        ["br", 250, 0.6, 330, 0.25, "lin"], ["br", 330, 0.25, 460, 0, "outQuad"],
        ["no", 340, 1, 420, 0, "lin"], ["co", 340, 0, 440, 1, "outQuad"]]
    readonly property var closeTracks: [
        ["co", 0, 1, 70, 0, "inQuad"],
        ["br", 40, 0, 80, 0.5, "lin"], ["sy", 60, 1, 140, 0.02, "inCubic"],
        ["so", 140, 1, 140, 0, "step"], ["bo", 140, 0, 140, 1, "step"], ["bx", 140, 1, 190, 0.03, "inCubic"],
        ["bo", 190, 1, 230, 0, "lin"], ["lo", 190, 1, 190, 0, "step"],
        ["g3s", 200, 1, 320, 0.12, "inCubic"], ["g3o", 260, 1, 320, 0, "lin"]]

    QtObject {
        id: gs
        property real g3o: 0
        property real g3s: 0.12
        property real lo: 0
        property real bo: 0
        property real bx: 0.1
        property real so: 0
        property real sy: 0.02
        property real br: 0
        property real no: 0
        property real co: 0
    }

    function ease(n, k) {
        switch (n) {
        case "step": return 1
        case "outCubic": return 1 - Math.pow(1 - k, 3)
        case "inCubic": return k * k * k
        case "outQuad": return 1 - (1 - k) * (1 - k)
        case "inQuad": return k * k
        case "inOutQuad": return k < 0.5 ? 2 * k * k : 1 - Math.pow(-2 * k + 2, 2) / 2
        default: return k
        }
    }
    function apply() {
        var o = {}
        for (var n = 0; n < names.length; n++) o[names[n]] = from[names[n]]
        for (var i = 0; i < tracks.length; i++) {
            var q = tracks[i]
            if (t < q[1]) continue
            var k = q[3] > q[1] ? Math.min(1, (t - q[1]) / (q[3] - q[1])) : 1
            o[q[0]] = q[2] + (q[4] - q[2]) * ease(q[5], k)
        }
        for (var m = 0; m < names.length; m++) gs[names[m]] = o[names[m]]
    }
    onTChanged: apply()

    NumberAnimation { id: g3clock; target: root; property: "t"; from: 0; to: 460; duration: 460 }

    function toggle() {
        g3clock.stop()
        var f = {}
        for (var n = 0; n < names.length; n++) f[names[n]] = gs[names[n]]
        from = f
        var opening = !root.shown
        if (opening) {
            root.targetScreen = root.focusedScreen()
            root.resetState()
        }
        root.shown = opening
        var src = opening ? openTracks : closeTracks
        var seen = {}, tr = []
        for (var i = 0; i < src.length; i++) {
            var q = src[i].slice()
            if (!seen[q[0]]) {
                seen[q[0]] = true
                if (q[5] !== "step" && !(opening && q[0] === "br")) q[2] = f[q[0]]
            }
            tr.push(q)
        }
        tracks = tr
        var total = opening ? 460 : 320
        g3clock.to = total
        g3clock.duration = total
        t = 0
        apply()
        if (opening) Qt.callLater(function () { findField.forceActiveFocus() })
        g3clock.start()
    }
    function show() { if (!root.shown) root.toggle() }
    function hide() { if (root.shown) root.toggle() }
    function openClipboard() {
        root.show()
        root.openFolder("clip")
    }

    // ── the Finder: state ──
    property string view: "top"
    property string sub: ""
    property string query: ""
    property int dataTick: 0

    readonly property bool searching: root.view === "top" && root.query.trim() !== ""
    readonly property bool frontOpen: root.view !== "top" || root.searching
    readonly property bool inSub: root.sub !== ""
    readonly property bool showFolders: !!root.subs[root.view] && !root.inSub && root.query.trim() === ""
    readonly property var geom: root.geoms[root.searching ? "search" : root.showFolders ? "sub" : root.view]
    readonly property var items: root.compute(root.view, root.sub, root.query, root.dataTick)
    readonly property Item grid: root.frontOpen ? frontGrid : topGrid
    readonly property string hdrText: {
        if (root.view === "clip" && root.clipboard.loading) return "Reading clipboard…"
        var n = root.items.length
        return n === 0 ? "0 items" : root.fmt(n) + (n === 1 ? " item" : " items") + ", 1 selected"
    }
    readonly property string emptyText: {
        if (root.view === "clip" && root.query.trim() === "")
            return root.clipboard.loading ? "" : (root.clipboard.loadError ? "Clipboard history unavailable" : "No clippings yet")
        return "No items match “" + root.query.trim() + "”"
    }
    readonly property var curFolder: root.folders[root.keyIndex(root.folders, root.view)]
    readonly property var curSub: root.inSub && root.subs[root.view] ? root.subs[root.view][root.keyIndex(root.subs[root.view], root.sub)] : undefined
    readonly property string frontTitle: {
        if (root.searching) return "Find “" + root.query.trim() + "”"
        if (root.curSub) return root.curSub.name
        return root.curFolder ? root.curFolder.name : ""
    }
    readonly property string frontProxy: {
        if (root.curSub) return root.curSub.icon
        return root.curFolder ? root.curFolder.icon : ""
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.dataTick++ }
    }

    FontMetrics {
        id: lm
        font.family: root.fSmall
        font.pixelSize: 10
        font.hintingPreference: Font.PreferFullHinting
    }
    function fits(text, w) {
        var n = text.length
        while (n > 1 && lm.advanceWidth(text.substring(0, n)) > w) n--
        return n
    }
    function clamp2(text, w) {
        var rest = ("" + text).replace(/\s+/g, " ").trim(), out = []
        for (var ln = 0; ln < 2 && rest.length > 0; ln++) {
            var n = root.fits(rest, w)
            if (n >= rest.length) { out.push(rest); rest = ""; break }
            var cut = n
            for (var i = n; i > 0; i--) {
                if (rest.charAt(i) === " " || (rest.charAt(i - 1) === "-" && /[A-Za-z]/.test(rest.charAt(i)))) { cut = i; break }
            }
            out.push(rest.substring(0, cut).replace(/\s+$/, ""))
            rest = rest.substring(cut).replace(/^\s+/, "")
        }
        if (rest.length > 0) {
            var last = out.pop()
            while (last.length > 0 && lm.advanceWidth(last + "\u2026") > w) last = last.substring(0, last.length - 1)
            out.push(last.replace(/\s+$/, "") + "\u2026")
        }
        return { text: out.join("\n"), lines: out.length, cut: rest.length > 0 }
    }

    function fmt(n) { return ("" + n).replace(/\B(?=(\d{3})+(?!\d))/g, ",") }

    function tierOf(q, name, extra) {
        var n = ("" + name).toLowerCase()
        if (n.indexOf(q) === 0) return 0
        if ((" " + n).indexOf(" " + q) >= 0) return 1
        if (n.indexOf(q) >= 0) return 2
        return extra && ("" + extra).toLowerCase().indexOf(q) >= 0 ? 3 : -1
    }
    function rank(q, list, nameOf, extraOf) {
        var tiers = [[], [], [], []]
        for (var i = 0; i < list.length; i++) {
            var t = root.tierOf(q, nameOf(list[i]), extraOf ? extraOf(list[i]) : "")
            if (t >= 0) tiers[t].push(list[i])
        }
        return tiers[0].concat(tiers[1], tiers[2], tiers[3])
    }
    function appItems(q) {
        var all = DesktopEntries.applications.values, list = []
        for (var i = 0; i < all.length; i++) if (!all[i].noDisplay) list.push(all[i])
        list.sort(function (a, b) {
            var x = ("" + a.name).toLowerCase(), y = ("" + b.name).toLowerCase()
            return x < y ? -1 : (x > y ? 1 : 0)
        })
        if (q) list = root.rank(q, list, function (e) { return e.name }, function (e) { return e.genericName })
        return list.map(function (e) { return { kind: "app", name: "" + e.name, entry: e } })
    }
    function clipItems(q) {
        var list = root.clipboard.parsedEntries || []
        if (q) list = root.rank(q, list, function (c) { return c.preview })
        return list.map(function (c) {
            return { kind: "clip", clip: c, full: c.preview,
                     name: c.kind === "image" ? ("" + c.format).toUpperCase() + " " + c.width + "×" + c.height : c.preview }
        })
    }
    function glyphItems(list, q) {
        return q ? root.rank(q, list, function (e) { return e.name }, function (e) { return e.words }) : list
    }
    function glyphsIn(list, sub) {
        return sub ? list.filter(function (e) { return e.group === sub }) : list
    }
    function compute(view, sub, query, tick) {
        var q = ("" + query).trim().toLowerCase()
        if (view === "top")
            return q === "" ? root.folders : root.appItems(q).concat(root.clipItems(q), root.glyphItems(Emoji.all(), q), root.glyphItems(Kaomoji.all(), q))
        if (view === "apps") return root.appItems(q)
        if (view === "clip") return root.clipItems(q)
        if (q === "" && sub === "") return root.subs[view]
        return root.glyphItems(root.glyphsIn(view === "emoji" ? Emoji.all() : Kaomoji.all(), sub), q)
    }

    function resetState() {
        findField.text = ""
        root.sub = ""
        root.view = "top"
        topGrid.currentIndex = 0
        topGrid.positionViewAtBeginning()
        root.clipboard.refresh()
    }
    function openFolder(key) {
        findField.text = ""
        root.sub = ""
        root.view = key
        if (key === "clip") root.clipboard.refresh()
    }
    function openSub(key) {
        findField.text = ""
        root.sub = key
    }
    function goTop() {
        var at = root.keyIndex(root.folders, root.view)
        findField.text = ""
        root.sub = ""
        root.view = "top"
        if (at >= 0) topGrid.currentIndex = at
    }
    function goUp() {
        if (root.searching) { findField.text = ""; return }
        if (!root.inSub) { root.goTop(); return }
        var at = root.keyIndex(root.subs[root.view], root.sub)
        findField.text = ""
        root.sub = ""
        frontGrid.currentIndex = at
        root.reveal(frontGrid, at)
    }
    function nav(dx, dy) {
        var g = root.grid, n = g.count
        if (n === 0) return
        if (!root.frontOpen && dy !== 0) return
        var i = g.currentIndex
        var j = dx !== 0 ? i + dx : i + dy * root.geom.cols
        if (dy < 0 && j < 0) j = i
        j = Math.max(0, Math.min(n - 1, j))
        g.currentIndex = j
        root.reveal(g, j)
    }
    function reveal(g, i) {
        var rowY = Math.floor(i / root.geom.cols) * root.geom.ch
        var s = g.contentY - g.originY
        if (rowY < s) s = rowY
        if (rowY + root.geom.ch + 8 > s + g.height) s = rowY + root.geom.ch + 8 - g.height
        g.contentY = g.originY + Math.max(0, Math.min(s, g.contentHeight - g.height))
    }
    function activate(it) {
        if (!it) return
        if (it.kind === "folder") { if (root.view === "top") root.openFolder(it.key); else root.openSub(it.key) }
        else if (it.kind === "app") {
            if (!it.entry.command || it.entry.command.length === 0) return
            Quickshell.execDetached(Kit.scopeArgv(it.entry))
            root.ledger.record(it.entry.id)
            root.hide()
        } else if (it.kind === "clip") {
            if (root.clipboard.copyById(it.clip.id)) root.hide()
        } else if (it.kind === "emoji" || it.kind === "kaomoji") {
            Quickshell.execDetached(["wl-copy", "--", it.glyph])
            root.hide()
        }
    }
    function pressed(e) {
        switch (e.key) {
        case Qt.Key_Left: root.nav(-1, 0); e.accepted = true; break
        case Qt.Key_Right: root.nav(1, 0); e.accepted = true; break
        case Qt.Key_Up: root.nav(0, -1); e.accepted = true; break
        case Qt.Key_Down: root.nav(0, 1); e.accepted = true; break
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.activate(root.items[root.grid.currentIndex])
            e.accepted = true
            break
        case Qt.Key_Backspace:
            if (findField.text === "") {
                if (!e.isAutoRepeat) root.goUp()
                e.accepted = true
            }
            break
        }
    }

    // ── cover for the little desktop ──
    property string coverPath: Quickshell.env("AOIDE_WALLPAPER") || ""
    FileView {
        path: root.aoideRoot + "/song/stage/cover.json"
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

    property string hostName: ""
    readonly property string diskName: root.hostName || "Computer"
    FileView {
        path: "/etc/hostname"
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.hostName = text().trim()
    }

    component Svg: Shape {
        id: sv
        property string d: ""
        property color stroke: "transparent"
        property real sw: 1
        property color fill: "transparent"
        property int cap: ShapePath.FlatCap
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: sv.stroke
            strokeWidth: sv.sw
            fillColor: sv.fill
            capStyle: sv.cap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: sv.d }
        }
    }

    component T: Text {
        renderType: Text.NativeRendering
        textFormat: Text.PlainText
        color: "#000000"
        font.family: root.fSmall
        font.pixelSize: 10
        font.hintingPreference: Font.PreferFullHinting
    }

    component Emblem: Text {
        id: em
        property bool emoji: root.view === "emoji"
        property real dy: 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(20.5 - em.height / 2) + em.dy
        renderType: Text.NativeRendering
        textFormat: Text.PlainText
        font.family: em.emoji ? "Noto Color Emoji" : root.fKao
        font.weight: Font.Medium
        font.pixelSize: em.emoji ? 13 : 10
    }

    component Lens: Item {
        width: 10
        height: 10
        Svg { d: Kit.ell(4, 4, 3, 3, 0); stroke: "#3a3a3a"; sw: 1.3 }
        Svg { d: "M6.2 6.2 L9 9"; stroke: "#3a3a3a"; sw: 1.6; cap: ShapePath.RoundCap }
    }

    component Bevel: Item {
        id: bv
        property color face: root.pl.face
        property bool pressed: false
        Rectangle { anchors.fill: parent; color: bv.face }
        Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: "#9a9a9a" }
        Rectangle { x: parent.width - 1; width: 1; height: parent.height; color: "#9a9a9a" }
        Rectangle { width: parent.width; height: 1; color: root.pl.hi }
        Rectangle { width: 1; height: parent.height; color: root.pl.hi }
    }

    component Box: Item {
        id: bx
        property int kind: 0
        signal clicked()
        width: 11
        height: 11
        Rectangle { anchors.fill: parent; color: root.pl.face; border.width: 1; border.color: root.pl.line }
        Rectangle { x: 1; y: 1; width: 9; height: 1; color: root.pl.hi }
        Rectangle { x: 1; y: 1; width: 1; height: 9; color: root.pl.hi }
        Rectangle { x: 2; y: 9; width: 8; height: 1; color: "#9a9a9a" }
        Rectangle { x: 9; y: 2; width: 1; height: 8; color: "#9a9a9a" }
        Rectangle { visible: bx.kind === 1; x: 2; y: 2; width: 7; height: 7; color: "transparent"; border.width: 1; border.color: root.pl.line }
        Rectangle { visible: bx.kind === 2; x: 2; y: 4; width: 7; height: 1; color: root.pl.line }
        Rectangle { visible: bx.kind === 2; x: 2; y: 6; width: 7; height: 1; color: root.pl.line }
        MouseArea { anchors.fill: parent; enabled: bx.visible; onClicked: bx.clicked() }
    }

    component Stripes: Item {
        height: 10
        Repeater {
            model: 10
            Rectangle {
                required property int index
                y: index
                width: parent.width
                height: 1
                color: index % 2 === 0 ? root.pl.hi : root.pl.sh
            }
        }
    }

    component Tri: Item {
        id: tr
        property bool up: true
        property color tone: root.pl.line
        width: 8
        height: 5
        Svg { d: tr.up ? "M0 5 L4 1 L8 5 z" : "M0 0 L4 4 L8 0 z"; fill: tr.tone }
    }

    component Sb: Item {
        id: sb
        property Item view: null
        property bool active: true
        readonly property real colH: height
        readonly property real total: sb.view ? sb.view.contentHeight : 0
        readonly property bool overflow: !!sb.view && sb.total > sb.view.height
        readonly property real trackH: sb.colH - 14 - 14 - 15
        readonly property real thumbH: sb.overflow ? Math.max(16, Math.round(sb.trackH * sb.view.height / sb.total)) : 0
        readonly property real thumbY: sb.overflow ? 15 + Math.round((sb.trackH - sb.thumbH) * Math.max(0, Math.min(1, (sb.view.contentY - sb.view.originY) / (sb.total - sb.view.height)))) : 15
        width: 15

        Rectangle { x: 0; y: 0; width: 15; height: parent.height; color: root.pl.track }
        Rectangle { x: 0; y: 0; width: 1; height: parent.height; color: root.pl.line }
        Rectangle { x: 1; y: 0; width: 14; height: 1; color: "#a5a5a5" }
        Rectangle { x: 1; y: 0; width: 1; height: parent.height; color: "#a5a5a5" }

        Item {
            visible: sb.active
            x: 1; y: 0; width: 14; height: 14
            Bevel { anchors.fill: parent }
            Rectangle { y: 13; width: 14; height: 1; color: root.pl.line }
            Tri { x: 3; y: 4; up: true; tone: sb.overflow ? root.pl.line : "#9a9a9a" }
        }
        Item {
            visible: sb.active
            x: 1; y: sb.colH - 28; width: 14; height: 14
            Bevel { anchors.fill: parent }
            Rectangle { y: 0; width: 14; height: 1; color: root.pl.line }
            Tri { x: 3; y: 4; up: false; tone: sb.overflow ? root.pl.line : "#9a9a9a" }
        }
        Item {
            x: 1; y: sb.colH - 14; width: 14; height: 14
            Rectangle { anchors.fill: parent; color: root.pl.face }
            Rectangle { y: 0; width: 14; height: 1; color: root.pl.line }
            Rectangle { y: 1; width: 14; height: 1; color: root.pl.hi }
            Rectangle { x: 0; y: 1; width: 1; height: 13; color: root.pl.hi }
            Repeater {
                model: [[10, 5], [9, 6], [8, 7], [7, 8], [6, 9], [5, 10], [4, 11], [10, 8], [9, 9], [8, 10], [7, 11], [10, 11]]
                Rectangle { required property var modelData; x: modelData[0]; y: modelData[1]; width: 1; height: 1; color: "#7a7a7a" }
            }
            Repeater {
                model: [[10, 6], [9, 7], [8, 8], [7, 9], [6, 10], [5, 11], [10, 9], [9, 10], [8, 11]]
                Rectangle { required property var modelData; x: modelData[0]; y: modelData[1]; width: 1; height: 1; color: "#ffffff" }
            }
        }
        Item {
            visible: sb.active && sb.overflow
            x: 1; y: sb.thumbY; width: 14; height: sb.thumbH
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: root.pl.thumbA }
                    GradientStop { position: 1; color: root.pl.thumbB }
                }
            }
            Rectangle { y: 0; width: 14; height: 1; color: root.pl.thumbLine }
            Rectangle { y: parent.height - 1; width: 14; height: 1; color: root.pl.thumbLine }
            Rectangle { x: 0; y: 1; width: 1; height: parent.height - 2; color: "#effcfd" }
            Rectangle { x: 0; y: 1; width: 13; height: 1; color: "#effcfd" }
            Rectangle { x: 13; y: 1; width: 1; height: parent.height - 2; color: "#4fa7b5" }
            Rectangle { x: 1; y: parent.height - 2; width: 13; height: 1; color: "#4fa7b5" }
            Repeater {
                model: 7
                Rectangle {
                    required property int index
                    x: 3
                    y: Math.round(parent.height / 2) - 4 + index
                    width: 8
                    height: 1
                    color: index % 2 === 0 ? "#effcfd" : "#3f8f9f"
                }
            }
        }
    }

    component Win: Item {
        id: w
        property string title: ""
        property url proxy: ""
        property bool lens: false
        property string hdr: ""
        property bool active: true
        property Item view: null
        default property alias body: bodyArea.data
        signal closeClicked()
        signal bodyClicked()

        Rectangle { x: 2; y: 2; width: w.width; height: w.height; color: Qt.rgba(12 / 255, 33 / 255, 48 / 255, 0.2) }
        Rectangle { x: 1; y: 1; width: w.width; height: w.height; color: Qt.rgba(12 / 255, 33 / 255, 48 / 255, 0.55) }
        Rectangle { anchors.fill: parent; color: root.pl.face; border.width: 1; border.color: root.pl.line }

        Item {
            id: inner
            x: 1; y: 1; width: w.width - 2; height: w.height - 2

            Item {
                id: tb
                width: inner.width
                height: 18
                readonly property real tw: 5 + 14 + 4 + ttl.implicitWidth + 5
                readonly property real sw: Math.max(0, (inner.width - 56 - tb.tw) / 2)
                Rectangle { y: 17; width: parent.width; height: 1; color: root.pl.line }
                Rectangle { width: parent.width; height: 1; color: root.pl.hi }
                Rectangle { width: 1; height: 17; color: root.pl.hi }
                Rectangle { x: parent.width - 1; y: 1; width: 1; height: 16; color: "#b5b5b5" }

                Box { x: 4; y: 3; visible: w.active; onClicked: w.closeClicked() }
                Stripes { x: 18; y: 3; width: tb.sw; visible: w.active }
                Item {
                    x: 18 + tb.sw + 3
                    y: 0
                    width: tb.tw
                    height: 17
                    Image {
                        visible: !w.lens
                        x: 6; y: 2; width: 14; height: 14
                        source: w.proxy
                        sourceSize: Qt.size(14, 14)
                        opacity: w.active ? 1 : 0.45
                    }
                    Lens { visible: w.lens; x: 6; y: 2; transform: Scale { xScale: 1.4; yScale: 1.4 } }
                    T {
                        id: ttl
                        x: 23
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -1
                        text: w.title
                        color: w.active ? "#000000" : "#8a8a8a"
                        font.family: root.fSys
                        font.pixelSize: 12
                    }
                }
                Stripes { x: 18 + tb.sw + 3 + tb.tw + 3; y: 3; width: tb.sw; visible: w.active }
                Box { x: 18 + tb.sw * 2 + 3 + tb.tw + 3 + 3; y: 3; kind: 1; visible: w.active }
                Box { x: 18 + tb.sw * 2 + 3 + tb.tw + 3 + 3 + 14; y: 3; kind: 2; visible: w.active }
            }

            Rectangle {
                y: 18
                width: inner.width
                height: 15
                color: root.pl.hdr
                Rectangle { width: parent.width; height: 1; color: root.pl.hi }
                Rectangle { y: 14; width: parent.width; height: 1; color: root.pl.sh }
                T {
                    width: parent.width
                    height: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: w.hdr
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                id: bodyArea
                x: 0; y: 34
                width: inner.width - 15
                height: inner.height - 34
                color: "#ffffff"
                clip: true
                MouseArea { anchors.fill: parent; onClicked: w.bodyClicked() }
            }

            Sb { x: inner.width - 15; y: 34; height: inner.height - 34; view: w.view; active: w.active }
        }
    }

    component Cell: Item {
        id: cell
        required property var modelData
        required property int index
        readonly property bool sel: GridView.isCurrentItem
        readonly property string kind: modelData.kind
        readonly property string emblem: modelData.emblem || ""
        readonly property bool glyphOnly: kind === "emoji" && !root.searching
        readonly property bool bigGlyph: kind === "emoji" && root.searching
        readonly property bool row: kind === "kaomoji" && !root.searching
        readonly property bool kaoLabel: kind === "kaomoji" && root.searching
        readonly property var fold: (cell.glyphOnly || cell.row) ? ({ text: "", lines: 0, cut: false })
            : cell.kaoLabel ? ({ text: cell.modelData.glyph, lines: 1, cut: false }) : root.clamp2(cell.modelData.name, cell.width - 8)
        readonly property bool truncated: cell.kaoLabel ? lbl.truncated : cell.fold.cut
        readonly property real anchorX: cell.row ? 6 + Math.min(kt.implicitWidth, 158) / 2 : cell.width / 2
        readonly property string iconUrl: {
            if (kind === "folder") return modelData.icon
            if (kind === "kaomoji") return root.g3Dir + "finder-clip-text.svg" + root.bust
            if (kind === "clip") return root.g3Dir + (modelData.clip.kind === "image" ? "finder-clip-picture.svg" : "finder-clip-text.svg") + root.bust
            if (kind !== "app") return ""
            var p = Quickshell.iconPath(modelData.entry.icon, true)
            return p ? (p.indexOf("/") === 0 ? "file://" + p : p) : root.g3Dir + "finder-app.svg" + root.bust
        }
        readonly property string thumb: {
            if (kind !== "clip" || modelData.clip.kind !== "image") return ""
            var st = root.clipboard.imageStates[modelData.clip.id]
            return st && st.state === "ready" ? st.source : ""
        }
        readonly property real labelY: cell.bigGlyph ? 41 : 37

        width: GridView.view ? GridView.view.cellWidth : 66
        height: GridView.view ? GridView.view.cellHeight : 60

        Component.onCompleted: {
            if (modelData.kind === "clip" && modelData.clip.kind === "image") root.clipboard.requestPreview(modelData.clip.id)
        }

        Rectangle {
            visible: cell.glyphOnly || cell.bigGlyph
            x: Math.ceil((cell.width - width) / 2)
            y: cell.glyphOnly ? 2 : 7
            width: cell.glyphOnly ? 30 : 34
            height: cell.glyphOnly ? 30 : 32
            radius: 4
            color: cell.sel ? root.pl.sel : "transparent"
            border.width: cell.sel ? 1 : 0
            border.color: root.pl.selLine
            Text {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: cell.kind === "emoji" ? cell.modelData.glyph : ""
                textFormat: Text.PlainText
                font.family: "Noto Color Emoji"
                font.pixelSize: cell.glyphOnly ? 26 : 31
            }
        }

        Item {
            id: ic
            visible: !cell.glyphOnly && !cell.bigGlyph && !cell.row
            x: (cell.width - 32) / 2
            y: 3
            width: 32
            height: 32
            layer.enabled: cell.sel
            layer.effect: MultiEffect {
                colorization: 0.45
                colorizationColor: "#1ed9ff"
                brightness: -0.08
            }
            Image {
                anchors.fill: parent
                source: cell.iconUrl
                sourceSize: Qt.size(32, 32)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }
            Image {
                visible: cell.thumb !== ""
                x: 9; y: 11; width: 14; height: 11
                source: cell.thumb
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                clip: true
            }
        }
        Item {
            visible: cell.emblem !== ""
            x: (cell.width - 32) / 2
            y: 3
            width: 32
            height: 32
            Emblem { visible: !emoji; text: cell.emblem; color: "#f1eeff"; dy: 1 }
            Emblem { visible: !emoji; text: cell.emblem; color: "#5b50c4" }
            Emblem { visible: emoji; text: cell.emblem }
        }

        Rectangle {
            visible: lbl.visible && cell.sel
            width: (cell.fold.lines > 1 || cell.truncated) ? cell.width - 4 : Math.ceil(lbl.contentWidth) + 4
            x: Math.round((cell.width - width) / 2)
            y: cell.kaoLabel ? cell.labelY - 1 : cell.labelY
            height: cell.kaoLabel ? 15 : cell.fold.lines * 11
            color: root.pl.sel
        }
        T {
            id: lbl
            visible: !cell.glyphOnly && !cell.row
            x: 4
            y: cell.labelY - 1
            width: cell.width - 8
            height: cell.kaoLabel ? 15 : implicitHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: cell.kaoLabel ? Text.AlignVCenter : Text.AlignTop
            text: cell.fold.text
            color: cell.sel ? "#ffffff" : "#000000"
            font.family: cell.kaoLabel ? root.fKao : root.fSmall
            font.weight: cell.kaoLabel ? Font.Medium : Font.Normal
            font.pixelSize: cell.kaoLabel ? 12 : 10
            elide: cell.kaoLabel ? Text.ElideRight : Text.ElideNone
            lineHeight: cell.kaoLabel ? 1 : 11
            lineHeightMode: cell.kaoLabel ? Text.ProportionalHeight : Text.FixedHeight
        }

        Rectangle {
            visible: cell.row && cell.sel
            x: 0; y: 1
            width: cell.width
            height: cell.height - 2
            color: root.pl.sel
        }
        T {
            id: kt
            visible: cell.row
            x: 6
            width: 158
            height: cell.height
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: cell.row ? cell.modelData.glyph : ""
            color: cell.sel ? "#ffffff" : "#000000"
            font.family: root.fKao
            font.weight: Font.Medium
            font.pixelSize: 12
        }
        T {
            visible: cell.row
            x: 170
            width: cell.width - 176
            height: cell.height
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: cell.row ? cell.modelData.name : ""
            color: cell.sel ? "#bfe4ea" : "#7a7a7a"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: cell.GridView.view.currentIndex = cell.index
            onDoubleClicked: root.activate(cell.modelData)
        }
    }

    // ── the G3 ──
    Item {
        id: g3box
        x: root.bleed
        y: root.bleed - 24
        width: 760
        height: 480
        opacity: gs.g3o
        transform: Scale { origin.x: 252; origin.y: 252; xScale: gs.g3s; yScale: gs.g3s }
        MouseArea { anchors.fill: parent }

        Image { source: root.g3Dir + "g3-body.svg" + root.bust; sourceSize: Qt.size(760, 480) }

        Image { id: g3scr; visible: false; source: root.g3Dir + "g3-screen.svg" + root.bust; sourceSize: Qt.size(760, 480) }
        MultiEffect {
            source: g3scr
            width: 760; height: 480
            opacity: gs.so
            brightness: gs.br
            transform: Scale { origin.x: 252; origin.y: 214; yScale: gs.sy }
        }
        Image { id: g3face; visible: false; source: root.g3Dir + "g3-face.svg" + root.bust; sourceSize: Qt.size(760, 480) }
        MultiEffect {
            source: g3face
            width: 760; height: 480
            opacity: gs.no * gs.so
            brightness: gs.br
            transform: Scale { origin.x: 252; origin.y: 214; yScale: gs.sy }
        }

        Item {
            x: 43; y: 55; width: 418; height: 318
            opacity: gs.co
            enabled: gs.co > 0.5

            Item {
                id: g3content
                anchors.fill: parent
                layer.enabled: true
                opacity: 0.01

                Item {
                    id: mac
                    anchors.fill: parent

                    Image {
                        anchors.fill: parent
                        visible: root.coverPath === ""
                        source: root.g3Dir + "finder-dither.svg" + root.bust
                        fillMode: Image.Tile
                        sourceSize: Qt.size(2, 2)
                    }
                    Image {
                        anchors.fill: parent
                        visible: root.coverPath !== ""
                        source: root.coverPath !== "" ? "file://" + root.coverPath : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        mipmap: true
                        smooth: true
                    }

                    Item {
                        anchors.right: parent.right; anchors.rightMargin: 4; y: 26; width: 72; height: 48
                        Image { x: 20; y: 0; width: 32; height: 32; source: root.g3Dir + "finder-disk.svg" + root.bust; sourceSize: Qt.size(32, 32) }
                        readonly property int lw: Math.ceil(dname.implicitWidth) + 4
                        Rectangle { x: Math.round((72 - parent.lw) / 2); y: 36; width: parent.lw; height: 11; color: "#ffffff" }
                        T { id: dname; x: Math.round((72 - parent.lw) / 2) + 2; y: 35; text: root.diskName; lineHeight: 11; lineHeightMode: Text.FixedHeight }
                        MouseArea { x: 14; width: 44; height: 46; onClicked: root.goTop() }
                    }
                    Item {
                        anchors.right: parent.right; anchors.rightMargin: 4; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; width: 72; height: 48
                        Image { x: 20; y: 0; width: 32; height: 32; source: root.g3Dir + "finder-trash.svg" + root.bust; sourceSize: Qt.size(32, 32) }
                        readonly property int lw: Math.ceil(tname.implicitWidth) + 4
                        Rectangle { x: Math.round((72 - parent.lw) / 2); y: 36; width: parent.lw; height: 11; color: "#ffffff" }
                        T { id: tname; x: Math.round((72 - parent.lw) / 2) + 2; y: 35; text: "Trash"; lineHeight: 11; lineHeightMode: Text.FixedHeight }
                    }

                    Win {
                        id: hdWin
                        x: 8; y: 26; width: 294; height: 112
                        title: root.diskName
                        proxy: root.g3Dir + "finder-disk.svg" + root.bust
                        active: !root.frontOpen
                        hdr: hdWin.active ? root.hdrText : root.folders.length + " items"
                        view: topGrid
                        onCloseClicked: root.hide()
                        onBodyClicked: if (!hdWin.active) root.goTop()
                        GridView {
                            id: topGrid
                            x: 3; y: 0
                            width: root.folders.length * root.geoms.top.cw
                            height: parent.height
                            visible: hdWin.active
                            header: Item { width: 1; height: 4 }
                            footer: Item { width: 1; height: 4 }
                            cellWidth: root.geoms.top.cw
                            cellHeight: root.geoms.top.ch
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.folders
                            delegate: Cell {}
                        }
                    }

                    Win {
                        id: midWin
                        x: 20; y: 48; width: 282; height: 230
                        visible: root.inSub
                        active: false
                        title: root.curFolder ? root.curFolder.name : ""
                        proxy: root.curFolder ? root.curFolder.icon : ""
                        hdr: (root.subs[root.view] || []).length + " items"
                        onBodyClicked: root.goUp()
                    }

                    Win {
                        id: frontWin
                        x: root.inSub ? 34 : 20
                        y: root.inSub ? 66 : 48
                        width: 282
                        height: root.inSub ? 212 : 230
                        visible: root.frontOpen
                        title: root.frontTitle
                        proxy: root.frontProxy
                        lens: root.searching
                        hdr: root.hdrText
                        view: frontGrid
                        onCloseClicked: root.goUp()
                        GridView {
                            id: frontGrid
                            x: 1; y: 0
                            width: root.geom.cols * root.geom.cw
                            height: parent.height
                            header: Item { width: 1; height: 4 }
                            footer: Item { width: 1; height: 4 }
                            cellWidth: root.geom.cw
                            cellHeight: root.geom.ch
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.frontOpen ? root.items : []
                            delegate: Cell {}
                            onModelChanged: { currentIndex = 0; positionViewAtBeginning() }
                        }
                        T {
                            visible: root.frontOpen && root.items.length === 0
                            x: 0; y: 54
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.emptyText
                            color: "#6a6a6a"
                        }
                    }

                    Rectangle {
                        x: 0; y: 0; width: parent.width; height: 18
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#f4f4f4" }
                            GradientStop { position: 1; color: "#dadada" }
                        }
                        Rectangle { y: 17; width: parent.width; height: 1; color: root.pl.line }
                        Image { x: 56; y: 1; width: 14; height: 16; source: root.g3Dir + "finder-note.svg" + root.bust; sourceSize: Qt.size(14, 16) }
                        Row {
                            x: 78
                            Repeater {
                                model: ["File", "Edit", "View", "Special"]
                                Item {
                                    required property string modelData
                                    width: mt.implicitWidth + 12
                                    height: 17
                                    T {
                                        id: mt
                                        x: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.verticalCenterOffset: -1
                                        text: parent.modelData
                                        font.family: root.fSys
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                        Item {
                            anchors.right: parent.right; anchors.rightMargin: 62; y: 2; width: 120; height: 14
                            Rectangle { anchors.fill: parent; color: "#ffffff" }
                            Rectangle { x: 0; y: 0; width: 120; height: 1; color: "#5c5c5c" }
                            Rectangle { x: 0; y: 0; width: 1; height: 14; color: "#5c5c5c" }
                            Rectangle { x: 1; y: 13; width: 119; height: 1; color: "#d0d0d0" }
                            Rectangle { x: 119; y: 1; width: 1; height: 13; color: "#d0d0d0" }
                            Rectangle { x: 1; y: 1; width: 118; height: 1; color: "#a8a8a8" }
                            Rectangle { x: 1; y: 1; width: 1; height: 12; color: "#a8a8a8" }
                            Lens { x: 4; y: 3 }
                            TextInput {
                                id: findField
                                x: 16; y: 1
                                width: 103
                                height: 12
                                clip: true
                                color: "#000000"
                                font.family: root.fSmall
                                font.pixelSize: 10
                                font.hintingPreference: Font.PreferFullHinting
                                renderType: TextInput.NativeRendering
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: root.query = text
                                Keys.onPressed: function (e) { root.pressed(e) }
                                cursorDelegate: Rectangle {
                                    width: 1
                                    height: 10
                                    color: "#000000"
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        running: findField.activeFocus
                                        PropertyAction { value: 1 }
                                        PauseAnimation { duration: 530 }
                                        PropertyAction { value: 0 }
                                        PauseAnimation { duration: 530 }
                                    }
                                }
                                T {
                                    visible: findField.text === ""
                                    x: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Find"
                                    color: "#8a8a8a"
                                }
                            }
                        }
                    }

                    Item {
                        id: balloon
                        readonly property var it: root.frontOpen ? root.items[frontGrid.currentIndex] : undefined
                        readonly property Item ci: frontGrid.currentItem
                        readonly property bool kao: !!balloon.it && balloon.it.kind === "kaomoji"
                        readonly property bool kaoGlyph: balloon.kao && root.searching
                        readonly property bool inView: balloon.cellTop + root.geom.ch > frontWin.y + 35 && balloon.cellTop < frontWin.y + frontWin.height - 1
                        readonly property bool want: !!balloon.it && !!balloon.ci && balloon.inView
                            && (balloon.it.kind === "emoji" || balloon.kao || (balloon.it.kind === "clip" && balloon.it.clip.kind === "text" && balloon.ci.truncated))
                        readonly property bool emojiOnly: !!balloon.it && balloon.it.kind === "emoji" && !root.searching
                        readonly property real cx: frontWin.x + 2 + (frontGrid.currentIndex % root.geom.cols) * root.geom.cw + (balloon.ci ? balloon.ci.anchorX : root.geom.cw / 2)
                        readonly property real cellTop: frontWin.y + 1 + 34 + Math.floor(frontGrid.currentIndex / root.geom.cols) * root.geom.ch - frontGrid.contentY
                        readonly property real below: balloon.cellTop + (balloon.emojiOnly ? 32 : (balloon.kao && !root.searching ? root.geom.ch : 62)) + 9
                        readonly property bool flip: balloon.below + box.height > mac.height - 4
                        readonly property bool leftAnchor: balloon.cx < 200
                        visible: balloon.want
                        z: 5
                        x: balloon.leftAnchor ? Math.max(4, balloon.cx - 10) : Math.min(mac.width - 4, balloon.cx + 10) - box.width
                        y: balloon.flip ? balloon.cellTop - 9 - box.height + 6 : balloon.below

                        Rectangle { x: 2; y: 2; width: box.width; height: box.height; radius: 7; color: Qt.rgba(12 / 255, 33 / 255, 48 / 255, 0.35) }
                        Rectangle {
                            id: box
                            readonly property real tw: Math.min(balloon.kaoGlyph ? 156 : 152, Math.max(bk.visible ? bk.implicitWidth : 0, bt.implicitWidth))
                            width: tw + 16
                            height: bcol.height + 9
                            radius: 7
                            color: "#ffffff"
                            border.width: 1
                            border.color: root.pl.line
                            Column {
                                id: bcol
                                x: 8; y: 4
                                width: box.tw
                                T {
                                    id: bk
                                    visible: !!balloon.it && (balloon.it.kind === "clip" || balloon.kaoGlyph)
                                    width: parent.width
                                    text: balloon.kao ? balloon.it.words : "text clipping"
                                    color: "#5a6b72"
                                    lineHeight: 12
                                    lineHeightMode: Text.FixedHeight
                                }
                                T {
                                    id: bt
                                    width: parent.width
                                    wrapMode: balloon.kao ? Text.NoWrap : Text.WrapAtWordBoundaryOrAnywhere
                                    text: !balloon.it ? "" : (balloon.it.kind === "emoji" ? balloon.it.name : balloon.kao ? (root.searching ? balloon.it.glyph : balloon.it.words) : (balloon.it.full || ""))
                                    font.family: balloon.kaoGlyph ? root.fKao : root.fSmall
                                    font.weight: balloon.kaoGlyph ? Font.Medium : Font.Normal
                                    font.pixelSize: balloon.kaoGlyph ? 12 : 10
                                    lineHeight: balloon.kaoGlyph ? 14 : 12
                                    lineHeightMode: Text.FixedHeight
                                }
                            }
                        }
                        Item {
                            width: 12; height: 10
                            x: balloon.leftAnchor ? 5 : box.width - 5 - 12
                            y: balloon.flip ? box.height - 2 : -8
                            transform: [
                                Scale { origin.x: 6; origin.y: 5; xScale: balloon.leftAnchor ? 1 : -1; yScale: balloon.flip ? -1 : 1 }
                            ]
                            Svg { d: "M1 0 L11 10 H3 z"; fill: "#ffffff" }
                            Svg { d: "M1 0 L3 10"; stroke: root.pl.line; sw: 1 }
                            Svg { d: "M1 0 L11 10"; stroke: root.pl.line; sw: 1 }
                        }
                    }
                }

                Repeater {
                    model: 106
                    Rectangle {
                        required property int index
                        y: index * 3
                        width: parent.width
                        height: 1
                        color: Qt.rgba(2 / 255, 18 / 255, 25 / 255, 0.06)
                    }
                }
            }
            Item {
                id: g3mask
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Svg { x: -43; y: -55; width: 760; height: 480; d: "M70 58Q252 52 434 58Q458 59 459 84Q463 214 459 344Q458 369 434 370Q252 376 70 370Q46 369 45 344Q41 214 45 84Q46 59 70 58Z"; fill: "#ffffff" }
            }
            MultiEffect {
                anchors.fill: parent
                source: g3content
                maskEnabled: true
                maskSource: g3mask
            }
        }

        Image { source: root.g3Dir + "g3-beam.svg" + root.bust; sourceSize: Qt.size(760, 480); opacity: gs.bo; transform: Scale { origin.x: 252; origin.y: 214; xScale: gs.bx } }
        Image { source: root.g3Dir + "g3-glare.svg" + root.bust; sourceSize: Qt.size(760, 480) }
        Image { source: root.g3Dir + "g3-led.svg" + root.bust; sourceSize: Qt.size(760, 480); opacity: gs.lo }
    }
}
