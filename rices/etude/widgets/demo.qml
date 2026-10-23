// demo.qml — etude's "demo" slot: a throwaway proof-of-concept widget for
// the declared widget-type registry (Phase 6 end-to-end demo,
// CONTRACTS.md §5 / `aoide.arrangement.widgets`). Hosted by
// RiceSurfaces.qml's data-driven SurfaceSlot (not a fixed shell.qml anchor)
// — same PanelWindow-rooted shape CONTRACTS.md §5 documents for a slot that
// owns its own layer/namespace (mirrors sonata's widgets/powermenu.qml, the
// existing reference for a window-owning slot).
//
// The declared `shortcut` ("aoide:etude-demo", rice.nix/theme.json) is
// wired by RiceSurfaces.qml ITSELF — one GlobalShortcut per declared entry,
// calling `.toggle()` on the loaded item. This file must NOT register its
// own GlobalShortcut for the same appid/name, or the two would collide.
//
// Fixed injected-prop contract (CONTRACTS.md §5): only `theme` + `bridge` —
// RiceSurfaces.qml passes no extras.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var theme
    required property var bridge

    // Starts HIDDEN — same default posture as sonata's powermenu.qml
    // (`shown: false`); the declared shortcut / a direct `.toggle()` call is
    // what brings it up.
    property bool shown: false
    function show()   { root.shown = true }
    function hide()   { root.shown = false }
    function toggle() { root.shown = !root.shown }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: root.shown
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "aoide-etude-demo"
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive
                                            : WlrKeyboardFocus.None

    // Dismiss on click-outside or Escape — same courtesy powermenu.qml gives.
    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
    }
    Item {
        focus: true
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape) { root.hide(); event.accepted = true }
        }
    }

    // ── The obvious visual proof — a solid panel, readable at a glance ──────
    Rectangle {
        anchors.centerIn: parent
        width: 520
        height: 220
        radius: 12
        color: root.theme.paletteAccent
        border.color: root.theme.paletteFg
        border.width: 3

        Column {
            anchors.centerIn: parent
            spacing: 10
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "ETUDE"
                font.family: "Noto Serif"
                font.pixelSize: 48
                font.letterSpacing: 10
                font.weight: Font.Bold
                color: root.theme.paletteBg
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "arrangement demo — phase 6 proof"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: root.theme.paletteBg
            }
        }
    }
}
