import QtQuick
import QtQuick.Shapes
import Quickshell
import "Kit.js" as Kit

Item {
    id: root

    required property var livery
    required property var bridge

    readonly property string mode: root.livery.riceMode || "declarative"
    readonly property string draft: (root.livery.modeRaw && root.livery.modeRaw.draft) || ""
    readonly property string song: root.livery.songName
    readonly property bool canMenu: !!root.bridge && typeof root.bridge.riceMenu === "function"
    readonly property string word: root.pending ? "…" : (root.mode === "staging" ? "Stage" : (root.mode === "draft" ? "Draft" : "Declared"))

    property bool pending: false
    property bool open: false
    property var answer: null
    property int asked: 0
    property Item hotRow: null
    readonly property bool ready: !!root.answer && root.answer.ok === true
    readonly property var songs: root.ready && Array.isArray(root.answer.songs) ? root.answer.songs : []
    readonly property var drafts: root.ready && Array.isArray(root.answer.drafts) ? root.answer.drafts : []
    readonly property string note: !root.answer ? "…" : (!root.answer.ok ? "" + (root.answer.message || "no answer") : "")

    onModeChanged: root.pending = false
    onDraftChanged: root.pending = false
    onSongChanged: root.pending = false
    Timer { interval: 10000; running: root.pending; onTriggered: root.pending = false }

    function gesture() {
        if (root.pending) return
        if (root.open) { root.open = false; return }
        root.answer = null
        var ask = ++root.asked
        root.open = true
        root.bridge.riceMenu(function (reply) { if (ask === root.asked) root.answer = reply })
    }

    function act(kind, name) {
        root.open = false
        if (kind !== "save") root.pending = true
        if (kind === "stage") root.bridge.riceMode("stage", name)
        else if (kind === "declarative") root.bridge.riceMode("declarative")
        else root.bridge.riceDraft(kind, name)
    }

    implicitWidth: label.implicitWidth + 50
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: Kit.white(root.open ? 0.08 : 0.04)
        border.width: 1
        border.color: Kit.white(root.open || cellMa.containsMouse ? 0.32 : 0.20)
    }

    Row {
        id: cellRow
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Item {
            width: 16; height: 16
            anchors.verticalCenter: parent.verticalCenter
            Shape {
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "#ffffff"; strokeWidth: 1.5; fillColor: "transparent"
                    PathSvg { path: "M6 2.5 v9" }
                }
                ShapePath {
                    strokeColor: "#ffffff"; strokeWidth: 1.4; fillColor: "transparent"
                    PathSvg { path: Kit.ell(4.2, 11.8, 2.6, 1.9, -20) }
                }
                ShapePath {
                    strokeColor: Kit.cyan; strokeWidth: 1.5; fillColor: "transparent"
                    PathSvg { path: "M6 2.5 c2.5 0 3 2.5 6 2.5" }
                }
            }
        }
        Item {
            width: label.implicitWidth; height: label.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            Text { x: 0; y: 1; text: root.word; font: Kit.boldFont(12); color: Kit.withA("#000000", 0.45); textFormat: Text.PlainText }
            Text { id: label; text: root.word; font: Kit.boldFont(12); color: "#ffffff"; textFormat: Text.PlainText }
        }
    }
    Item {
            x: root.width - 18; y: 14.5; width: 10; height: 5
            Shape {
                x: 2
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "#ffffff"; strokeWidth: 1.3; fillColor: "transparent"
                    PathSvg { path: "M1 1 l3 3 3 -3" }
                }
            }
        }

    MouseArea {
        id: cellMa
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.canMenu
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.canMenu ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.gesture()
    }

    component PickRow: Item {
        id: row
        property string lamp: ""
        property string name: ""
        property color nameColor: Kit.dark(1)
        property bool live: true
        readonly property bool hot: root.hotRow === row
        signal activated()

        width: 248
        height: 26

        Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(37 / 255, 187 / 255, 207 / 255, 0.10); visible: row.live && row.hot }
        Text {
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.lamp
            color: Kit.dark(1)
            font: Kit.heavyFont(12)
            textFormat: Text.PlainText
        }
        Text {
            x: 28
            width: parent.width - 36
            anchors.verticalCenter: parent.verticalCenter
            text: row.name.replace(/\s+/g, " ")
            color: row.nameColor
            elide: Text.ElideRight
            font: Kit.bodyFont(12)
            textFormat: Text.PlainText
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

    component Head: Item {
        property string name: ""
        width: 248
        height: 24
        Text {
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            text: parent.name
            color: Kit.dark(0.72)
            font: Kit.boldFont(12)
            textFormat: Text.PlainText
        }
    }

    Component {
        id: pickBody
        Column {
            Head { name: "songs" }
            PickRow { visible: !root.ready; live: false; name: root.note; nameColor: Kit.dark(0.55) }
            Repeater {
                model: root.songs
                PickRow {
                    required property var modelData
                    readonly property bool here: root.ready && root.mode === "staging" && modelData.name === root.answer.song
                    readonly property bool last: root.ready && root.mode === "declarative" && modelData.name === root.answer.stagingSong
                    live: !!modelData.ok
                    lamp: here ? "✓" : (last ? "○" : "")
                    name: modelData.ok ? "" + modelData.name : modelData.name + " · unreadable"
                    nameColor: modelData.ok ? Kit.dark(1) : Kit.dark(0.55)
                    onActivated: {
                        if (here) root.open = false
                        else root.act("stage", "" + modelData.name)
                    }
                }
            }
            PickRow {
                lamp: root.mode === "declarative" ? "✓" : ""
                name: root.ready && root.answer.declared ? "[declarative] " + root.answer.declared : "[declarative]"
                onActivated: {
                    if (root.mode === "declarative") root.open = false
                    else root.act("declarative")
                }
            }
            Head { name: root.ready && root.answer.draftsSong ? "drafts · " + root.answer.draftsSong : "drafts" }
            PickRow { visible: root.ready && root.drafts.length === 0; live: false; name: "no saved drafts"; nameColor: Kit.dark(0.55) }
            Repeater {
                model: root.drafts
                PickRow {
                    required property var modelData
                    lamp: modelData.current ? "✓" : ""
                    name: "" + modelData.name
                    onActivated: {
                        if (modelData.current) root.open = false
                        else root.act("enter", "" + modelData.name)
                    }
                }
            }
            PickRow { name: "[+ new draft]"; onActivated: root.act("new") }
            PickRow { visible: root.mode === "staging"; name: "[save as draft]"; onActivated: root.act("save") }
        }
    }

    LazyLoader {
        active: root.open

        PopupWindow {
            visible: true
            color: "transparent"
            anchor.item: root
            anchor.edges: Edges.Top | Edges.Left
            anchor.gravity: Edges.Top | Edges.Right
            anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.Slide
            implicitWidth: 250
            implicitHeight: body.implicitHeight + 8

            Timer {
                interval: 600
                running: !cellMa.containsMouse && !paneHover.hovered && root.hotRow === null
                onTriggered: root.open = false
            }

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: Qt.rgba(245 / 255, 251 / 255, 251 / 255, 0.97)
                border.width: 1
                border.color: Kit.dark(0.55)
                HoverHandler { id: paneHover }
                Loader {
                    id: body
                    x: 1; y: 4
                    sourceComponent: pickBody
                }
            }
        }
    }
}
