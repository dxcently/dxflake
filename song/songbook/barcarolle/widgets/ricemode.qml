import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import "Kit.js" as Kit
import "Rice.js" as Rice

Item {
    id: root

    required property var livery
    required property var bridge

    readonly property string mode: root.livery.riceMode || "declarative"
    readonly property bool staging: root.mode !== "declarative"
    readonly property string draft: (root.livery.modeRaw && root.livery.modeRaw.draft) || ""
    readonly property string song: root.livery.songName || ""
    readonly property bool canMenu: !!root.bridge && typeof root.bridge.riceMenu === "function"
    readonly property string iconDir: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/song/songbook/barcarolle/icons/tray/"
    readonly property string hint: root.staging
        ? "Staging · " + root.song + (root.draft ? " · " + root.draft : "")
        : "Declarative · " + (Rice.ready(root.answer) && root.answer.declared ? root.answer.declared : root.song)

    property bool open: false
    property var answer: null
    property int asked: 0
    property bool pending: false
    property real goneAt: 0
    property bool tipShown: false
    readonly property string key: root.mode + "/" + root.song + "/" + root.draft
    onKeyChanged: root.pending = false
    Timer { interval: 10000; running: root.pending; onTriggered: root.pending = false }

    readonly property var rows: !root.canMenu
        ? [{ label: "Switching needs a newer shell", mark: "", live: false, kind: "", name: "", here: false }]
        : root.pending ? [Rice.waiting(null)] : Rice.switchRows(root.answer, root.livery.riceMode)

    function toggle() {
        if (root.open) { root.open = false; return }
        if (Date.now() - root.goneAt <= 250) return
        root.open = true
        if (!root.canMenu) return
        var ask = ++root.asked
        root.answer = null
        root.bridge.riceMenu(function (a) { if (ask === root.asked) root.answer = a })
    }
    function pick(row) {
        if (Rice.act(root.bridge, row)) root.pending = true
        root.open = false
    }

    implicitWidth: 24
    implicitHeight: Kit.barHeight

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: "transparent"
        border.width: 1
        border.color: Kit.white(0.32)
        visible: hover.hovered || root.open
    }
    Image {
        x: 4; y: 12; width: 16; height: 16
        source: "file://" + root.iconDir + (root.staging ? "stage-staging.svg" : "stage-declarative.svg")
        sourceSize: Qt.size(64, 64)
        smooth: true
        asynchronous: true
        fillMode: Image.PreserveAspectFit
    }
    HoverHandler {
        id: hover
        onHoveredChanged: {
            root.tipShown = false
            if (hovered) tipWait.restart()
            else tipWait.stop()
        }
    }
    Timer { id: tipWait; interval: 500; onTriggered: root.tipShown = true }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggle()
    }

    component Glass: Rectangle {
        id: gl
        radius: 3
        color: Kit.rimTint()
        border.width: 1
        border.color: Kit.dark(0.85)
        Item {
            anchors.fill: parent
            anchors.margins: 1
            clip: true
            Shape {
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: Kit.white(0.035)
                    PathSvg { path: Kit.streaks(gl.width - 2, gl.height - 2) }
                }
            }
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
            x: 1; y: 1; width: parent.width - 2; height: Math.min(24, parent.height - 2)
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0; color: Kit.white(0.22) }
                GradientStop { position: 1; color: Kit.white(0.06) }
            }
        }
    }

    component SwitchRow: Item {
        id: sr
        required property var modelData
        width: parent ? parent.width : 218
        height: 26
        Rectangle {
            anchors.fill: parent
            radius: 2
            color: srMa.containsMouse ? Kit.accent(0.10) : "transparent"
        }
        Text { x: 9; anchors.verticalCenter: parent.verticalCenter; text: sr.modelData.mark; color: Kit.ink; font: Kit.heavyFont(12); textFormat: Text.PlainText }
        Text {
            x: 24
            width: sr.width - 24 - 6
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
            text: sr.modelData.label
            color: sr.modelData.live ? Kit.ink : Kit.dark(0.40)
            font: Kit.bodyFont(12)
            textFormat: Text.PlainText
        }
        MouseArea {
            id: srMa
            anchors.fill: parent
            enabled: sr.modelData.live
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pick(sr.modelData)
        }
    }

    PopupWindow {
        visible: root.tipShown && hover.hovered && !root.open
        color: "transparent"
        anchor.item: root
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
        anchor.adjustment: PopupAdjustment.Slide
        implicitWidth: tipText.implicitWidth + 16
        implicitHeight: 24 + 6
        mask: Region {}
        Glass {
            width: parent.width
            height: 24
            Text { x: 8; y: 6; height: 15; verticalAlignment: Text.AlignVCenter; text: root.hint; font: Kit.bodyFont(12); color: Kit.withA("#000000", 0.45); textFormat: Text.PlainText }
            Text { id: tipText; x: 8; y: 4.5; height: 15; verticalAlignment: Text.AlignVCenter; text: root.hint; font: Kit.bodyFont(12); color: "#ffffff"; textFormat: Text.PlainText }
        }
    }

    PopupWindow {
        id: fly
        visible: root.open
        color: "transparent"
        anchor.item: root
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
        anchor.adjustment: PopupAdjustment.Slide
        grabFocus: false
        implicitWidth: rim.width
        implicitHeight: Math.max(446, rim.height + 6)
        mask: Region { item: rim }
        Shortcut { sequence: "Escape"; enabled: fly.visible; onActivated: root.open = false }
        HyprlandFocusGrab {
            windows: [fly]
            active: fly.visible && fly.backingWindowVisible
            onCleared: {
                root.goneAt = Date.now()
                root.open = false
            }
        }
        Glass {
            id: rim
            y: fly.implicitHeight - 6 - height
            width: 234
            height: plate.height + 14
            Rectangle {
                id: plate
                x: 7; y: 7; width: 220
                height: col.height + 10
                radius: 2
                color: Kit.plate()
                border.width: 1
                border.color: Kit.dark(0.55)
                Column {
                    id: col
                    x: 1; y: 5; width: parent.width - 2
                    Repeater {
                        model: root.rows
                        SwitchRow {}
                    }
                }
            }
        }
    }
}
