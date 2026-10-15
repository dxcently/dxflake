import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt.labs.folderlistmodel
import "Kit.js" as Kit
import "Emoji.js" as Emoji
import "Kaomoji.js" as Kaomoji
import "Trash.js" as Trash
import "Rice.js" as Rice

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
        clipBig: { cw: 128, ch: 118, cols: 3 },
        pics: { cw: 88, ch: 78, cols: 3 },
        emoji: { cw: 33, ch: 33, cols: 8 },
        kaomoji: { cw: 264, ch: 20, cols: 1 },
        search: { cw: 66, ch: 60, cols: 4 },
        sub: { cw: 66, ch: 60, cols: 4 },
        songs: { cw: 88, ch: 60, cols: 3 },
        trash: { cw: 265, ch: 18, cols: 1 },
        keys: { cw: 265, ch: 18, cols: 1 }
    })
    readonly property var folders: [
        { kind: "folder", key: "apps", name: "Applications", icon: root.g3Dir + "finder-folder-apps.svg" + root.bust },
        { kind: "folder", key: "clip", name: "Clipboard", icon: root.g3Dir + "finder-folder-clipboard.svg" + root.bust },
        { kind: "folder", key: "emoji", name: "Emoji", icon: root.g3Dir + "finder-folder-emoji.svg" + root.bust },
        { kind: "folder", key: "kaomoji", name: "Kaomoji", icon: root.g3Dir + "finder-folder-kaomoji.svg" + root.bust },
        { kind: "folder", key: "pics", name: "Desktop Pictures", icon: root.g3Dir + "finder-folder-pictures.svg" + root.bust },
        { kind: "folder", key: "songs", name: "Songs", icon: root.g3Dir + "finder-folder-songs.svg" + root.bust }
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
    Shortcut { sequence: "Escape"; enabled: root.shown; onActivated: root.dismiss() }

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
            root.refreshTrash()
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
    // Super+W: shows the G3 with Desktop Pictures in front; pressed again while Pictures is in front it hides the G3
    function openPictures() {
        if (root.shown && root.view === "pics" && !root.aboutOpen) { root.hide(); return }
        root.show()
        root.menuOpen = ""
        root.aboutOpen = false
        root.openFolder("pics")
    }

    // ── the Finder: state ──
    property string view: "top"
    property string sub: ""
    property string query: ""
    onQueryChanged: root.picSel = ""
    property int dataTick: 0
    property var binds: []
    property string bindsState: "idle"
    property var sortMemo: ({})

    // ── keys: where the keyboard is (grid | band | bar | desk); a mouse press anywhere puts it back on the grid ──
    property string keyFocus: "grid"
    property string barTitle: ""
    property int bandAt: 0
    property int deskAt: 0
    property bool keyMenu: false
    readonly property var titles: ["♪", "File", "Edit", "View", "Special", "Help", "Song"]

    readonly property bool searching: root.view === "top" && root.query.trim() !== ""
    readonly property bool frontOpen: root.view !== "top" || root.searching
    readonly property bool inSub: root.sub !== ""
    readonly property bool canUp: root.inSub || root.searching
    readonly property bool showFolders: !!root.subs[root.view] && !root.inSub && root.query.trim() === ""
    readonly property var parentItems: root.view === "songs" ? root.songItems : (root.subs[root.view] || [])
    readonly property bool clipBig: root.view === "clip" && !!frontWin.unzoom
    readonly property var geom: root.geoms[root.searching ? "search" : root.showFolders ? "sub" : root.clipBig ? "clipBig" : root.view]
    onClipBigChanged: Qt.callLater(function () { root.reveal(frontGrid, frontGrid.currentIndex) })
    readonly property var items: root.sorted(root.compute(root.view, root.sub, root.query, root.dataTick))
    readonly property bool listed: root.view === "trash" || root.view === "keys"
    readonly property Item listItem: root.view === "trash" ? trashList : keysList
    readonly property Item grid: root.frontOpen ? (root.listed ? root.listItem : frontGrid) : topGrid
    readonly property var listCols: {
        if (root.view === "keys") {
            var keyed = root.finderKeys.concat(root.binds)
            return [Math.min(160, root.widest(keyed, "keys", 128)), root.widest(keyed, "label", 122)]
        }
        if (root.view !== "trash") return [0, 0]
        var rows = root.trashRows("")
        return [root.widest(rows, "label", 110), Math.min(160, root.widest(rows, "when", 122))]
    }
    readonly property real listWant: (root.view === "keys" ? 6 : 24) + root.listCols[0] + 4 + root.listCols[1] + 22
    readonly property string hdrText: {
        if (root.view === "clip" && root.clipboard.loading) return "Reading clipboard…"
        if (root.view === "clip" && root.clipErr !== "") return root.clipErr
        if (root.view === "pics" && root.picErr !== "") return root.picErr
        if (root.view === "songs" && !Rice.ready(root.answer)) return ""
        if (root.view === "songs" && root.pending) return "…"
        var n = root.items.length
        if (root.view === "keys") return root.bindsState === "ok" ? root.fmt(n) + (n === 1 ? " shortcut" : " shortcuts") : ""
        if (root.view === "trash") return root.trashState === "ok" ? root.fmt(n) + (n === 1 ? " item" : " items") : ""
        return n === 0 ? "0 items" : root.fmt(n) + (n === 1 ? " item" : " items") + ", 1 selected"
    }
    readonly property string emptyText: {
        if (root.view === "keys") {
            if (root.bindsState === "unavailable") return "Shortcuts are unavailable"
            if (root.bindsState !== "ok") return ""
            if (root.query.trim() === "") return "No shortcuts found"
        }
        if (root.view === "trash" && root.query.trim() === "") {
            if (root.trashState === "missing") return "Can\u2019t read the Trash: gio is not installed."
            return root.trashState === "ok" ? "The Trash is empty" : (root.trashState === "unknown" ? "" : "Trash is unavailable")
        }
        if (root.view === "pics" && root.query.trim() === "") return "No pictures found"
        if (root.view === "songs" && root.query.trim() === "" && !Rice.ready(root.answer)) return Rice.waiting(root.answer).label
        if (root.view === "clip" && root.query.trim() === "")
            return root.clipboard.loading ? "" : (root.clipboard.loadError ? "Clipboard history unavailable" : "No clippings yet")
        return "No items match “" + root.query.trim() + "”"
    }
    readonly property var curFolder: root.folders[root.keyIndex(root.folders, root.view)]
    readonly property var curSub: root.inSub ? root.parentItems[root.keyIndex(root.parentItems, root.sub)] : undefined
    readonly property string frontTitle: {
        if (root.searching) return "Find “" + root.query.trim() + "”"
        if (root.view === "trash") return "Trash"
        if (root.view === "keys") return "Keyboard Shortcuts"
        if (root.view === "songs" && root.sub === "drafts")
            return "Drafts" + (Rice.ready(root.answer) && root.answer.draftsSong ? " · " + root.answer.draftsSong : "")
        if (root.curSub) return root.curSub.name
        return root.curFolder ? root.curFolder.name : ""
    }
    readonly property string frontProxy: {
        if (root.curSub) return root.curSub.icon
        if (root.view === "trash") return root.g3Dir + "finder-trash.svg" + root.bust
        if (root.view === "keys") return root.g3Dir + "finder-note.svg" + root.bust
        return root.curFolder ? (root.menuIcons[root.curFolder.key] || root.curFolder.icon) : ""
    }
    readonly property var menuIcons: ({
        apps: root.g3Dir + "finder-menu-folder-apps.svg" + root.bust,
        clip: root.g3Dir + "finder-menu-folder-clipboard.svg" + root.bust,
        emoji: root.g3Dir + "finder-menu-folder-emoji.svg" + root.bust,
        kaomoji: root.g3Dir + "finder-menu-folder-kaomoji.svg" + root.bust,
        pics: root.g3Dir + "finder-menu-folder-pictures.svg" + root.bust,
        songs: root.g3Dir + "finder-menu-folder-songs.svg" + root.bust,
        trash: root.g3Dir + "finder-trash.svg" + root.bust
    })
    readonly property real memUsed: root.memTotalKb > 0 ? (root.memTotalKb - root.memAvailKb) / root.memTotalKb : 0
    readonly property string memText: root.fmt(Math.round((root.memTotalKb - root.memAvailKb) / 1024)) + " MB used of "
        + root.fmt(Math.round(root.memTotalKb / 1024)) + " MB"
    readonly property bool sortable: root.frontOpen && root.view !== "top" && root.view !== "songs" && root.query.trim() === ""
    readonly property bool dated: root.view === "clip" || root.view === "trash"
    readonly property var sortDefault: ({ apps: "name", clip: "date", trash: "name", emoji: "kind", kaomoji: "kind", keys: "kind", pics: "kind" })
    readonly property string sortBy: root.sortMemo[root.view + "/" + root.sub] || root.sortDefault[root.view] || "name"
    readonly property var selItem: root.items[root.grid.currentIndex]
    readonly property bool canOpen: !root.aboutOpen && !!root.selItem && ["folder", "app", "clip", "emoji", "kaomoji", "pic", "rice"].indexOf(root.selItem.kind) >= 0
        && !(root.selItem.kind === "pic" && root.coverLocked) && !(root.selItem.kind === "rice" && (!root.selItem.row.live || root.pending))
    readonly property bool canCopy: !root.aboutOpen && (findField.selectedText !== "" || (!!root.selItem && ["emoji", "kaomoji", "clip"].indexOf(root.selItem.kind) >= 0))
    readonly property bool canPaste: !root.aboutOpen && (findField.selectedText !== "" || root.newestText() !== undefined)

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
    function widest(list, field, floor) {
        var m = floor
        for (var i = 0; i < list.length; i++) m = Math.max(m, Math.ceil(lm.advanceWidth("" + list[i][field])))
        return m
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
    function trashRows(q) {
        var rows = []
        for (var i = 0; i < root.trashItems.length; i++) {
            var t = root.trashItems[i]
            if (q && ("" + t.name).toLowerCase().indexOf(q) < 0) continue
            rows.push({ kind: "trash", uri: t.uri, name: t.name, label: t.name.replace(/[\x00-\x1F\x7F-\x9F\u2028\u2029\u202A-\u202E\u2066-\u2069\u200E\u200F]+/g, " "),
                        when: Trash.when(t.when), stamp: t.when, dir: t.dir, icon: root.g3Dir + (t.dir ? "finder-folder.svg" : "finder-doc.svg") + root.bust })
        }
        return rows
    }
    function picItems(q) {
        var list = []
        for (var k = 0; k < 2; k++) {
            var m = k === 0 ? ownPics : libPics
            for (var i = 0; i < m.count; i++) {
                var file = "" + m.get(i, "fileName"), name = file.replace(/\.[^.]*$/, "")
                list.push({ kind: "pic", own: k === 0, name: name, full: name, path: "" + m.get(i, "filePath"), url: m.get(i, "fileUrl"),
                            tile: file.toLowerCase().indexOf("_tile") >= 0 })
            }
        }
        return q ? root.rank(q, list, function (p) { return p.name }) : list
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
        if (view === "keys") return root.keyRows(q)
        if (view === "trash") return root.trashRows(q)
        if (view === "apps") return root.appItems(q)
        if (view === "clip") return root.clipItems(q)
        if (view === "pics") return root.picItems(q)
        if (view === "songs") {
            var rice = sub === "drafts" ? root.draftItems : root.songItems
            return q ? root.rank(q, rice, function (it) { return it.name }) : rice
        }
        if (q === "" && sub === "") return root.subs[view]
        return root.glyphItems(root.glyphsIn(view === "emoji" ? Emoji.all() : Kaomoji.all(), sub), q)
    }

    function sorted(list) {
        if (!root.sortable) return list
        var by = root.sortBy, keyed = []
        for (var i = 0; i < list.length; i++) keyed.push({ it: list[i], n: i })
        keyed.sort(function (a, b) { return root.cmpItems(a.it, b.it, by) || a.n - b.n })
        return keyed.map(function (k) { return k.it })
    }
    function cmpText(x, y) { return x < y ? -1 : (x > y ? 1 : 0) }
    function labelOf(it) { return ("" + (it.label !== undefined ? it.label : it.name)).toLowerCase() }
    function kindOf(it) {
        if (it.kind === "app") return (it.entry.categories || [])[0] || "~"
        if (it.kind === "clip") return it.clip.kind === "image" ? "1" : "0"
        if (it.kind === "trash") return it.dir ? "0" : "1"
        if (it.kind === "pic") return it.own ? "0" : "1"
        return ""
    }
    function cmpItems(a, b, by) {
        if (by === "name") return (root.bindGroups.indexOf(a.group) - root.bindGroups.indexOf(b.group)) || root.cmpText(root.labelOf(a), root.labelOf(b))
        if (by === "date") return root.cmpText(b.stamp || "", a.stamp || "")
        return root.cmpText(root.kindOf(a), root.kindOf(b)) || (a.kind === "app" || a.kind === "trash" ? root.cmpText(root.labelOf(a), root.labelOf(b)) : 0)
    }
    function setSort(by) {
        var m = {}
        for (var k in root.sortMemo) m[k] = root.sortMemo[k]
        m[root.view + "/" + root.sub] = by
        root.sortMemo = m
    }

    readonly property var modNames: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"], [2, "Caps Lock"], [16, "Mod2"], [32, "Mod3"], [128, "Mod5"]]
    readonly property var bindGroups: ["Finder", "Apps", "Workspaces", "Windows", "Shell"]
    readonly property var finderKeys: [
        ["Tab", "Next: window buttons, menu bar, desktop"],
        ["Shift + Tab", "Previous: desktop, menu bar, window buttons"],
        ["Return / Space (button)", "Press the focused window button"],
        ["Up (top row)", "Go to the menu bar"],
        ["Left / Right", "Walk the menu bar"],
        ["Down / Return / Space", "Open the highlighted menu"],
        ["Up / Down", "Move in an open menu"],
        ["Return", "Run the menu item"],
        ["Escape", "Close the menu, then back to the window"],
        ["Arrows / Return (desktop)", "Walk and open the desktop icons"],
        ["Ctrl + Up", "Up one folder"],
        ["Ctrl + /", "Zoom the front window"],
        ["Page Up / Page Down", "Move one page"],
        ["Home / End", "First / last item"],
        ["Left / Right (picture)", "Previous / next picture clipping"],
        ["Return (picture)", "Copy the picture"],
        ["Delete / Ctrl + Backspace", "Delete the selected clipping"],
        ["Ctrl + Backspace", "In the picture viewer: delete it, show the next"]
    ].map(function (k) { return { kind: "bind", group: "Finder", keys: k[0], label: k[1] } })
    function capWord(k) {
        var s = "" + k
        return s.length > 1 && s === s.toUpperCase() ? s.charAt(0) + s.slice(1).toLowerCase() : s.charAt(0).toUpperCase() + s.slice(1)
    }
    function keyWord(b) {
        var m = /^mouse:(\d+)$/.exec(b.key)
        if (m) return ({ 272: "Left Click", 273: "Right Click", 274: "Middle Click" })[m[1]] || ("Mouse " + m[1])
        return root.capWord(b.key)
    }
    function bindKeys(b) {
        var parts = []
        for (var i = 0; i < root.modNames.length; i++) if (b.modmask & root.modNames[i][0]) parts.push(root.modNames[i][1])
        parts.push(root.keyWord(b))
        return parts.join(" + ")
    }
    function programOf(cmd) {
        var segs = ("" + cmd).replace(/^\s*(\[[^\]]*\]\s*)+/, "").split(/;|\||&&/)
        for (var i = 0; i < segs.length; i++) {
            var w = segs[i].trim().split(/\s+/)[0]
            if (w && w !== "pkill" && w !== "killall") return w.replace(/^.*\//, "")
        }
        return ("" + cmd).trim()
    }
    function dirWord(a) { return ({ l: "left", r: "right", u: "up", d: "down" })[a] || a }
    function resizeLabel(a) {
        var p = ("" + a).trim().split(/\s+/), x = Number(p[0]), y = Number(p[1] || 0)
        if (x && !y) return (x > 0 ? "Widen" : "Narrow") + " window by " + Math.abs(x)
        if (y && !x) return (y > 0 ? "Heighten" : "Shorten") + " window by " + Math.abs(y)
        return "Resize window by " + a
    }
    function bindLabel(b) {
        var a = "" + b.arg
        switch (b.dispatcher) {
        case "exec": return "Open " + root.programOf(a)
        case "workspace": return a === "previous" ? "Go to previous workspace" : "Go to workspace " + a
        case "movetoworkspace": return a.indexOf("special:") === 0 ? "Send window to special workspace " + a.slice(8) : "Send window to workspace " + a
        case "togglespecialworkspace": return "Toggle special workspace " + a
        case "movefocus": return "Focus window " + root.dirWord(a)
        case "movewindow": return "Move window " + root.dirWord(a)
        case "resizeactive": return root.resizeLabel(a)
        case "killactive": return "Close window"
        case "togglefloating": return "Toggle floating"
        case "fullscreen": return "Toggle fullscreen"
        case "layoutmsg": return ({ "promote": "Promote window to master", "fit visible": "Fit visible windows", "fit active": "Fit active window" })[a] || "layoutmsg " + a
        case "global": return "Aoide " + a.replace(/^aoide:/, "")
        case "mouse": return a === "movewindow" ? "Move window (drag)" : (a === "resizewindow" ? "Resize window (drag)" : "mouse " + a)
        }
        return (b.dispatcher + " " + a).trim()
    }
    function bindGroup(b) {
        if (b.dispatcher === "exec") return "Apps"
        if (b.dispatcher === "workspace" || b.dispatcher === "movetoworkspace" || b.dispatcher === "togglespecialworkspace") return "Workspaces"
        if (["movefocus", "movewindow", "resizeactive", "killactive", "togglefloating", "fullscreen", "layoutmsg", "mouse"].indexOf(b.dispatcher) >= 0) return "Windows"
        return "Shell"
    }
    function bindsRead(code, text) {
        var raw = null
        if (code === 0) { try { raw = JSON.parse(text) } catch (e) { raw = null } }
        if (!Array.isArray(raw)) { root.binds = []; root.bindsState = "unavailable"; return }
        var out = []
        for (var g = 0; g < root.bindGroups.length; g++)
            for (var i = 0; i < raw.length; i++)
                if (root.bindGroup(raw[i]) === root.bindGroups[g])
                    out.push({ kind: "bind", group: root.bindGroups[g], label: root.bindLabel(raw[i]), keys: root.bindKeys(raw[i]) })
        root.binds = out
        root.bindsState = "ok"
    }
    function keyRows(q) {
        return root.finderKeys.concat(root.binds).filter(function (b) { return !q || (b.label + " " + b.keys + " " + b.group).toLowerCase().indexOf(q) >= 0 })
    }
    function openKeys() {
        root.menuOpen = ""
        root.openFolder("keys")
        if (!bindsRun.running) bindsRun.go()
    }

    function resetState() {
        findField.text = ""
        root.sub = ""
        root.view = "top"
        root.alertOpen = false
        root.menuOpen = ""
        root.aboutOpen = false
        root.keyFocus = "grid"
        root.viewIt = null
        root.clipErr = ""
        root.picSel = ""
        root.picErr = ""
        topGrid.currentIndex = 0
        topGrid.positionViewAtBeginning()
        root.clipboard.refresh()
    }
    function openFolder(key) {
        root.viewIt = null
        root.clipErr = ""
        root.picSel = ""
        root.picErr = ""
        findField.text = ""
        root.sub = ""
        root.view = key
        if (key === "clip") root.clipboard.refresh()
        if (key === "trash") root.refreshTrash()
        if (key === "songs") root.askRice()
    }
    function openSub(key) {
        findField.text = ""
        root.sub = key
        if (root.view === "songs") root.askRice()
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
        var at = root.keyIndex(root.parentItems, root.sub)
        findField.text = ""
        root.sub = ""
        frontGrid.currentIndex = at
        root.reveal(frontGrid, at)
    }
    function nav(dx, dy) {
        var g = root.grid, n = g.count
        if (n === 0) return
        var i = g.currentIndex
        var j = dx !== 0 ? i + dx : i + dy * root.geom.cols
        if (dy < 0 && j < 0) j = i
        j = Math.max(0, Math.min(n - 1, j))
        g.currentIndex = j
        root.reveal(g, j)
    }
    function page(dir) {
        var g = root.grid, n = g.count, c = root.geom.cols
        if (n === 0) return
        var j = g.currentIndex + dir * Math.max(1, Math.floor(g.height / root.geom.ch)) * c
        if (j < 0) j = g.currentIndex % c
        root.jump(Math.min(n - 1, j))
    }
    function jump(j) {
        if (root.grid.count === 0) return
        root.grid.currentIndex = j
        root.reveal(root.grid, j)
    }
    function reveal(g, i) {
        if (g === trashList || g === keysList) { g.positionViewAtIndex(i, ListView.Contain); return }
        var rowY = Math.floor(i / root.geom.cols) * root.geom.ch
        var s = g.contentY - g.originY
        if (rowY < s) s = rowY
        if (rowY + root.geom.ch + 8 > s + g.height) s = rowY + root.geom.ch + 8 - g.height
        g.contentY = g.originY + Math.max(0, Math.min(s, g.contentHeight - g.height))
    }
    function activate(it) {
        if (!it || root.aboutOpen) return
        if (it.kind === "folder") { if (root.view === "top") root.openFolder(it.key); else root.openSub(it.key) }
        else if (it.kind === "app") {
            if (!it.entry.command || it.entry.command.length === 0) return
            Quickshell.execDetached(Kit.scopeArgv(it.entry))
            root.ledger.record(it.entry.id)
            root.hide()
        } else if (it.kind === "clip") {
            if (it.clip.kind === "image") root.openViewer(it)
            else if (root.clipboard.copyById(it.clip.id)) root.hide()
        } else if (it.kind === "emoji" || it.kind === "kaomoji") {
            Quickshell.execDetached(["wl-copy", "--", it.glyph])
            root.hide()
        } else if (it.kind === "pic") {
            if (!root.coverLocked) Quickshell.execDetached(["lyra", "cover", "set", it.path])
        } else if (it.kind === "rice") root.riceAct(it.row)
    }
    function pressed(e) {
        if (root.alertOpen) {
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Escape) root.alertCancel()
            e.accepted = true
            return
        }
        var command = (e.modifiers & (Qt.ControlModifier | Qt.MetaModifier)) !== 0
        // About in front is the front window and has no selection: only its ⌘W and ⌘/ (Esc is the Shortcut), the menu bar and the Tab ring act
        if (root.aboutOpen && !(command ? e.key === Qt.Key_W || e.key === Qt.Key_Slash : root.menuOpen !== "" || e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab
                || root.keyFocus === "bar" && [Qt.Key_Left, Qt.Key_Right, Qt.Key_Down, Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space].indexOf(e.key) >= 0)) { e.accepted = true; return }
        if (command) {
            var known = true
            switch (e.key) {
            case Qt.Key_O: if (root.canOpen) root.openSel(); break
            case Qt.Key_W: if (root.frontOpen || root.aboutOpen || root.viewIt) root.closeWindow(); break
            case Qt.Key_F: root.focusFind(); break
            case Qt.Key_C: if (root.canCopy) root.copyPick(); break
            case Qt.Key_V: if (root.canPaste) root.pasteText(); break
            case Qt.Key_Y: root.putAway(); break
            case Qt.Key_Up: if (root.canUp) root.goUp(); break
            case Qt.Key_Backspace:
                if (findField.text !== "" && !root.viewIt) { known = false; break }
                if (root.canTrashClip && !e.isAutoRepeat) root.trashClip()
                break
            case Qt.Key_Slash:
                if (root.menuOpen === "Position") { root.menuOpen = ""; root.keyFocus = root.band[root.bandAt] !== undefined ? "band" : "grid" }
                (root.aboutOpen ? aboutWin : root.viewIt ? viewWin : root.frontOpen ? frontWin : hdWin).zoom()
                break
            default: known = false
            }
            if (known) { e.accepted = true; return }
        }
        var back = e.key === Qt.Key_Backtab || (e.key === Qt.Key_Tab && (e.modifiers & Qt.ShiftModifier) !== 0)
        if (root.menuOpen !== "") {
            root.menuKey(e.key)
            e.accepted = true
            return
        }
        if (e.key === Qt.Key_Tab || back) {
            root.ring(back ? -1 : 1)
            e.accepted = true
            return
        }
        // the picture viewer in front keeps the grid's keys: ←/→ step, Return is its default button (Copy)
        if (root.viewIt && root.keyFocus === "grid" && !command) {
            if (e.key === Qt.Key_Left || e.key === Qt.Key_Right) root.stepViewer(e.key === Qt.Key_Left ? -1 : 1)
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.viewerCopy()
            e.accepted = true
            return
        }
        if (root.keyFocus !== "grid") {
            var took = root.keyFocus === "bar" ? root.barKey(e.key) : root.keyFocus === "desk" ? root.deskKey(e.key) : root.bandKey(e.key)
            if (!took && e.text !== "" && e.text.charCodeAt(0) >= 32 && e.text.charCodeAt(0) !== 127 && (e.modifiers & Qt.AltModifier) === 0 && !command) {
                root.keyFocus = "grid"
                return
            }
            e.accepted = true
            return
        }
        switch (e.key) {
        case Qt.Key_Left: root.nav(-1, 0); e.accepted = true; break
        case Qt.Key_Right: root.nav(1, 0); e.accepted = true; break
        case Qt.Key_Up:
            if (root.grid.currentIndex < root.geom.cols) root.toBar(root.titles[0])
            else root.nav(0, -1)
            e.accepted = true
            break
        case Qt.Key_Down: root.nav(0, 1); e.accepted = true; break
        case Qt.Key_PageUp: root.page(-1); e.accepted = true; break
        case Qt.Key_PageDown: root.page(1); e.accepted = true; break
        case Qt.Key_Home: root.jump(0); e.accepted = true; break
        case Qt.Key_End: root.jump(root.grid.count - 1); e.accepted = true; break
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
        case Qt.Key_Delete:
            if (findField.text === "" && root.canTrashClip) {
                if (!e.isAutoRepeat) root.trashClip()
                e.accepted = true
            }
            break
        }
    }
    // the Tab ring: grid → the front window's live band controls → menu bar → desktop → grid
    function ring(dir) {
        var stops = ["grid"]
        for (var i = 0; i < root.band.length; i++) stops.push("band" + i)
        stops.push("bar", "desk")
        var at = stops.indexOf(root.keyFocus === "band" ? "band" + root.bandAt : root.keyFocus)
        var to = stops[(at + dir + stops.length) % stops.length]
        if (to === "bar") root.toBar(root.titles[0])
        else if (to === "desk") { root.deskAt = 0; root.keyFocus = "desk" }
        else if (to === "grid") root.keyFocus = "grid"
        else { root.bandAt = +to.slice(4); root.keyFocus = "band" }
    }
    function toBar(title) {
        root.barTitle = title
        root.keyFocus = "bar"
    }
    function titleLive(label) { return label !== "Song" || songTitle.live }
    // the next live, non-separator row of a drop from `from` in `dir`, wrapping; -1 when there is none
    function liveRow(d, from, dir) {
        var n = d.rows.length
        if (from < 0 && dir < 0) from = 0
        for (var k = 1; k <= n; k++) {
            var i = ((from + dir * k) % n + n) % n
            if (!d.rows[i].sep && d.rows[i].live === true) return i
        }
        return -1
    }
    function openTitle(label) {
        root.toBar(label)
        root.keyMenu = true
        root.menuOpen = root.titleLive(label) ? label : ""
        var d = root.dropOf(root.menuOpen)
        if (d) d.hot = root.liveRow(d, -1, 1)
    }
    function barKey(k) {
        var at = root.titles.indexOf(root.barTitle), n = root.titles.length
        if (k === Qt.Key_Left || k === Qt.Key_Right) root.barTitle = root.titles[(at + (k === Qt.Key_Left ? -1 : 1) + n) % n]
        else if (k === Qt.Key_Down || k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.openTitle(root.barTitle)
        else return false
        return true
    }
    function menuKey(k) {
        var d = root.dropOf(root.menuOpen), at = root.titles.indexOf(root.menuOpen), n = root.titles.length
        root.keyMenu = true
        if (k === Qt.Key_Up || k === Qt.Key_Down) d.hot = root.liveRow(d, d.hot, k === Qt.Key_Up ? -1 : 1)
        else if ((k === Qt.Key_Left || k === Qt.Key_Right) && at >= 0) root.openTitle(root.titles[(at + (k === Qt.Key_Left ? -1 : 1) + n) % n])
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            var row = d.hot >= 0 ? d.rows[d.hot] : null
            root.keyFocus = root.menuOpen === "Position" && root.band[root.bandAt] !== undefined ? "band" : "grid"
            root.menuOpen = ""
            if (row && !row.sep && row.live === true) row.act()
        }
    }
    function deskKey(k) {
        if (k === Qt.Key_Up || k === Qt.Key_Left) root.deskAt = 0
        else if (k === Qt.Key_Down || k === Qt.Key_Right) root.deskAt = 1
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            root.keyFocus = "grid"
            if (root.deskAt === 0) root.goTop()
            else root.openTrash()
        } else return false
        return true
    }
    function bandKey(k) {
        if (k !== Qt.Key_Return && k !== Qt.Key_Enter && k !== Qt.Key_Space) return false
        if (root.bandFocus === "remove") root.removePicture()
        else if (root.bandFocus === "add") root.addPictures()
        else if (root.bandFocus === "position") root.openPosition(true)
        return true
    }

    // ── cover for the little desktop ──
    property string coverPath: Quickshell.env("AOIDE_WALLPAPER") || ""
    property bool coverPick: false
    property bool coverTile: false
    property bool coverStill: false
    property string coverPosition: "auto"
    readonly property real screenW: root.screen ? root.screen.width : 1920
    // lyra refuses a cover pick while the declared song is locked in
    readonly property bool coverLocked: root.riceMode === "declarative"
    readonly property bool canRemove: root.coverPick && !root.coverLocked && !root.aboutOpen
    readonly property bool canPosition: root.coverStill && !root.coverLocked && !root.aboutOpen
    readonly property bool canAddPics: root.view === "pics" && !root.aboutOpen && !root.coverLocked
    readonly property bool canTrashPic: root.view === "pics" && !root.aboutOpen && !root.coverLocked && !picOp.running
        && !!root.selItem && root.selItem.kind === "pic" && !root.selItem.own
    readonly property var positions: [["auto", "Automatic"], ["tile", "Tile on Screen"], ["fill", "Fill Screen"]]
    readonly property real posBoxW: 6 + Math.ceil(posFit.implicitWidth) + 6 + 17
    T { id: posFit; visible: false; font.family: root.fSys; font.pixelSize: 12; text: root.positions.map(function (q) { return q[1] }).join("\n") }
    readonly property var band: root.view === "pics" ? [root.canRemove ? "remove" : "", root.canPosition ? "position" : "", root.canAddPics ? "add" : ""].filter(function (b) { return b !== "" }) : []
    readonly property string bandFocus: root.keyFocus === "band" ? (root.band[root.bandAt] || "") : ""
    // a band control that goes away (pick cleared, declarative, another window, About in front) closes its popup and hands the keys back to the grid
    onBandChanged: {
        if (root.menuOpen === "Position" && root.band.indexOf("position") < 0) root.menuOpen = ""
        if (root.keyFocus === "band" && root.band[root.bandAt] === undefined) root.keyFocus = "grid"
    }
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
                var mine = !!d && (!d.song || d.song === root.livery.songName)
                root.coverPath = mine && d.path ? "" + d.path : baked
                root.coverPick = mine && d.pick === true && (!!d.path || !!d.weId)
                root.coverTile = mine && !!d.path && d.pick === true && d.tile === true
                root.coverStill = root.coverPick && !!d.path && (d.kind || "static") === "static"
                root.coverPosition = mine && d.position ? "" + d.position : "auto"
            } catch (e) { root.coverPath = baked; root.coverPick = false; root.coverTile = false; root.coverStill = false; root.coverPosition = "auto" }
        }
        onLoadFailed: { root.coverPath = Quickshell.env("AOIDE_WALLPAPER") || ""; root.coverPick = false; root.coverTile = false; root.coverStill = false; root.coverPosition = "auto" }
    }
    function removePicture() {
        if (root.canRemove) Quickshell.execDetached(["lyra", "cover", "set", "--clear"])
    }
    // the folder the Pictures list reads, in the default file manager; the list's folder watch picks up what lands there
    function addPictures() {
        root.menuOpen = ""
        if (root.canAddPics) Quickshell.execDetached(["xdg-open", root.coversDir])
    }
    // a library picture to the system Trash (gio, recoverable, no confirm); the pick in force is cleared first, and the trash
    // runs only once lyra has cleared it. A failure shows in the Pictures window's header (picErr), as clipErr does for clippings.
    property string picErr: ""
    Process {
        id: picOp
        property var next: null
        property string name: ""
        property bool cleared: false
        property bool began: false
        onStarted: picOp.began = true
        onExited: function (code) { root.picOpDone(code) }
        // a binary that is not on PATH never starts and never exits
        onRunningChanged: if (!picOp.running && !picOp.began) root.picOpDone(127)
    }
    function trashPicture() {
        root.menuOpen = ""
        if (!root.canTrashPic) return
        var it = root.selItem, name = it.path.slice(it.path.lastIndexOf("/") + 1)
        root.picErr = ""
        if (name === "" || it.path !== root.coversDir + "/" + name) { root.picErr = "Couldn\u2019t move " + name + " to the Trash"; return }
        var trash = ["gio", "trash", it.path]
        var inForce = root.coverPick && it.path === root.coverPath
        picOp.name = name
        picOp.cleared = false
        picOp.began = false
        picOp.next = inForce ? trash : null
        picOp.command = inForce ? ["lyra", "cover", "set", "--clear"] : trash
        picOp.running = true
    }
    function picOpDone(code) {
        var n = picOp.next
        picOp.next = null
        if (code !== 0) root.picErr = n ? "Couldn\u2019t clear the desktop picture"
            : picOp.cleared ? "Desktop picture cleared; couldn\u2019t trash " + picOp.name : "Couldn\u2019t move " + picOp.name + " to the Trash"
        else if (n) { picOp.cleared = true; picOp.began = false; picOp.command = n; picOp.running = true; return }
        root.refreshTrash()
    }
    // the selected picture by path, so a folder change under the window keeps it (or lands on its neighbour when it went away);
    // a Find change lands on the best match (index 0) as everywhere else. Recorded a tick late, after the grid's own reset to the
    // first item and onModelChanged's restore.
    property string picSel: ""
    property int picAt: 0
    property string picQuery: ""
    function notePic() {
        var it = root.view === "pics" ? root.items[frontGrid.currentIndex] : undefined
        if (it && it.kind === "pic") { root.picSel = it.path; root.picAt = frontGrid.currentIndex; root.picQuery = root.query }
    }
    function picLanded() {
        for (var i = 0; i < root.items.length; i++) if (root.items[i].path === root.picSel) return i
        return Math.min(root.picAt, root.items.length - 1)
    }
    function setPosition(word) {
        if (root.canPosition && word !== root.coverPosition)
            Quickshell.execDetached(["lyra", "cover", "set", root.coverPath, "--position", word])
    }
    function openPosition(keyed) {
        if (!root.canPosition) return
        var p = posBox.mapToItem(mac, 0, posBox.height)
        posDrop.x = p.x
        posDrop.y = p.y
        root.bandAt = root.band.indexOf("position")
        root.keyMenu = keyed
        root.menuOpen = "Position"
        if (keyed) posDrop.hot = Math.max(0, root.positions.map(function (q) { return q[0] }).indexOf(root.coverPosition))
    }

    // ── rice: songs as folders and the right-edge song menu; Rice.js says what every row means ──
    readonly property string riceMode: root.livery.riceMode || "declarative"
    readonly property string riceKey: [root.riceMode, root.livery.songName, (root.livery.modeRaw && root.livery.modeRaw.draft) || ""].join("|")
    property var answer: null
    property int asked: 0
    property bool pending: false
    readonly property bool canMenu: !!root.bridge && typeof root.bridge.riceMenu === "function"
    onRiceKeyChanged: {
        root.pending = false
        if (root.shown && (root.view === "songs" || root.menuOpen === "Song")) root.askRice()
    }
    onMenuOpenChanged: if (root.menuOpen === "Song") root.askRice()
    Timer { interval: 10000; running: root.pending; onTriggered: root.pending = false }
    function askRice() {
        var ask = ++root.asked
        root.answer = root.canMenu ? null : { ok: false, message: "Stage menu needs a newer shell" }
        if (root.canMenu) root.bridge.riceMenu(function (reply) { if (ask === root.asked) root.answer = reply })
    }
    function riceAct(row) {
        if (root.pending || !root.canMenu) return
        root.pending = Rice.act(root.bridge, row)
        // a save changes no livery key, so read the drafts again once the daemon has had time to write one
        if (row.kind === "save" && row.live) afterSave.restart()
    }
    Timer { id: afterSave; interval: 1500; onTriggered: if (root.shown && root.view === "songs") root.askRice() }
    readonly property var songItems: {
        if (!Rice.ready(root.answer)) return []
        return Rice.switchRows(root.answer, root.riceMode).map(function (r) {
            return { kind: "rice", name: r.label, row: r, icon: root.g3Dir + (r.kind === "declarative" ? "finder-declarative.svg" : "finder-folder.svg") + root.bust }
        }).concat([{ kind: "folder", key: "drafts", name: "Drafts", icon: root.g3Dir + "finder-folder-drafts.svg" + root.bust }])
    }
    readonly property var draftItems: !Rice.ready(root.answer) ? [] : Rice.draftRows(root.answer).concat([Rice.newDraft()]).map(function (r) {
        return { kind: "rice", name: r.label, row: r, icon: root.g3Dir + (r.kind === "new" ? "finder-new-draft.svg" : "finder-doc.svg") + root.bust }
    })
    readonly property var songRows: {
        var out = []
        Rice.switchRows(root.answer, root.riceMode).forEach(function (r) {
            if (r.kind === "declarative" && out.length > 0) out.push({ sep: true })
            out.push({ label: r.label, live: r.live, check: r.mark === "✓", ring: r.mark === "○", act: function () { root.riceAct(r) } })
        })
        return out
    }
    component Pics: FolderListModel {
        nameFilters: ["*.webp", "*.png", "*.jpg", "*.jpeg"]
        caseSensitive: false
        sortCaseSensitive: false
        showDirs: false
        onCountChanged: root.dataTick++
    }
    Pics { id: ownPics; folder: "file://" + root.aoideRoot + "/song/songbook/barcarolle/cover" }
    readonly property string coversDir: root.aoideRoot + "/song/covers"
    Pics { id: libPics; folder: "file://" + root.coversDir }

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

    property string osName: ""
    property string kernel: ""
    property real uptimeSecs: 0
    property real memTotalKb: 0
    property real memAvailKb: 0
    FileView {
        id: osRel
        path: "/etc/os-release"
        blockLoading: false
        printErrors: false
        onLoaded: { var m = /^PRETTY_NAME="?([^"\n]*)/m.exec(text()); root.osName = m ? m[1] : "" }
    }
    FileView {
        id: kernelRel
        path: "/proc/sys/kernel/osrelease"
        blockLoading: false
        printErrors: false
        onLoaded: root.kernel = text().trim()
    }
    FileView {
        id: uptimeRead
        path: "/proc/uptime"
        blockLoading: false
        printErrors: false
        onLoaded: root.uptimeSecs = parseFloat(text()) || 0
    }
    FileView {
        id: memRead
        path: "/proc/meminfo"
        blockLoading: false
        printErrors: false
        onLoaded: {
            var t = text()
            var a = /MemTotal:\s+(\d+)/.exec(t), b = /MemAvailable:\s+(\d+)/.exec(t)
            root.memTotalKb = a ? +a[1] : 0
            root.memAvailKb = b ? +b[1] : 0
        }
    }

    // ── the Trash: gio is the backend; trashState says what the desktop and the Trash window show ──
    property string trashState: "unknown"
    property var trashItems: []
    property bool trashStale: false
    property bool alertOpen: false
    property string alertKind: ""
    property string menuOpen: ""
    property bool aboutOpen: false
    readonly property bool trashFull: root.trashItems.length > 0
    readonly property bool canPutAway: !root.aboutOpen && root.view === "trash" && root.trashState === "ok" && root.items.length > 0 && !trashOp.running
    readonly property bool canEmpty: root.trashState === "ok" && root.trashItems.length > 0 && !trashOp.running
    readonly property string alertText: {
        if (root.alertKind === "empty") return "The Trash contains " + root.trashItems.length + (root.trashItems.length === 1 ? " item" : " items")
            + ". Are you sure you want to permanently remove " + (root.trashItems.length === 1 ? "this item" : "these items") + "?"
        if (root.alertKind === "reboot") return "Are you sure you want to restart your computer now?"
        if (root.alertKind === "shutdown") return "Are you sure you want to shut down your computer now?"
        if (root.alertKind === "clip") return "Clear the clipboard history? All " + root.fmt(root.clipCount) + (root.clipCount === 1 ? " clipping" : " clippings")
            + " will be removed. This can\u2019t be undone."
        return "Are you sure you want to log out now?"
    }

    // a Process that reports once: done(code, text) after both its exit code and its whole stdout are in,
    // because Process.exitCode is not set yet when the stdout stream finishes (only onExited carries it)
    component Ran: Process {
        id: ran
        property int code: -1
        property string text: ""
        property int halves: 0
        property bool began: false
        signal done(int code, string text)
        function go() { ran.halves = 0; ran.code = -1; ran.began = false; ran.running = true }
        function half() {
            ran.halves++
            if (ran.halves < 2) return
            ran.halves = 0
            ran.done(ran.code, ran.text)
        }
        stdout: StdioCollector {
            id: ranOut
            waitForEnd: true
            onStreamFinished: { ran.text = ranOut.text; ran.half() }
        }
        onStarted: ran.began = true
        onExited: function (exitCode) { ran.code = exitCode; ran.half() }
        // a binary that is not on PATH never starts: running falls back to false with no exit, which is code 127
        onRunningChanged: if (!ran.running && !ran.began) { ran.halves = 0; ran.code = 127; ran.text = ""; ran.done(127, "") }
    }
    Ran {
        id: trashLister
        command: Trash.listArgv
        onDone: function (code, text) { root.trashListed(code, text) }
    }
    Process {
        id: trashOp
        onExited: root.refreshTrash()
    }
    Ran {
        id: bindsRun
        command: ["hyprctl", "binds", "-j"]
        onDone: function (code, text) { root.bindsRead(code, text) }
    }
    function refreshTrash() {
        if (trashLister.running) { root.trashStale = true; return }
        trashLister.go()
    }
    function trashListed(code, text) {
        if (code === 0) { root.trashItems = Trash.parse(text); root.trashState = "ok" }
        else { root.trashItems = []; root.trashState = code === 127 ? "missing" : "failed" }
        if (root.trashStale) { root.trashStale = false; root.refreshTrash() }
    }
    function runTrashOp(argv) {
        if (trashOp.running) return
        trashOp.command = argv
        trashOp.running = true
    }
    function putAway() {
        if (root.alertOpen) return
        var it = root.canPutAway ? root.items[trashList.currentIndex] : undefined
        root.menuOpen = ""
        if (it) root.runTrashOp(Trash.restoreArgv(it.uri))
    }
    function askEmpty() {
        if (!root.canEmpty) return
        root.menuOpen = ""
        root.alertKind = "empty"
        root.alertOpen = true
    }
    function askPower(action) {
        root.menuOpen = ""
        root.alertKind = action
        root.alertOpen = true
    }
    function alertOk() {
        var k = root.alertKind
        root.alertOpen = false
        if (k === "empty") { root.runTrashOp(Trash.emptyArgv); findField.forceActiveFocus() }
        else if (k === "clip") { if (root.canClearClip) root.clipboard.clear(); findField.forceActiveFocus() }
        else root.power(k)
    }
    function alertCancel() {
        root.alertOpen = false
        findField.forceActiveFocus()
    }
    function power(action) {
        root.bridge.sendCommand({ cmd: "power", action: action })
        root.hide()
    }
    function sleepNow() {
        root.menuOpen = ""
        root.power("suspend")
    }
    function dismiss() {
        if (root.alertOpen) root.alertCancel()
        else if (root.menuOpen !== "") {
            var m = root.menuOpen
            root.menuOpen = ""
            if (root.keyMenu && m === "Position") root.keyFocus = root.band[root.bandAt] !== undefined ? "band" : "grid"
            else if (root.keyMenu && root.titles.indexOf(m) >= 0) root.toBar(m)
        }
        else if (root.keyFocus !== "grid") root.keyFocus = "grid"
        else if (root.aboutOpen) root.aboutOpen = false
        else if (root.viewIt) root.viewIt = null
        else root.hide()
    }
    function closeWindow() {
        root.menuOpen = ""
        if (root.aboutOpen) root.aboutOpen = false
        else if (root.viewIt) root.viewIt = null
        else root.goTop()
    }
    function openSel() {
        root.menuOpen = ""
        root.activate(root.selItem)
    }
    function focusFind() {
        root.menuOpen = ""
        root.keyFocus = "grid"
        findField.forceActiveFocus()
    }
    function clearFind() {
        root.menuOpen = ""
        root.keyFocus = "grid"
        findField.text = ""
        findField.forceActiveFocus()
    }
    function previewIsWhole(p) {
        p = "" + p
        return p.slice(-1) !== "…" && p.indexOf(" ↵ ") < 0 && p.indexOf(" ⇥ ") < 0 && p.indexOf("�") < 0
    }
    function newestText() {
        var list = root.clipboard.parsedEntries || []
        for (var i = 0; i < list.length; i++) {
            if (list[i].kind !== "text") continue
            return root.previewIsWhole(list[i].preview) ? list[i] : undefined
        }
        return undefined
    }
    function copyPick() {
        root.menuOpen = ""
        if (findField.selectedText !== "") { root.keyFocus = "grid"; findField.copy(); return }
        var it = root.selItem
        if (!it) return
        if (it.kind === "emoji" || it.kind === "kaomoji") Quickshell.execDetached(["wl-copy", "--", it.glyph])
        else if (it.kind === "clip") root.clipboard.copyById(it.clip.id)
        findField.forceActiveFocus()
    }
    function pasteText() {
        root.menuOpen = ""
        root.keyFocus = "grid"
        if (findField.selectedText !== "") { findField.paste(); return }
        var c = root.newestText()
        if (c) findField.insert(findField.cursorPosition, c.preview)
        findField.forceActiveFocus()
    }
    function openAbout() {
        root.menuOpen = ""
        osRel.reload()
        kernelRel.reload()
        uptimeRead.reload()
        memRead.reload()
        root.aboutOpen = true
    }
    function uptimeText() {
        var s = Math.floor(root.uptimeSecs), d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        var hms = h + ":" + ("0" + m).slice(-2) + ":" + ("0" + (s % 60)).slice(-2)
        return d > 0 ? d + (d === 1 ? " day, " : " days, ") + hms : hms
    }
    function dropOf(label) {
        return label === "♪" ? appleDrop : label === "File" ? fileDrop : label === "Edit" ? editDrop
            : label === "View" ? viewDrop : label === "Special" ? specialDrop : label === "Help" ? helpDrop
            : label === "Song" ? songDrop : label === "Position" ? posDrop : label === "Context" ? ctxDrop : null
    }
    function titleAt(x, y) {
        var ts = [appleTitle, fileTitle, editTitle, viewTitle, specialTitle, helpTitle, songTitle]
        for (var i = 0; i < ts.length; i++) {
            var q = ts[i].mapToItem(mac, 0, 0)
            if (ts[i].live && x >= q.x && x < q.x + ts[i].width && y >= q.y && y < q.y + ts[i].height) return ts[i].label
        }
        return ""
    }
    function hoverAt(x, y) {
        var d = root.dropOf(root.menuOpen)
        if (!d) return
        var q = mac.mapToItem(d, x, y)
        d.hot = q.x >= 0 && q.x < d.width ? d.indexAt(q.y) : -1
    }
    function rowAt(x, y) {
        var d = root.dropOf(root.menuOpen)
        if (!d) return null
        var q = mac.mapToItem(d, x, y)
        if (q.x < 0 || q.x >= d.width) return null
        var i = d.indexAt(q.y)
        return i >= 0 && d.rows[i].live === true ? d.rows[i] : null
    }
    function openTrash() { root.openFolder("trash") }

    // ── the picture viewer: an image clipping opened in its own window; ←/→ walk the front window's image clippings ──
    property var viewIt: null
    readonly property string viewHome: [root.view, root.sub, root.query].join("/")
    onViewHomeChanged: { root.viewIt = null; if (root.menuOpen === "Context") root.menuOpen = "" }
    readonly property var viewPics: root.items.filter(function (it) { return it.kind === "clip" && it.clip.kind === "image" })
    readonly property int viewAt: {
        for (var i = 0; root.viewIt && i < root.viewPics.length; i++) if (root.viewPics[i].clip.id === root.viewIt.clip.id) return i
        return -1
    }
    // a copy, so a decode finishing (the same state object, mutated) still reaches the viewer
    readonly property var viewState: {
        var st = root.viewIt ? root.clipboard.imageStates[root.viewIt.clip.id] : undefined
        return st ? { state: st.state, source: st.source } : undefined
    }
    function openViewer(it) {
        root.viewIt = it
        root.keyFocus = "grid"
        root.clipboard.requestPreview(it.clip.id)
        for (var i = 0; i < root.items.length; i++) if (root.items[i].kind === "clip" && root.items[i].clip.id === it.clip.id) root.jump(i)
    }
    function stepViewer(dir) {
        var j = root.viewAt + dir
        if (root.viewAt >= 0 && j >= 0 && j < root.viewPics.length) root.openViewer(root.viewPics[j])
    }
    function viewerCopy() {
        if (root.viewIt && root.clipboard.copyById(root.viewIt.clip.id)) root.hide()
    }

    // ── removing clippings: lyra clipboard delete/clear through the clipboard extra, which reloads the list when lyra exits ──
    readonly property bool canEditClip: typeof root.clipboard.deleteById === "function"
    readonly property int clipCount: (root.clipboard.parsedEntries || []).length
    readonly property bool canTrashClip: root.canEditClip && !root.aboutOpen && root.view === "clip" && !root.clipboard.loading
        && (!!root.viewIt || (!!root.selItem && root.selItem.kind === "clip"))
    readonly property bool canClearClip: root.canEditClip && !root.clipboard.loading && root.clipCount > 0
    property string clipErr: ""
    property int clipAfter: -1
    property int viewAfter: -1
    Connections {
        target: root.clipboard
        ignoreUnknownSignals: true
        function onActionErrorChanged() { root.clipErr = root.clipboard.actionError }
        function onLoadingChanged() { if (!root.clipboard.loading) Qt.callLater(root.clipLanded) }
    }
    // the selection lands on the deleted clipping's neighbour; the viewer on the next picture, or closes when none is left
    function trashClip() {
        root.menuOpen = ""
        if (!root.canTrashClip) return
        var it = root.viewIt || root.selItem
        root.viewAfter = root.viewIt ? root.viewAt : -1
        root.clipAfter = root.grid.currentIndex
        root.clipboard.deleteById(it.clip.id)
    }
    function clipLanded() {
        var v = root.viewAfter, c = root.clipAfter
        root.viewAfter = -1
        root.clipAfter = -1
        if (root.view !== "clip") return
        if (v >= 0 && root.viewPics.length > 0) { root.openViewer(root.viewPics[Math.min(v, root.viewPics.length - 1)]); return }
        if (v >= 0) root.viewIt = null
        if (c >= 0 && root.grid.count > 0) root.jump(Math.min(c, root.grid.count - 1))
    }
    // the contextual menu: a right-press on a clipping or a picture selects it (the viewer closes) and opens its rows at the pointer
    property string ctxKind: ""
    property point ctxAt: Qt.point(0, 0)
    function openContext(cell, mx, my) {
        var k = cell.modelData.kind
        if (root.aboutOpen || root.alertOpen || (k !== "clip" && k !== "pic")) return
        root.viewIt = null
        cell.GridView.view.currentIndex = cell.index
        root.ctxKind = k
        var p = cell.mapToItem(mac, mx, my)
        root.ctxAt = Qt.point(Math.round(p.x), Math.round(p.y))
        root.keyMenu = false
        root.menuOpen = "Context"
    }
    function askClearClip() {
        if (!root.canClearClip) return
        root.menuOpen = ""
        root.alertKind = "clip"
        root.alertOpen = true
    }

    // a Platinum menu-bar title; its drop-down is a Drop at window level (below). A press opens it, a drag
    // across the titles moves the menu and a release over a live row runs that row; a click keeps it open.
    component MenuTitle: Item {
        id: mtl
        property string label: ""
        property url icon: ""
        property string caption: mtl.hasIcon ? "" : mtl.label
        property real maxText: 1000
        property bool live: true
        property bool wasOpen: false
        property bool moved: false
        readonly property bool open: root.menuOpen === mtl.label
        readonly property bool lit: mtl.open || (root.keyFocus === "bar" && root.menuOpen === "" && root.barTitle === mtl.label)
        readonly property bool hasIcon: mtl.icon.toString() !== ""
        width: mtl.caption === "" ? 22 : mt.x + mt.width + 5
        height: 17
        Rectangle { anchors.fill: parent; visible: mtl.lit; color: root.pl.sel }
        Image {
            visible: mtl.hasIcon
            x: 4; y: 1; width: 14; height: 16
            source: mtl.icon
            sourceSize: Qt.size(14, 16)
        }
        T {
            id: mt
            visible: mtl.caption !== ""
            x: mtl.hasIcon ? 21 : 5
            width: Math.min(implicitWidth, mtl.maxText)
            elide: implicitWidth > mtl.maxText ? Text.ElideRight : Text.ElideNone
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -1
            text: mtl.caption
            color: mtl.lit ? "#ffffff" : (mtl.live ? "#000000" : "#8a8a8a")
            font.family: root.fSys
            font.pixelSize: 12
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPressed: {
                mtl.wasOpen = mtl.open
                mtl.moved = false
                root.keyMenu = false
                if (!mtl.open && mtl.live) root.menuOpen = mtl.label
            }
            onPositionChanged: function (m) {
                if (!pressed) return
                mtl.moved = true
                var p = mapToItem(mac, m.x, m.y)
                var t = root.titleAt(p.x, p.y)
                if (t !== "") root.menuOpen = t
                root.hoverAt(p.x, p.y)
            }
            onReleased: function (m) {
                var p = mapToItem(mac, m.x, m.y)
                var row = root.rowAt(p.x, p.y)
                if (row) { root.menuOpen = ""; row.act() }
                else if (mtl.wasOpen && !mtl.moved) root.menuOpen = ""
                else if (mtl.moved && root.titleAt(p.x, p.y) === "") root.menuOpen = ""
            }
            onEntered: if (root.titles.indexOf(root.menuOpen) >= 0 && mtl.live) root.menuOpen = mtl.label
        }
    }

    // a Platinum drop-down, placed under its title at window level and above the dismiss shade
    component Drop: Rectangle {
        id: drop
        property var rows: []
        property int hot: -1
        width: 176
        height: dcol.height + 4
        color: root.pl.face
        border.width: 1
        border.color: root.pl.line
        onVisibleChanged: drop.hot = -1
        // a menu opened by keys keeps a live row hot when its rows change under it (an answer arriving)
        onRowsChanged: if (drop.visible && root.keyMenu && !(drop.hot >= 0 && drop.hot < drop.rows.length && drop.rows[drop.hot].live === true)) drop.hot = root.liveRow(drop, -1, 1)
        function indexAt(y) {
            var at = 2
            for (var i = 0; i < drop.rows.length; i++) {
                var h = drop.rows[i].sep ? 7 : 17
                if (y >= at && y < at + h) return drop.rows[i].sep ? -1 : i
                at += h
            }
            return -1
        }
        Column {
            id: dcol
            x: 2; y: 2
            width: drop.width - 4
            Repeater {
                model: drop.rows
                Item {
                    id: dr
                    required property var modelData
                    required property int index
                    readonly property bool hit: !dr.modelData.sep && dr.modelData.live === true
                    readonly property bool lit: dr.hit && drop.hot === dr.index
                    width: dcol.width
                    height: dr.modelData.sep ? 7 : 17
                    Rectangle { visible: !!dr.modelData.sep; x: 2; y: 3; width: dr.width - 4; height: 1; color: "#9a9a9a" }
                    Rectangle { visible: !!dr.modelData.sep; x: 2; y: 4; width: dr.width - 4; height: 1; color: root.pl.hi }
                    Rectangle { visible: dr.lit; anchors.fill: parent; color: root.pl.sel }
                    Image {
                        visible: !!dr.modelData.icon
                        x: 5
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16
                        source: dr.modelData.icon || ""
                        sourceSize: Qt.size(16, 16)
                        smooth: true
                        opacity: dr.hit ? 1 : 0.5
                    }
                    Svg {
                        visible: !!dr.modelData.check
                        x: 4; y: 6
                        d: "M0 3 L2.5 5.5 L7 0.5"
                        stroke: dr.lit ? "#ffffff" : "#000000"
                        sw: 1.6
                        cap: ShapePath.RoundCap
                    }
                    Rectangle {
                        visible: !!dr.modelData.ring
                        x: 4; y: 5; width: 7; height: 7; radius: 3.5
                        color: "transparent"
                        border.width: 1.2
                        border.color: dr.lit ? "#ffffff" : "#000000"
                    }
                    T {
                        visible: !dr.modelData.sep
                        x: dr.modelData.icon ? 26 : 16
                        width: dr.width - x - 6
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                        text: dr.modelData.label || ""
                        color: !dr.hit ? "#8a8a8a" : (dr.lit ? "#ffffff" : "#000000")
                        font.family: root.fSys
                        font.pixelSize: 12
                    }
                    T {
                        visible: !dr.modelData.sep && !!dr.modelData.key
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: dr.modelData.key || ""
                        color: !dr.hit ? "#8a8a8a" : (dr.lit ? "#ffffff" : "#000000")
                        font.family: root.fSys
                        font.pixelSize: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !dr.modelData.sep
                        hoverEnabled: true
                        onEntered: drop.hot = dr.index
                        onExited: if (drop.hot === dr.index) drop.hot = -1
                        onClicked: if (dr.hit) { root.menuOpen = ""; dr.modelData.act() }
                    }
                }
            }
        }
    }

    // a Platinum push button; dflt draws the heavy ring of the default button
    component PBtn: Item {
        id: pb
        property string label: ""
        property bool dflt: false
        property bool live: true
        property bool focused: false
        signal chosen()
        width: 64
        height: 20
        Rectangle {
            visible: pb.dflt || pb.focused
            x: -3; y: -3
            width: pb.width + 6; height: pb.height + 6
            radius: 6
            color: "transparent"
            border.width: 2
            border.color: pb.focused ? root.pl.sel : root.pl.line
        }
        Rectangle {
            anchors.fill: parent
            radius: 4
            color: ma.pressed ? "#bcbcbc" : root.pl.face
            border.width: 1
            border.color: pb.live ? root.pl.line : "#9a9a9a"
        }
        T {
            anchors.centerIn: parent
            text: pb.label
            color: pb.live ? "#000000" : "#8a8a8a"
            font.family: root.fSys
            font.pixelSize: 12
        }
        MouseArea { id: ma; anchors.fill: parent; enabled: pb.live; onClicked: pb.chosen() }
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
        property bool live: true
        readonly property color ink: bx.live ? root.pl.line : "#9a9a9a"
        signal clicked()
        width: 11
        height: 11
        Rectangle { anchors.fill: parent; color: root.pl.face; border.width: 1; border.color: root.pl.line }
        Rectangle { x: 1; y: 1; width: 9; height: 1; color: root.pl.hi }
        Rectangle { x: 1; y: 1; width: 1; height: 9; color: root.pl.hi }
        Rectangle { x: 2; y: 9; width: 8; height: 1; color: "#9a9a9a" }
        Rectangle { x: 9; y: 2; width: 1; height: 8; color: "#9a9a9a" }
        Repeater {
            model: bx.kind === 0 ? [[3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [7, 3], [6, 4], [4, 6], [3, 7]] : []
            Rectangle { required property var modelData; x: modelData[0]; y: modelData[1]; width: 1; height: 1; color: root.pl.line }
        }
        Rectangle { visible: bx.kind === 1; x: 2; y: 2; width: 7; height: 7; color: "transparent"; border.width: 1; border.color: root.pl.line }
        Rectangle { visible: bx.kind === 2; x: 5; y: 2; width: 1; height: 1; color: bx.ink }
        Rectangle { visible: bx.kind === 2; x: 4; y: 3; width: 3; height: 1; color: bx.ink }
        Rectangle { visible: bx.kind === 2; x: 3; y: 4; width: 5; height: 1; color: bx.ink }
        Rectangle { visible: bx.kind === 2; x: 5; y: 5; width: 1; height: 4; color: bx.ink }
        MouseArea { anchors.fill: parent; enabled: bx.visible; onClicked: if (bx.live) bx.clicked() }
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

    component Grow: Item {
        width: 14; height: 14
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
        function scrollTo(s) { sb.view.contentY = sb.view.originY + Math.max(0, Math.min(sb.total - sb.view.height, s)) }
        function scrollBy(d) { sb.scrollTo(sb.view.contentY - sb.view.originY + d) }
        Timer {
            id: rep
            interval: 350
            repeat: true
            running: ua.pressed || da.pressed
            onRunningChanged: rep.interval = 350
            onTriggered: { rep.interval = 50; sb.scrollBy((ua.pressed ? -1 : 1) * root.geom.ch) }
        }

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
            MouseArea { id: ua; anchors.fill: parent; enabled: sb.overflow; onPressed: sb.scrollBy(-root.geom.ch) }
        }
        Item {
            visible: sb.active
            x: 1; y: sb.colH - 28; width: 14; height: 14
            Bevel { anchors.fill: parent }
            Rectangle { y: 0; width: 14; height: 1; color: root.pl.line }
            Tri { x: 3; y: 4; up: false; tone: sb.overflow ? root.pl.line : "#9a9a9a" }
            MouseArea { id: da; anchors.fill: parent; enabled: sb.overflow; onPressed: sb.scrollBy(root.geom.ch) }
        }
        Grow { x: 1; y: sb.colH - 14 }
        MouseArea {
            id: trk
            x: 1; y: 15; width: 14; height: sb.trackH
            enabled: sb.active && sb.overflow
            property real grabY: -1
            onPressed: function (m) {
                var t = sb.thumbY - 15
                trk.grabY = m.y >= t && m.y < t + sb.thumbH ? m.y - t : -1
                if (trk.grabY < 0) sb.scrollBy(m.y < t ? -sb.view.height : sb.view.height)
            }
            onPositionChanged: function (m) {
                if (trk.grabY >= 0) sb.scrollTo((m.y - trk.grabY) / Math.max(1, sb.trackH - sb.thumbH) * (sb.total - sb.view.height))
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
        property bool scrolls: true
        property real baseW: 0
        property real baseH: 0
        property real fitW: 0
        property real growW: -1
        property real growH: -1
        property string opening: ""
        property real homeX: 0
        property real homeY: 0
        property real moveX: 0
        property real moveY: 0
        property var unzoom: null
        property bool canUp: false
        readonly property real maxW: mac.width - 16
        readonly property real maxH: mac.height - 32
        x: w.clampX(w.homeX + w.moveX)
        y: w.clampY(w.homeY + w.moveY)
        width: Math.max(0, Math.min(w.maxW, w.growW >= 0 ? w.growW : Math.max(w.baseW, w.fitW)))
        height: Math.max(0, Math.min(w.maxH, w.growH >= 0 ? w.growH : w.baseH))
        onOpeningChanged: { w.growW = -1; w.growH = -1; w.moveX = 0; w.moveY = 0; w.unzoom = null }
        default property alias body: bodyArea.data
        signal closeClicked()
        signal bodyClicked()
        signal upClicked()
        function clampX(v) { return Math.round(Math.max(8, Math.min(mac.width - 8 - w.width, v))) }
        function clampY(v) { return Math.round(Math.max(18, Math.min(mac.height - 14 - w.height, v))) }
        function zoom() {
            if (w.unzoom) {
                var u = w.unzoom
                w.unzoom = null
                w.moveX = u[0]; w.moveY = u[1]; w.growW = u[2]; w.growH = u[3]
                return
            }
            w.unzoom = [w.moveX, w.moveY, w.growW, w.growH]
            w.moveX = 8 - w.homeX; w.moveY = 18 - w.homeY; w.growW = w.maxW; w.growH = w.maxH
        }

        Rectangle { x: 2; y: 2; width: w.width; height: w.height; color: Qt.rgba(12 / 255, 33 / 255, 48 / 255, 0.2) }
        Rectangle { x: 1; y: 1; width: w.width; height: w.height; color: Qt.rgba(12 / 255, 33 / 255, 48 / 255, 0.55) }
        Rectangle { anchors.fill: parent; color: root.pl.face; border.width: 1; border.color: root.pl.line }
        MouseArea { anchors.fill: parent; onClicked: w.bodyClicked() }

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
                MouseArea {
                    id: tm
                    anchors.fill: parent
                    enabled: w.active
                    property real px: 0
                    property real py: 0
                    onPressed: function (m) {
                        var p = mapToItem(mac, m.x, m.y)
                        tm.px = p.x - w.x; tm.py = p.y - w.y
                    }
                    onPositionChanged: function (m) {
                        var p = mapToItem(mac, m.x, m.y)
                        w.moveX = w.clampX(p.x - tm.px) - w.homeX
                        w.moveY = w.clampY(p.y - tm.py) - w.homeY
                    }
                    onClicked: w.bodyClicked()
                }

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
                Box { x: 18 + tb.sw * 2 + 3 + tb.tw + 3 + 3; y: 3; kind: 1; visible: w.active; onClicked: w.zoom() }
                Box { x: 18 + tb.sw * 2 + 3 + tb.tw + 3 + 3 + 14; y: 3; kind: 2; visible: w.active; live: w.canUp; onClicked: w.upClicked() }
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
                width: inner.width - (w.scrolls ? 15 : 0)
                height: inner.height - 34
                color: "#ffffff"
                clip: true
                MouseArea { anchors.fill: parent; onClicked: w.bodyClicked() }
            }

            Sb { visible: w.scrolls; x: inner.width - 15; y: 34; height: inner.height - 34; view: w.view; active: w.active }
            Rectangle { visible: !w.scrolls; x: inner.width - 15; y: inner.height - 14; width: 1; height: 14; color: root.pl.line }
            Grow { visible: !w.scrolls; x: inner.width - 14; y: inner.height - 14 }
        }
        MouseArea {
            id: gb
            x: w.width - 16; y: w.height - 16; width: 15; height: 15
            enabled: w.active
            property real px: 0
            property real py: 0
            property real pw: 0
            property real ph: 0
            onPressed: function (m) {
                var p = mapToItem(mac, m.x, m.y)
                gb.px = p.x; gb.py = p.y; gb.pw = w.width; gb.ph = w.height
                w.moveX = w.x - w.homeX; w.moveY = w.y - w.homeY
            }
            onPositionChanged: function (m) {
                var p = mapToItem(mac, m.x, m.y)
                w.unzoom = null
                w.growW = Math.round(Math.max(w.baseW, Math.min(mac.width - 8 - w.x, gb.pw + p.x - gb.px)))
                w.growH = Math.round(Math.max(w.baseH, Math.min(mac.height - 14 - w.y, gb.ph + p.y - gb.py)))
            }
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
        readonly property bool pic: kind === "pic"
        readonly property bool bigRow: kind === "clip" && root.clipBig
        readonly property bool big: cell.bigRow && modelData.clip.kind === "image"
        readonly property string mark: kind === "rice" ? modelData.row.mark : ""
        readonly property bool dead: (kind === "rice" && !modelData.row.live) || (cell.pic && root.coverLocked)
        readonly property var fold: (cell.glyphOnly || cell.row) ? ({ text: "", lines: 0, cut: false })
            : cell.kaoLabel ? ({ text: cell.modelData.glyph, lines: 1, cut: false }) : root.clamp2(cell.modelData.name, cell.width - 8)
        readonly property bool truncated: cell.kaoLabel ? lbl.truncated : cell.fold.cut
        readonly property real anchorX: cell.row ? 6 + Math.min(kt.implicitWidth, 158) / 2 : cell.width / 2
        readonly property string iconUrl: {
            if (kind === "folder" || kind === "rice") return modelData.icon
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
        readonly property real labelY: cell.bigRow ? 92 : cell.pic ? 55 : cell.bigGlyph ? 41 : 37

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
            x: (cell.width - width) / 2
            y: cell.bigRow && !cell.big ? 29 : 3
            width: cell.big ? cell.width - 12 : cell.pic ? 66 : 32
            height: cell.big ? 84 : cell.pic ? 50 : 32
            opacity: cell.dead ? 0.45 : 1
            layer.enabled: cell.sel
            layer.effect: MultiEffect {
                colorization: 0.45
                colorizationColor: "#1ed9ff"
                brightness: -0.08
            }
            Image {
                visible: !cell.big || cell.thumb === ""
                anchors.centerIn: parent
                width: 32; height: 32
                source: cell.iconUrl
                sourceSize: Qt.size(32, 32)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }
            Rectangle {
                visible: cell.big && bigPic.status === Image.Ready
                x: Math.round((ic.width - bigPic.paintedWidth) / 2) - 1
                y: Math.round((ic.height - bigPic.paintedHeight) / 2) - 1
                width: Math.round(bigPic.paintedWidth) + 2
                height: Math.round(bigPic.paintedHeight) + 2
                color: "transparent"
                border.width: 1
                border.color: root.pl.line
            }
            Image {
                id: bigPic
                visible: cell.big
                anchors.fill: parent
                source: cell.big ? cell.thumb : ""
                sourceSize: Qt.size(2 * ic.width, 2 * ic.height)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }
            Image {
                visible: cell.thumb !== "" && !cell.big
                x: 9; y: 11; width: 14; height: 11
                source: cell.thumb
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                clip: true
            }
            Rectangle {
                visible: cell.pic
                anchors.fill: parent
                color: root.pl.face
                border.width: 1
                border.color: root.pl.line
                Loader {
                    x: 1; y: 1; width: 64; height: 48
                    active: cell.pic
                    Component.onCompleted: setSource(Kit.helper("CoverArt"), {
                        source: Qt.binding(function () { return cell.pic ? cell.modelData.url : "" }),
                        tile: Qt.binding(function () { return cell.pic && cell.modelData.tile }),
                        screenWidth: Qt.binding(function () { return root.screenW }),
                        cropWidth: 128
                    })
                }
                Rectangle {
                    visible: cell.pic && cell.modelData.path === root.coverPath
                    x: 56; y: 40; width: 12; height: 12
                    color: "#ffffff"
                    border.width: 1
                    border.color: root.pl.line
                    Svg { x: 2; y: 3; d: "M0 3 L2.5 5.5 L7 0.5"; stroke: "#000000"; sw: 1.6; cap: ShapePath.RoundCap }
                }
            }
            Rectangle {
                visible: cell.mark !== ""
                x: 22; y: 21; width: 12; height: 12
                color: "#ffffff"
                border.width: 1
                border.color: root.pl.line
                Svg { visible: cell.mark === "✓"; x: 2; y: 3; d: "M0 3 L2.5 5.5 L7 0.5"; stroke: "#000000"; sw: 1.6; cap: ShapePath.RoundCap }
                Rectangle { visible: cell.mark === "○"; x: 3; y: 3; width: 6; height: 6; radius: 3; color: "transparent"; border.width: 1.2; border.color: "#000000" }
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
            color: cell.sel ? "#ffffff" : (cell.dead ? "#8a8a8a" : "#000000")
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: function (m) { if (m.button === Qt.RightButton) root.openContext(cell, m.x, m.y) }
            onClicked: function (m) { if (m.button === Qt.LeftButton) cell.GridView.view.currentIndex = cell.index }
            onDoubleClicked: function (m) { if (m.button === Qt.LeftButton) root.activate(cell.modelData) }
        }
    }

    // a desktop icon; lit paints it selected (keys walk the desktop)
    component DeskIcon: Item {
        id: dk
        property url src: ""
        property string name: ""
        property bool lit: false
        readonly property int lw: Math.ceil(dn.implicitWidth) + 4
        width: 72
        height: 48
        Item {
            x: 20; width: 32; height: 32
            layer.enabled: dk.lit
            layer.effect: MultiEffect {
                colorization: 0.45
                colorizationColor: "#1ed9ff"
                brightness: -0.08
            }
            Image { anchors.fill: parent; source: dk.src; sourceSize: Qt.size(32, 32) }
        }
        Rectangle { x: Math.round((72 - dk.lw) / 2); y: 36; width: dk.lw; height: 11; color: dk.lit ? root.pl.sel : "#ffffff" }
        T { id: dn; x: Math.round((72 - dk.lw) / 2) + 2; y: 35; text: dk.name; color: dk.lit ? "#ffffff" : "#000000"; lineHeight: 11; lineHeightMode: Text.FixedHeight }
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
        MouseArea { anchors.fill: parent; onClicked: if (root.frontOpen) root.goUp() }

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
                    Loader {
                        anchors.fill: parent
                        visible: root.coverPath !== ""
                        Component.onCompleted: setSource(Kit.helper("CoverArt"), {
                            source: Qt.binding(function () { return root.coverPath !== "" ? "file://" + root.coverPath : "" }),
                            tile: Qt.binding(function () { return root.coverTile }),
                            screenWidth: Qt.binding(function () { return root.screenW }),
                            cropWidth: 836
                        })
                    }

                    DeskIcon {
                        anchors.right: parent.right; anchors.rightMargin: 4; y: 26
                        src: root.g3Dir + "finder-disk.svg" + root.bust
                        name: root.diskName
                        lit: root.keyFocus === "desk" && root.deskAt === 0
                        MouseArea { x: 14; width: 44; height: 46; onClicked: root.goTop() }
                    }
                    DeskIcon {
                        anchors.right: parent.right; anchors.rightMargin: 4; anchors.bottom: parent.bottom; anchors.bottomMargin: 10
                        src: root.g3Dir + (root.trashFull ? "finder-trash-full.svg" : "finder-trash.svg") + root.bust
                        name: "Trash"
                        lit: root.keyFocus === "desk" && root.deskAt === 1
                        MouseArea { x: 14; width: 44; height: 46; onDoubleClicked: root.openTrash() }
                    }

                    Win {
                        id: hdWin
                        homeX: 8; homeY: 26; baseW: 294; baseH: 170
                        opening: "" + root.shown
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
                            width: root.geoms.top.cols * root.geoms.top.cw
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
                        homeX: 20; homeY: 48; baseW: 282; baseH: 230
                        visible: root.inSub
                        active: false
                        title: root.curFolder ? root.curFolder.name : ""
                        proxy: root.curFolder ? root.curFolder.icon : ""
                        hdr: root.parentItems.length + " items"
                        onBodyClicked: root.goUp()
                    }

                    Win {
                        id: frontWin
                        homeX: root.inSub ? 34 : 20
                        homeY: root.inSub ? 66 : 48
                        baseW: 282
                        baseH: root.inSub ? 212 : root.view === "pics" ? 254 : 230
                        fitW: root.listed ? root.listWant : (root.view === "pics" ? 116 + posLbl.implicitWidth + 4 + root.posBoxW + 6 + 17 : 0)
                        opening: [root.shown, root.view, root.sub, root.searching].join("/")
                        readonly property real split: root.view === "keys" ? 10 + root.listCols[0] : frontWin.width - 22 - root.listCols[1]
                        visible: root.frontOpen
                        title: root.frontTitle
                        proxy: root.frontProxy
                        lens: root.searching
                        hdr: root.hdrText
                        view: root.listed ? root.listItem : frontGrid
                        canUp: root.canUp
                        onCloseClicked: root.goTop()
                        onUpClicked: root.goUp()
                        GridView {
                            id: frontGrid
                            x: 1; y: root.view === "pics" ? 52 : 0
                            width: root.geom.cols * root.geom.cw
                            height: parent.height - y
                            header: Item { width: 1; height: 4 }
                            footer: Item { width: 1; height: 4 }
                            cellWidth: root.geom.cw
                            cellHeight: root.geom.ch
                            boundsBehavior: Flickable.StopAtBounds
                            visible: !root.listed
                            model: root.frontOpen && !root.listed ? root.items : []
                            delegate: Cell {}
                            onModelChanged: {
                                if (root.view === "pics" && root.picSel !== "" && root.query === root.picQuery && count > 0) { currentIndex = root.picLanded(); root.reveal(frontGrid, currentIndex) }
                                else { currentIndex = 0; positionViewAtBeginning() }
                            }
                            onCurrentIndexChanged: Qt.callLater(root.notePic)
                        }
                        Rectangle {
                            visible: root.view === "pics"
                            width: parent.width
                            height: 52
                            color: root.pl.face
                            Rectangle { y: 51; width: parent.width; height: 1; color: root.pl.sh }
                            PBtn { x: 6; y: 4; width: 104; label: "Remove Picture"; live: root.canRemove; focused: root.bandFocus === "remove"; onChosen: root.removePicture() }
                            PBtn { id: addBtn; x: 6; y: 28; width: 104; label: "Add Pictures…"; live: root.canAddPics; focused: root.bandFocus === "add"; onChosen: root.addPictures() }
                            T {
                                id: posLbl
                                x: 116; y: 4; height: 20
                                verticalAlignment: Text.AlignVCenter
                                text: "Position:"
                                color: root.canPosition ? "#000000" : "#8a8a8a"
                                font.family: root.fSys
                                font.pixelSize: 12
                            }
                            Item {
                                id: posBox
                                x: 116 + posLbl.implicitWidth + 4; y: 4
                                width: root.posBoxW; height: 20
                                readonly property bool open: root.menuOpen === "Position"
                                Rectangle {
                                    visible: root.bandFocus === "position"
                                    x: -3; y: -3; width: posBox.width + 6; height: posBox.height + 6
                                    radius: 5
                                    color: "transparent"
                                    border.width: 2
                                    border.color: root.pl.sel
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: posBox.open ? "#bcbcbc" : root.pl.face
                                    border.width: 1
                                    border.color: root.canPosition ? root.pl.line : "#9a9a9a"
                                }
                                Rectangle { x: 1; y: 1; width: posBox.width - 19; height: 1; color: root.pl.hi }
                                Rectangle { x: 1; y: 1; width: 1; height: posBox.height - 2; color: root.pl.hi }
                                T {
                                    x: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (root.positions.filter(function (q) { return q[0] === root.coverPosition })[0] || root.positions[0])[1]
                                    color: root.canPosition ? "#000000" : "#8a8a8a"
                                    font.family: root.fSys
                                    font.pixelSize: 12
                                }
                                Rectangle { x: posBox.width - 17; y: 1; width: 1; height: posBox.height - 2; color: root.canPosition ? root.pl.line : "#9a9a9a" }
                                Tri { x: posBox.width - 13; y: 4; up: true; tone: root.canPosition ? root.pl.line : "#9a9a9a" }
                                Tri { x: posBox.width - 13; y: 11; up: false; tone: root.canPosition ? root.pl.line : "#9a9a9a" }
                                MouseArea { anchors.fill: parent; enabled: root.canPosition; onPressed: root.openPosition(false) }
                            }
                        }
                        Rectangle {
                            visible: root.listed
                            x: 0; y: 0
                            width: parent.width
                            height: 15
                            color: root.pl.hdr
                            Rectangle { y: 14; width: parent.width; height: 1; color: root.pl.sh }
                            Rectangle { x: frontWin.split - 4; y: 2; width: 1; height: 11; color: root.pl.sh }
                            T { x: root.view === "keys" ? 6 : 24; y: 1; text: root.view === "keys" ? "Keys" : "Name" }
                            T { x: frontWin.split + 2; y: 1; text: root.view === "keys" ? "Action" : "Date Deleted" }
                        }
                        ListView {
                            id: trashList
                            visible: root.view === "trash"
                            x: 0; y: 15
                            width: parent.width
                            height: parent.height - 15
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.view === "trash" ? root.items : []
                            delegate: Item {
                                id: trow
                                required property var modelData
                                required property int index
                                readonly property bool sel: ListView.isCurrentItem
                                width: trashList.width
                                height: Math.max(root.geom.ch, Math.ceil(Math.max(tn.implicitHeight, td.implicitHeight)) + 4)
                                Rectangle { anchors.fill: parent; visible: trow.sel; color: root.pl.sel }
                                Image { x: 4; anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; source: trow.modelData.icon; sourceSize: Qt.size(16, 16); smooth: true }
                                T {
                                    id: tn
                                    x: 24; width: frontWin.split - 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: trow.modelData.label || ""
                                    wrapMode: Text.Wrap
                                    color: trow.sel ? "#ffffff" : "#000000"
                                }
                                T {
                                    id: td
                                    x: frontWin.split; width: trashList.width - 5 - frontWin.split
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: trow.modelData.when || ""
                                    wrapMode: Text.Wrap
                                    color: trow.sel ? "#ffffff" : "#000000"
                                }
                                MouseArea { anchors.fill: parent; onClicked: trashList.currentIndex = trow.index }
                            }
                            onModelChanged: { currentIndex = 0; positionViewAtBeginning() }
                        }
                        ListView {
                            id: keysList
                            visible: root.view === "keys"
                            x: 0; y: 15
                            width: parent.width
                            height: parent.height - 15
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: root.view === "keys" ? root.items : []
                            section.property: "group"
                            section.criteria: ViewSection.FullString
                            section.delegate: Rectangle {
                                required property string section
                                width: keysList.width
                                height: 15
                                color: root.pl.hdr
                                Rectangle { y: 14; width: parent.width; height: 1; color: root.pl.sh }
                                T { x: 4; y: 1; text: section; font.bold: true }
                            }
                            delegate: Item {
                                id: krow
                                required property var modelData
                                required property int index
                                readonly property bool sel: ListView.isCurrentItem
                                width: keysList.width
                                height: Math.max(root.geom.ch, Math.ceil(Math.max(kk.implicitHeight, kl.implicitHeight)) + 4)
                                Rectangle { anchors.fill: parent; visible: krow.sel; color: root.pl.sel }
                                T {
                                    id: kk
                                    x: 6; width: frontWin.split - 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: krow.modelData.keys || ""
                                    wrapMode: Text.Wrap
                                    color: krow.sel ? "#ffffff" : "#000000"
                                }
                                T {
                                    id: kl
                                    x: frontWin.split; width: keysList.width - 5 - frontWin.split
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: krow.modelData.label || ""
                                    wrapMode: Text.Wrap
                                    color: krow.sel ? "#ffffff" : "#000000"
                                }
                                MouseArea { anchors.fill: parent; onClicked: keysList.currentIndex = krow.index }
                            }
                            onModelChanged: { currentIndex = 0; positionViewAtBeginning() }
                        }
                        T {
                            visible: root.frontOpen && root.items.length === 0
                            x: 8; y: 54
                            width: parent.width - 16
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            text: root.emptyText
                            color: "#6a6a6a"
                        }
                    }

                    Rectangle {
                        x: 0; y: 0; width: parent.width; height: 18; z: 40
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#f4f4f4" }
                            GradientStop { position: 1; color: "#dadada" }
                        }
                        Rectangle { y: 17; width: parent.width; height: 1; color: root.pl.line }
                        MenuTitle { id: appleTitle; x: 52; label: "♪"; icon: root.g3Dir + "finder-note.svg" + root.bust }
                        Row {
                            id: barRow
                            x: 74
                            MenuTitle { id: fileTitle; label: "File" }
                            MenuTitle { id: editTitle; label: "Edit" }
                            MenuTitle { id: viewTitle; label: "View" }
                            MenuTitle { id: specialTitle; label: "Special" }
                            MenuTitle { id: helpTitle; label: "Help" }
                        }
                        MenuTitle {
                            id: songTitle
                            anchors.right: parent.right; anchors.rightMargin: 16
                            label: "Song"
                            icon: root.g3Dir + "finder-song.svg" + root.bust
                            caption: root.pending ? "…" : root.livery.songName
                            maxText: parent.width - 16 - (findBox.x + findBox.width + 6) - 26
                            live: !root.pending
                        }
                        Item {
                            id: findBox
                            x: barRow.x + barRow.width + 6; y: 2; width: 62; height: 14
                            Rectangle { anchors.fill: parent; color: "#ffffff" }
                            Rectangle { x: 0; y: 0; width: findBox.width; height: 1; color: "#5c5c5c" }
                            Rectangle { x: 0; y: 0; width: 1; height: 14; color: "#5c5c5c" }
                            Rectangle { x: 1; y: 13; width: findBox.width - 1; height: 1; color: "#d0d0d0" }
                            Rectangle { x: findBox.width - 1; y: 1; width: 1; height: 13; color: "#d0d0d0" }
                            Rectangle { x: 1; y: 1; width: findBox.width - 2; height: 1; color: "#a8a8a8" }
                            Rectangle { x: 1; y: 1; width: 1; height: 12; color: "#a8a8a8" }
                            Lens { x: 4; y: 3 }
                            TextInput {
                                id: findField
                                readOnly: root.aboutOpen
                                x: 16; y: 1
                                width: findBox.width - 20
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
                                    visible: root.keyFocus === "grid"
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
                            && (balloon.it.kind === "emoji" || balloon.kao || (balloon.it.kind === "clip" && balloon.it.clip.kind === "text" && balloon.ci.truncated) || (balloon.it.kind === "pic" && balloon.ci.truncated))
                        readonly property bool emojiOnly: !!balloon.it && balloon.it.kind === "emoji" && !root.searching
                        readonly property real cx: frontWin.x + 2 + (frontGrid.currentIndex % root.geom.cols) * root.geom.cw + (balloon.ci ? balloon.ci.anchorX : root.geom.cw / 2)
                        readonly property real cellTop: frontWin.y + 1 + 34 + frontGrid.y + Math.floor(frontGrid.currentIndex / root.geom.cols) * root.geom.ch - frontGrid.contentY
                        readonly property real below: balloon.cellTop + (balloon.emojiOnly ? 32 : (balloon.kao && !root.searching ? root.geom.ch : root.geom.ch + 2)) + 9
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
                    Drop {
                        id: appleDrop
                        visible: root.menuOpen === "♪"
                        x: appleTitle.x; y: 18; z: 41
                        rows: [
                            { label: "About This Computer…", live: true, act: root.openAbout },
                            { sep: true },
                            { label: "Applications", icon: root.menuIcons.apps, live: true, act: function () { root.openFolder("apps") } },
                            { label: "Clipboard", icon: root.menuIcons.clip, live: true, act: function () { root.openFolder("clip") } },
                            { label: "Desktop Pictures…", icon: root.menuIcons.pics, live: true, act: function () { root.openFolder("pics") } },
                            { label: "Emoji", icon: root.menuIcons.emoji, live: true, act: function () { root.openFolder("emoji") } },
                            { label: "Kaomoji", icon: root.menuIcons.kaomoji, live: true, act: function () { root.openFolder("kaomoji") } },
                            { label: "Trash", icon: root.menuIcons.trash, live: true, act: function () { root.openTrash() } }
                        ]
                    }
                    Drop {
                        id: fileDrop
                        visible: root.menuOpen === "File"
                        x: barRow.x + fileTitle.x; y: 18; z: 41
                        rows: [
                            { label: "Open", key: "⌘O", live: root.canOpen, act: root.openSel },
                            { label: "Delete Clipping", key: "⌘⌫", live: root.canTrashClip, act: root.trashClip },
                            { label: "Move to Trash", live: root.canTrashPic, act: root.trashPicture },
                            { label: "Add Pictures…", live: root.canAddPics, act: root.addPictures },
                            { label: "Close Window", key: "⌘W", live: root.frontOpen || root.aboutOpen, act: root.closeWindow },
                            { sep: true },
                            { label: "Find…", key: "⌘F", live: !root.aboutOpen, act: root.focusFind },
                            { sep: true },
                            { label: "Put Away", key: "⌘Y", live: root.canPutAway, act: root.putAway },
                            { sep: true },
                            { label: "Save as Draft", live: root.canMenu && Rice.saveDraft(root.riceMode).live && !root.pending, act: function () { root.riceAct(Rice.saveDraft(root.riceMode)) } }
                        ]
                    }
                    Drop {
                        id: editDrop
                        visible: root.menuOpen === "Edit"
                        x: barRow.x + editTitle.x; y: 18; z: 41
                        rows: [
                            { label: "Copy", key: "⌘C", live: root.canCopy, act: root.copyPick },
                            { label: "Paste", key: "⌘V", live: root.canPaste, act: root.pasteText },
                            { label: "Clear", live: !root.aboutOpen && findField.text !== "", act: root.clearFind },
                            { sep: true },
                            { label: "Show Clipboard", live: true, act: function () { root.openFolder("clip") } }
                        ]
                    }
                    Drop {
                        id: viewDrop
                        visible: root.menuOpen === "View"
                        x: barRow.x + viewTitle.x; y: 18; z: 41
                        rows: [
                            { label: "by Name", check: root.sortBy === "name", live: root.sortable && !root.aboutOpen, act: function () { root.setSort("name") } },
                            { label: "by Kind", check: root.sortBy === "kind", live: root.sortable && !root.aboutOpen, act: function () { root.setSort("kind") } },
                            { label: "by Date", check: root.sortBy === "date", live: root.sortable && root.dated && !root.aboutOpen, act: function () { root.setSort("date") } }
                        ]
                    }
                    Drop {
                        id: specialDrop
                        visible: root.menuOpen === "Special"
                        x: barRow.x + specialTitle.x; y: 18; z: 41
                        rows: [
                            { label: "Empty Trash…", live: root.canEmpty, act: root.askEmpty },
                            { label: "Clear Clipboard History…", live: root.canClearClip, act: root.askClearClip },
                            { sep: true },
                            { label: "Sleep", live: true, act: root.sleepNow },
                            { label: "Restart…", live: true, act: function () { root.askPower("reboot") } },
                            { label: "Shut Down…", live: true, act: function () { root.askPower("shutdown") } },
                            { label: "Log Out…", live: true, act: function () { root.askPower("logout") } }
                        ]
                    }
                    Drop {
                        id: helpDrop
                        visible: root.menuOpen === "Help"
                        x: barRow.x + helpTitle.x; y: 18; z: 41
                        rows: [
                            { label: "Keyboard Shortcuts…", live: true, act: root.openKeys }
                        ]
                    }
                    Drop {
                        id: songDrop
                        visible: root.menuOpen === "Song"
                        x: songTitle.x + songTitle.width - songDrop.width; y: 18; z: 41
                        width: Math.min(songTitle.x + songTitle.width - 4, Math.max(176, 26 + Math.ceil(songFit.implicitWidth)))
                        rows: root.songRows
                        T { id: songFit; visible: false; font.family: root.fSys; font.pixelSize: 12; text: root.songRows.map(function (r) { return r.sep ? "" : r.label }).join("\n") }
                    }
                    Drop {
                        id: posDrop
                        visible: root.menuOpen === "Position"
                        z: 41
                        width: root.posBoxW
                        rows: root.positions.map(function (q) {
                            return { label: q[1], check: root.coverPosition === q[0], live: true, act: function () { root.setPosition(q[0]) } }
                        })
                    }
                    Drop {
                        id: ctxDrop
                        visible: root.menuOpen === "Context"
                        x: Math.max(0, Math.min(mac.width - ctxDrop.width, root.ctxAt.x))
                        y: Math.max(0, Math.min(mac.height - ctxDrop.height, root.ctxAt.y))
                        z: 41
                        width: Math.max(120, 16 + Math.ceil(ctxFit.implicitWidth) + 14)
                        rows: root.ctxKind === "clip" ? [
                            { label: "Open", live: root.canOpen, act: root.openSel },
                            { label: "Copy", live: root.canCopy && !!root.selItem && root.selItem.kind === "clip", act: function () { root.clipboard.copyById(root.selItem.clip.id) } },
                            { sep: true },
                            { label: "Delete Clipping", live: root.canTrashClip, act: root.trashClip }
                        ] : [
                            { label: "Open", live: root.canOpen, act: root.openSel },
                            { sep: true },
                            { label: "Remove Picture", live: root.canRemove && !!root.selItem && root.selItem.path === root.coverPath, act: root.removePicture },
                            { label: "Move to Trash", live: root.canTrashPic, act: root.trashPicture }
                        ]
                        T { id: ctxFit; visible: false; font.family: root.fSys; font.pixelSize: 12; text: ctxDrop.rows.map(function (r) { return r.sep ? "" : r.label }).join("\n") }
                    }
                    Win {
                        id: viewWin
                        homeX: 30; homeY: 26; z: 19
                        baseW: 340; baseH: 266
                        opening: "" + !!root.viewIt
                        visible: !!root.viewIt
                        title: root.viewIt ? root.viewIt.name : ""
                        proxy: root.g3Dir + "finder-clip-picture.svg" + root.bust
                        hdr: root.viewAt >= 0 ? (root.viewAt + 1) + " of " + root.viewPics.length : ""
                        scrolls: false
                        onCloseClicked: root.viewIt = null
                        readonly property string src: root.viewState && root.viewState.state === "ready" ? root.viewState.source : ""
                        Item {
                            id: viewArea
                            x: 8; y: 8
                            width: viewWin.width - 2 - 16
                            height: viewWin.height - 2 - 34 - 8 - 34 - 8
                            Rectangle {
                                visible: viewPic.status === Image.Ready
                                x: Math.round((viewArea.width - viewPic.paintedWidth) / 2) - 1
                                y: Math.round((viewArea.height - viewPic.paintedHeight) / 2) - 1
                                width: Math.round(viewPic.paintedWidth) + 2
                                height: Math.round(viewPic.paintedHeight) + 2
                                color: "transparent"
                                border.width: 1
                                border.color: root.pl.line
                            }
                            Image {
                                id: viewPic
                                anchors.fill: parent
                                source: viewWin.src
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                mipmap: true
                            }
                            T {
                                visible: viewPic.status !== Image.Ready
                                anchors.centerIn: parent
                                text: root.viewState && root.viewState.state === "error" ? "Can\u2019t show this picture" : "Reading picture\u2026"
                                color: "#6a6a6a"
                            }
                        }
                        Rectangle {
                            y: viewWin.height - 2 - 34 - 34
                            width: viewWin.width - 2
                            height: 34
                            color: root.pl.face
                            Rectangle { width: parent.width; height: 1; color: root.pl.sh }
                            PBtn { x: parent.width - 22 - 64 - 12 - 64; y: 8; label: "Close"; onChosen: root.viewIt = null }
                            PBtn { x: parent.width - 22 - 64; y: 8; label: "Copy"; dflt: true; onChosen: root.viewerCopy() }
                        }
                    }
                    Win {
                        id: aboutWin
                        homeX: 56; homeY: 44; z: 20
                        baseW: 300; baseH: 200
                        fitW: 146 + root.widest(aboutWin.rows, "v", 154)
                        opening: "" + root.aboutOpen
                        readonly property var rows: [
                            { k: "Computer", v: root.diskName },
                            { k: "User", v: Quickshell.env("USER") || "" },
                            { k: "System", v: root.osName },
                            { k: "Kernel", v: root.kernel },
                            { k: "Uptime", v: root.uptimeText() }
                        ]
                        visible: root.aboutOpen
                        title: "About This Computer"
                        scrolls: false
                        proxy: root.g3Dir + "finder-note.svg" + root.bust
                        onCloseClicked: root.aboutOpen = false
                        Image { x: 14; y: 12; width: 32; height: 32; source: root.g3Dir + "finder-disk.svg" + root.bust; sourceSize: Qt.size(32, 32) }
                        Column {
                            id: aboutCol
                            x: 58; y: 12
                            spacing: 1
                            Repeater {
                                model: aboutWin.rows
                                delegate: Item {
                                    id: arow
                                    required property var modelData
                                    width: 66 + av.width
                                    height: Math.max(13, Math.ceil(av.implicitHeight))
                                    T { x: 0; width: 60; horizontalAlignment: Text.AlignRight; text: arow.modelData.k + ":" }
                                    T { id: av; x: 66; width: aboutWin.width - 146; wrapMode: Text.Wrap; text: arow.modelData.v }
                                }
                            }
                        }
                        Rectangle {
                            id: memBar
                            x: 14; y: aboutCol.y + aboutCol.height + 19; width: 262; height: 12
                            color: "#ffffff"
                            border.width: 1
                            border.color: root.pl.line
                            Rectangle { x: 1; y: 1; width: Math.round(260 * root.memUsed); height: 10; color: root.pl.sel }
                        }
                        T { x: 14; y: memBar.y + 18; width: 262; text: root.memText }
                    }
                    MouseArea {
                        anchors.fill: parent
                        z: 30
                        visible: root.menuOpen !== ""
                        acceptedButtons: Qt.AllButtons
                        onClicked: root.menuOpen = ""
                    }
                    Item {
                        id: alertLayer
                        anchors.fill: parent
                        z: 42
                        visible: root.alertOpen
                        MouseArea { anchors.fill: parent }
                        Rectangle {
                            id: alertBox
                            width: 276; height: 120
                            x: Math.round((parent.width - width) / 2)
                            y: 74
                            color: root.pl.face
                            border.width: 1
                            border.color: root.pl.line
                            Image { x: 16; y: 16; width: 32; height: 32; source: root.g3Dir + "finder-caution.svg" + root.bust; sourceSize: Qt.size(32, 32) }
                            T {
                                x: 60; y: 16
                                width: 200
                                wrapMode: Text.WordWrap
                                text: root.alertText
                                font.family: root.fSys
                                font.pixelSize: 12
                                lineHeight: 14
                                lineHeightMode: Text.FixedHeight
                            }
                            PBtn { x: 122; y: 88; label: "Cancel"; dflt: true; onChosen: root.alertCancel() }
                            PBtn { x: 196; y: 88; label: root.alertKind === "clip" ? "Clear" : "OK"; onChosen: root.alertOk() }
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
        // any press puts the keys back on the grid, then goes on to whatever is under it
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: function (m) { root.keyFocus = "grid"; m.accepted = false } }
    }
}
