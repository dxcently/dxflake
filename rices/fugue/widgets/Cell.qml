// Cell.qml -- fugue's rigid-lattice unit: one cell on the bar/notifications grid.
//
// design/intent.md's thesis is "a rigid grid; nothing is ornamental" --
// every visible piece of fugue is one of these: a flat rectangle, one line
// of JetBrainsMono text, an optional 2px rule for "this is live" state, and
// a 1px hairline on the trailing edge, the only separator the grammar
// allows (grammar rule 5). No radius, no shadow, no gradient, no blur; a
// live cell wears a solid rule, never a glow (grammar rules 3-4). One
// transition tier: 120ms linear on colour only (grammar rule 4).
//
// Song-local helper component (slots.md "Helper files"): uppercase-first
// filename, resolved by TYPE NAME through the per-song qmldir the
// derivation emits for any song carrying an uppercase-first widgets/ file
// (Aoide's modules/dendrites/strillix/ at revision bb5dbcca) -- no import statement needed by
// a caller sitting in the same songs/fugue/ directory. Used by bar.qml,
// notifications.qml and ricemode.qml.
import QtQuick

Item {
    id: root

    required property var theme

    property string label: ""
    property string value: ""

    // Paint only from the injected theme (CONTRACTS.md section 0 / the
    // paint test) -- every colour below is a property default that reads
    // theme.*, never a literal. A caller may still override any of these
    // per cell (notifications.qml paints from the notif tier instead of bar's).
    property color paper: theme.paletteBg
    property color ink: theme.paletteFg
    // base02, via the window tier's borderInactive (rice.nix pins it there
    // literally: "borderInactive = base02" -- "recedes on graphite without
    // vanishing", exactly a hairline separator's job).
    property color hair: theme.windowBorderInactive
    property color tone: theme.paletteAccent
    property color urgentTone: theme.paletteUrgent

    // The live/selected state: a 2px rule, not a glow.
    property bool active: false
    // The alarm state: rule and value text burn urgentTone instead of tone.
    property bool urgent: false
    // A clickable cell reports through this signal; a readout cell with no
    // backing action leaves interactive false and draws no pointer.
    property bool interactive: false
    signal activated()

    readonly property bool hot: root.interactive && mouse.containsMouse

    implicitWidth: row.implicitWidth + 18
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: root.paper
    }

    // trailing hairline -- the only separator the grammar allows
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: root.hair
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            visible: root.label.length > 0
            text: root.label
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: root.ink
            opacity: 0.6
        }
        Text {
            visible: root.value.length > 0
            text: root.value
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color: root.urgent ? root.urgentTone : (root.hot ? root.tone : root.ink)
            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.Linear } }
        }
    }

    // state rule -- a 2px solid underline, never a glow
    Rectangle {
        visible: root.active
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: 1
        anchors.bottom: parent.bottom
        height: 2
        color: root.urgent ? root.urgentTone : root.tone
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.activated()
    }
}
