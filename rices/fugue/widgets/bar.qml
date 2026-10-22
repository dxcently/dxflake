// bar.qml -- fugue's "bar" slot: the always-visible strip, hosted by
// WidgetSlot (shell.qml's barWin PanelWindow reads this item's own
// implicitHeight back for its own height/exclusiveZone -- CONTRACTS.md
// section 5, "the song fully owns its own footprint").
//
// design/intent.md's grammar: strict counterpoint, a fixed lattice, every
// element a cell -- nothing ornamental. Where sonata's bar is a staff full
// of note glyphs, fugue's bar is a row of Cell instances (Cell.qml, this
// song's own uppercase helper), each one a flat rectangle with a 1px
// hairline trailing edge and, when live, a 2px rule instead of a glow.
//
// Same KINDS of information sonata's bar carries, a minimal set:
//   workspaces (Quickshell.Hyprland, no shell-out) -- live activate()
//   mode       (the shared `ricemode` slot, embedded below; fugue's own
//               ricemode.qml dresses it -- a left click toggles, a right or
//               middle click opens the draft picker)
//   net        (a readout: /proc/net/route via FileView, no backing
//               action exists to toggle a NIC from here, so no button)
//   sessions   (state/stage/sessions.json + hooks.json via FileView --
//               click opens the injected dock, the same capability
//               sonata's session-count cell exposes)
//   clock      (a readout, QtQuick Date/Timer, no shell-out)
//   pwr        ("[pwr]" -- design/intent.md lines 53-55: the bar's power
//               cell calls the injected powermenu instance's toggle
//               directly, the live proof of the baseline-fallback chain)
//
// No Process, no execDetached, no shelling out to any binary from this
// file (hard constraint) -- every reading here is either a Quickshell
// service object (Hyprland) or a plain file read (FileView / procfs).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
// The shell's WidgetSlot, for the embedded `ricemode` slot. This file lands at
// $out/qml/songs/fugue/bar.qml, so two levels up is the shell's own qml/ root
// (sonata's bar.qml reaches it the same way).
import "../.."

Item {
    id: root

    // -- Injected props -- exactly what shell.qml's barSlot hands over ------
    // (shell.qml lines ~122-143: WidgetSlot { slot: "bar" } always carries
    // theme + bridge, plus extraProps { shared, stagingEngine }).
    // stagingEngine is handed on to the embedded `ricemode`
    // slot; shared is declared because it is unconditionally injected --
    // unused here, same precedent WidgetSlot.qml itself documents for bridge
    // on its own fallback path.
    required property var theme
    required property var bridge
    required property var shared
    required property var stagingEngine

    // WidgetSlot sizes ITSELF off this item's implicitWidth/Height (an
    // Item's implicitWidth otherwise defaults to 0, or to its children's
    // extent) -- exactly backwards for a whole-width surface like the bar,
    // and nothing anchors this Item to the window's real width on its own.
    // Binding implicitWidth to parent.width would be a loop (WidgetSlot's
    // own width already reads off implicitWidth): bind width directly
    // instead, the same fix sonata's bar.qml carries for the identical
    // hazard.
    width: parent ? parent.width : implicitWidth
    implicitWidth: parent ? parent.width : 0
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: root.theme.barBg
    }

    // -- Workspaces -- one Cell per live Hyprland workspace, sorted by id ---
    readonly property var wsList: {
        var vs = (Hyprland.workspaces && Hyprland.workspaces.values)
                 ? Hyprland.workspaces.values.slice() : []
        vs.sort(function (a, b) { return (a.id || 0) - (b.id || 0) })
        return vs
    }

    Row {
        id: wsRow
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Repeater {
            model: root.wsList
            delegate: Cell {
                id: wsCell
                required property var modelData
                theme: root.theme
                paper: root.theme.barBg
                ink: root.theme.barFg
                // paletteHot -- "the one-hot trace": exactly one workspace
                // is ever active at a time, the literal one-hot case.
                tone: root.theme.paletteHot
                value: "" + (modelData ? (modelData.id || "") : "")
                active: modelData ? (modelData.active || modelData.focused) : false
                urgent: modelData ? !!modelData.urgent : false
                interactive: true
                onActivated: if (wsCell.modelData && wsCell.modelData.activate)
                                 wsCell.modelData.activate()
            }
        }
    }

    // -- Network -- /proc/net/route via FileView (files, not processes) -----
    property string netKind: "down"
    function parseRoute(text) {
        if (!text) return "down"
        var lines = ("" + text).split("\n")
        for (var i = 1; i < lines.length; i++) {
            var parts = lines[i].trim().split(/\s+/)
            if (parts.length < 2) continue
            if (parts[1] === "00000000") {
                var n = parts[0].toLowerCase()
                if (n.indexOf("wl") === 0) return "wifi"
                return "eth"
            }
        }
        return "down"
    }
    FileView {
        id: routeFile
        path: "/proc/net/route"
        onTextChanged: root.netKind = root.parseRoute(routeFile.text())
        Component.onCompleted: routeFile.reload()
    }
    Timer { interval: 5000; repeat: true; running: true; onTriggered: routeFile.reload() }

    // -- Agent sessions -- state/stage/sessions.json + hooks.json -----------
    // CONDUCTING files (CONTRACTS.md section 4) -- state/stage/, not
    // song/stage/.
    property int sessionCount: 0
    property bool sessionsBlocked: false
    property bool hooksBlocked: false
    readonly property bool anyBlocked: sessionsBlocked || hooksBlocked
    function anyStateBlocked(arr, key) {
        if (!arr) return false
        for (var i = 0; i < arr.length; i++) {
            var v = arr[i] ? ("" + (arr[i][key] || "")).toLowerCase() : ""
            if (v.indexOf("block") !== -1) return true
        }
        return false
    }
    FileView {
        id: sessionsFile
        path: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/state/stage/sessions.json"
        watchChanges: true
        onFileChanged: sessionsFile.reload()
        onTextChanged: {
            try {
                var d = JSON.parse(sessionsFile.text())
                var arr = (d && d.sessions) ? d.sessions : []
                root.sessionCount = arr.length
                root.sessionsBlocked = root.anyStateBlocked(arr, "state")
            } catch (e) { /* absent/garbage -- hold count */ }
        }
        Component.onCompleted: sessionsFile.reload()
    }
    FileView {
        id: hooksFile
        path: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/state/stage/hooks.json"
        watchChanges: true
        onFileChanged: hooksFile.reload()
        onTextChanged: {
            try {
                var d = JSON.parse(hooksFile.text())
                root.hooksBlocked = root.anyStateBlocked(d && d.hooks, "phase")
            } catch (e) { /* absent/garbage -- hold */ }
        }
        Component.onCompleted: hooksFile.reload()
    }

    // -- Clock -- QtQuick Date/Timer, no shell-out ---------------------------
    property var now: new Date()
    Timer { interval: 1000; repeat: true; running: true; onTriggered: root.now = new Date() }

    // -- Right-hand cells -------------------------------------------------
    Row {
        id: rightRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        // Rice mode -- the shared `ricemode` slot; fugue's ricemode.qml carries
        // the cell, the gestures and the draft picker.
        WidgetSlot {
            theme: root.theme
            bridge: root.bridge
            stagingEngine: root.stagingEngine
            slot: "ricemode"
            anchors.verticalCenter: parent.verticalCenter
        }
        Cell {
            theme: root.theme
            paper: root.theme.barBg
            ink: root.theme.barFg
            label: "net"
            value: root.netKind
            // a readout: no backing action exists to toggle a NIC here
            interactive: false
        }
        Cell {
            theme: root.theme
            paper: root.theme.barBg
            ink: root.theme.barFg
            label: "ses"
            value: "" + root.sessionCount
            urgent: root.anyBlocked
            interactive: true
            onActivated: root.bridge.component("dock", "toggle")
        }
        Cell {
            theme: root.theme
            paper: root.theme.barBg
            ink: root.theme.barFg
            value: Qt.formatDateTime(root.now, "hh.mm")
            interactive: false
        }
        Cell {
            theme: root.theme
            paper: root.theme.barBg
            ink: root.theme.barFg
            value: "[pwr]"
            interactive: true
            onActivated: root.bridge.component("powermenu", "toggle")
        }
    }
}
