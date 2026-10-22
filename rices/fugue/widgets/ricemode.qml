// ricemode.qml -- fugue's "ricemode" slot: the `mode` cell and its menu,
// hosted by bar.qml's WidgetSlot as the first cell of the right row
// (checks.bar-ricemode fails a bar that does not embed it).
//
// The look is fugue's: Cell instances on the lattice, a flat plate, a 2px rule
// for what is live, no ornament. The contract is the one every `ricemode`
// body keeps (sonata's is the floor), through the same bridge verbs. Left,
// right and middle click all do one thing: open the menu, or close it. The
// cell never switches; nothing changes until a row is chosen.
// bridge.riceMenu(cb) fills the plate, top to bottom:
//   songs                  the runtime songbook; a row sends
//                          bridge.riceMode("stage", name). A song that does not
//                          load is a dim row that does nothing
//   declarative · <song>   sends bridge.riceMode("declarative")
//   drafts · <song>        the staged song's drafts, a row sends
//                          bridge.riceDraft("enter", name); the two fixed rows
//                          send ("new") and ("save"); `save` is offered in
//                          staging only (in draft mode writes already land in
//                          the draft, in declarative nothing is unsaved)
// What is live wears the 2px accent rule: the song staged now, the declarative
// row while it is locked, the current draft. The last-staged song while locked
// wears a 1px rule at half strength. The marked rows only close the menu. In
// draft mode the drafted song's row is live: it leaves the draft for plain
// staging.
// A stage, a declarative, an enter and a new each change what is live, so the
// word reads `...` and every click is swallowed until theme.riceMode, the
// draft name or the song changes, or 10s pass: the double click that sent two
// switches. A `save` changes nothing and holds nothing.
//
// The menu is marked by a narrow cell after `mode`, holding a drawn chevron
// (two 1px rules, never a glyph: nothing on this lattice relies on a glyph
// nobody has seen render), so it is on screen at rest. The two cells are one
// control: a click on either opens the menu. A bridge without `riceMenu` has no
// menu and no chevron cell, and the cells stay inert.
//
// The menu is a PopupWindow made on open and destroyed on close, so no hover
// state carries into the next open. It closes on a row action, on any click on
// the cells, and 600ms after the pointer is over neither the cells nor the
// popup. No text input, so no keyboard and no focus grab: the CLI mints a new
// draft's name. Every string that came over the bridge is painted PlainText,
// which is why its rows are not Cell instances (Cell's Text is AutoText).
//
// Cell is fugue's own uppercase helper, resolved by type name through the
// qmldir the build writes beside this file (bar.qml and notifications.qml do the same).
import QtQuick
import Quickshell

Item {
    id: root

    required property var theme
    required property var bridge

    function modeWord(m) {
        if (m === "staging") return "stage"
        if (m === "draft") return "draft"
        return "decl"
    }

    readonly property string mode: root.theme.riceMode
    readonly property string draft: (root.theme.modeRaw && root.theme.modeRaw.draft) || ""
    readonly property string song: root.theme.riceName
    readonly property bool canMenu: !!root.bridge && typeof root.bridge.riceMenu === "function"

    property bool pending: false       // a mode change was sent and has not landed
    property bool open: false          // the menu
    property var answer: null          // the last riceMenu reply, null while asking
    property int asked: 0              // which ask a reply belongs to
    property Item hotRow: null         // the menu row under the pointer
    readonly property bool ready: !!root.answer && root.answer.ok === true
    readonly property var songs: root.ready && Array.isArray(root.answer.songs) ? root.answer.songs : []
    readonly property var drafts: root.ready && Array.isArray(root.answer.drafts) ? root.answer.drafts : []

    onModeChanged: root.pending = false
    onDraftChanged: root.pending = false
    onSongChanged: root.pending = false
    Timer { interval: 10000; running: root.pending; onTriggered: root.pending = false }

    function gesture() {
        if (root.pending || !root.canMenu) return
        if (root.open) {
            root.open = false
            return
        }
        root.answer = null
        var ask = ++root.asked
        root.open = true
        root.bridge.riceMenu(function (reply) { if (ask === root.asked) root.answer = reply })
    }

    // `save` never changes what is live; the rest do.
    function act(kind, name) {
        root.open = false
        if (kind !== "save") root.pending = true
        if (kind === "stage") root.bridge.riceMode("stage", name)
        else if (kind === "declarative") root.bridge.riceMode("declarative")
        else root.bridge.riceDraft(kind, name)
    }

    // -- The cells -----------------------------------------------------------
    // Pending reads `...` padded to the word it replaces, so nothing moves.
    implicitWidth: cells.implicitWidth
    implicitHeight: cells.implicitHeight
    opacity: root.pending ? 0.55 : 1.0

    Row {
        id: cells
        spacing: 0

        Cell {
            id: modeCell
            theme: root.theme
            paper: root.theme.barBg
            ink: root.theme.barFg
            label: "mode"
            value: root.pending
                   ? "..." + " ".repeat(root.modeWord(root.mode).length - 3)
                   : root.modeWord(root.mode)
            active: root.mode === "staging"
            interactive: true
            onActivated: root.gesture()
        }
        Cell {
            id: pickCell
            visible: root.canMenu
            theme: root.theme
            paper: root.theme.barBg
            ink: root.theme.barFg
            interactive: true
            onActivated: root.gesture()

            // The mark: a 7x4 chevron of two 1px rules meeting at the bottom.
            Item {
                anchors.centerIn: parent
                width: 7
                height: 4
                Repeater {
                    model: [40.6, -40.6]
                    Rectangle {
                        required property real modelData
                        width: 5
                        height: 1
                        x: modelData > 0 ? -0.75 : 2.75
                        y: 1.5
                        rotation: modelData
                        antialiasing: true
                        color: pickCell.hot || root.open ? root.theme.paletteAccent : root.theme.barFg
                        opacity: pickCell.hot || root.open ? 1.0 : 0.6
                    }
                }
            }
        }
    }

    // Right and middle open the menu too. Left is not accepted here, so it
    // reaches the Cells beneath, which keep their own hover and rule.
    MouseArea {
        id: pickMa
        anchors.fill: parent
        enabled: root.canMenu
        acceptedButtons: Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.gesture()
    }
    HoverHandler { id: cellsHover }

    // -- The menu ------------------------------------------------------------
    // One row of the plate: a label, a hover tone, a rule when marked, tap.
    component PickRow: Item {
        id: row
        property string label: ""
        property real ink: 1.0
        property bool marked: false       // the 2px rule: what is live now
        property bool faint: false        // a 1px half-strength rule: the secondary "last staged"
        property bool live: true          // false for a header or a message
        readonly property bool hot: root.hotRow === row
        signal activated()

        width: parent ? parent.width : 0
        height: 22

        Rectangle {
            visible: row.marked || row.faint
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: row.marked ? 2 : 1
            color: row.marked ? root.theme.paletteAccent : root.theme.barFg
            opacity: row.marked ? 1.0 : 0.5
        }
        Text {
            x: 9
            width: parent.width - 18
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: row.live && row.hot ? root.theme.paletteAccent : root.theme.barFg
            opacity: row.ink
            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.Linear } }
        }
        HoverHandler {
            enabled: row.live
            onHoveredChanged: {
                if (hovered) root.hotRow = row
                else if (root.hotRow === row) root.hotRow = null
            }
        }
        TapHandler {
            enabled: row.live
            onTapped: row.activated()
        }
    }

    LazyLoader {
        active: root.open

        PopupWindow {
            visible: true
            color: "transparent"
            anchor.item: root
            anchor.edges: Edges.Bottom | Edges.Right
            anchor.gravity: Edges.Bottom | Edges.Left
            anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.Slide

            // A 4px gap under the cells.
            implicitWidth: plate.width
            implicitHeight: plate.height + 4

            // The pointer has left both the cells and the popup: 600ms of grace
            // for the hand-off between two surfaces, then it closes.
            Timer {
                interval: 600
                running: !cellsHover.hovered && !plateHover.hovered && root.hotRow === null
                onTriggered: root.open = false
            }

            Rectangle {
                id: plate
                y: 4
                width: 208
                height: rows.implicitHeight + 2
                radius: 0
                color: root.theme.barBg
                border.width: 1
                border.color: root.theme.windowBorderInactive

                HoverHandler { id: plateHover }

                Column {
                    id: rows
                    x: 1
                    y: 1
                    width: parent.width - 2

                    PickRow {
                        live: false
                        ink: 0.6
                        label: "songs"
                    }
                    PickRow {
                        visible: !root.ready
                        live: false
                        ink: 0.6
                        label: !root.answer ? "..." : "" + (root.answer.message || "no answer")
                    }
                    Repeater {
                        model: root.songs
                        PickRow {
                            required property var modelData
                            readonly property bool here: root.ready && root.mode === "staging" && modelData.name === root.answer.song
                            readonly property bool last: root.ready && root.mode === "declarative" && modelData.name === root.answer.stagingSong
                            live: !!modelData.ok
                            ink: modelData.ok ? 1.0 : 0.4
                            label: modelData.ok ? "" + modelData.name
                                   : modelData.name + " · " + (modelData.reason || "unreadable")
                            marked: here
                            faint: last
                            onActivated: {
                                if (here) root.open = false
                                else root.act("stage", "" + modelData.name)
                            }
                        }
                    }
                    PickRow {
                        label: root.ready && root.answer.declared ? "declarative · " + root.answer.declared : "declarative"
                        marked: root.mode === "declarative"
                        onActivated: {
                            if (root.mode === "declarative") root.open = false
                            else root.act("declarative")
                        }
                    }
                    PickRow {
                        live: false
                        ink: 0.6
                        label: root.ready && root.answer.draftsSong ? "drafts · " + root.answer.draftsSong : "drafts"
                    }
                    PickRow {
                        visible: root.ready && root.drafts.length === 0
                        live: false
                        ink: 0.6
                        label: "no saved drafts"
                    }
                    Repeater {
                        model: root.drafts
                        PickRow {
                            required property var modelData
                            label: "" + modelData.name
                            marked: !!modelData.current
                            onActivated: {
                                if (modelData.current) root.open = false
                                else root.act("enter", "" + modelData.name)
                            }
                        }
                    }
                    PickRow {
                        label: "+ new draft"
                        onActivated: root.act("new")
                    }
                    PickRow {
                        visible: root.mode === "staging"
                        label: "save current as draft"
                        onActivated: root.act("save")
                    }
                }
            }
        }
    }
}
