import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "Kit.js" as Kit
import "Notice.js" as Notice

Item {
    id: root

    required property var livery
    required property var bridge

    readonly property var kit: Kit.make(root.livery)
    readonly property string stageDir: (Quickshell.env("AOIDE_ROOT") || (Quickshell.env("HOME") + "/.aoide")) + "/state/stage/"

    property var records: []
    property date now: new Date()

    readonly property var rows: Notice.newest(root.records)
    readonly property int awaiting: {
        var n = 0
        for (var i = 0; i < root.rows.length; i++) if (Notice.isSummons(root.rows[i])) n++
        return n
    }

    implicitWidth: 320
    implicitHeight: 26 + plate.height

    FileView {
        path: root.stageDir + "herald.json"
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(text())
                root.records = d && d.notifications ? d.notifications : []
            } catch (e) {}
        }
        onLoadFailed: root.records = []
    }
    Timer {
        interval: 30000
        repeat: true
        running: root.rows.length > 0
        onTriggered: root.now = new Date()
    }

    function dismiss(id) { root.bridge.sendCommand({ cmd: "heralddismiss", id: "" + id }) }
    function verdict(r, word) { root.bridge.sendCommand({ cmd: "heraldverdict", id: "" + r.sessionId, verdict: word }) }

    component Glyph: Item {
        id: gl
        property color tone: "#25bbcf"
        property bool bang: false
        width: 16
        height: 16
        Rectangle { x: 0.5; y: 0.5; width: 15; height: 15; radius: 7.5; color: gl.tone; border.width: 1; border.color: Kit.dark(0.55) }
        Rectangle { visible: gl.bang; x: 7.1; y: 3.1; width: 1.8; height: 6.8; radius: 0.9; color: Kit.ink }
        Rectangle { visible: gl.bang; x: 7; y: 10.5; width: 2; height: 2; radius: 1; color: Kit.ink }
        Rectangle { visible: !gl.bang; x: 7; y: 3.5; width: 2; height: 2; radius: 1; color: Kit.ink }
        Rectangle { visible: !gl.bang; x: 7.1; y: 6.8; width: 1.8; height: 5.7; radius: 0.9; color: Kit.ink }
    }

    component Pill: Item {
        id: pill
        property string label: ""
        property color tone: "#3bdcac"
        signal clicked()
        width: lab.implicitWidth + 26
        height: 22
        Rectangle {
            anchors.fill: parent
            radius: 11
            color: pill.tone
            border.width: 1
            border.color: Kit.dark(0.55)
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0; color: Kit.white(0.55) }
                    GradientStop { position: 0.5; color: Kit.white(0.15) }
                    GradientStop { position: 0.5; color: Kit.white(0) }
                    GradientStop { position: 1; color: Kit.white(0) }
                }
            }
            Rectangle { anchors.fill: parent; radius: 11; color: Kit.white(0.20); visible: pillMa.containsMouse }
        }
        Text {
            id: lab
            anchors.centerIn: parent
            text: pill.label
            color: Kit.ink
            font: Kit.boldFont(12)
            textFormat: Text.PlainText
        }
        MouseArea { id: pillMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }

    Rectangle {
        width: root.width
        height: 26
        radius: 2
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Kit.dark(0.80)
        Shape {
            x: 8
            y: 5
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "#ffffff"
                strokeWidth: 1.5
                fillColor: "transparent"
                PathSvg { path: "M3 1.5 v13.5" }
            }
            ShapePath {
                strokeColor: "transparent"
                fillColor: Kit.white(0.9)
                PathSvg { path: "M3.5 2.5 c3 -1.5 5 1.5 9.5 0 v7 c-4.5 1.5 -6.5 -1.5 -9.5 0 z" }
            }
        }
        Text {
            x: 30
            anchors.verticalCenter: parent.verticalCenter
            text: "Action Center"
                + (root.rows.length > 0 ? " · " + root.rows.length + (root.rows.length === 1 ? " message" : " messages") : "")
                + (root.awaiting > 0 ? " · " + root.awaiting + " awaiting" : "")
            color: "#ffffff"
            font: Kit.boldFont(12)
            textFormat: Text.PlainText
        }
    }

    Rectangle {
        id: plate
        y: 26
        width: root.width
        height: 1 + (root.rows.length > 0 ? flick.height + 26 : 52) + 1
        radius: 2
        topLeftRadius: 0
        topRightRadius: 0
        color: Kit.plate()
        border.width: 1
        border.color: Kit.dark(0.55)

        Text {
            visible: root.rows.length === 0
            x: 1
            y: 1
            width: parent.width - 2
            height: 52
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "No new messages"
            color: Kit.dark(0.72)
            font: Kit.bodyFont(12)
            textFormat: Text.PlainText
        }

        Flickable {
            id: flick
            visible: root.rows.length > 0
            x: 1
            y: 1
            width: parent.width - 2
            height: Math.min(list.implicitHeight, 340)
            contentWidth: width
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: flick.width
                Repeater {
                    model: root.rows
                    delegate: Item {
                        id: row
                        required property int index
                        required property var modelData
                        readonly property var rec: modelData
                        readonly property bool summons: Notice.isSummons(rec)
                        readonly property bool critical: ("" + rec.urgency) === "critical"
                        readonly property var cmd: summons ? Notice.command(rec.body) : ({ label: "", code: "" })
                        readonly property bool hasCmd: cmd.label !== ""
                        readonly property bool hasText: ("" + (rec.body || "")).length > 0 && !hasCmd
                        readonly property int pct: rec.progress !== undefined ? rec.progress | 0 : -1
                        width: list.width
                        height: info.height + 16

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: row.summons ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: if (!row.summons) root.dismiss(row.rec.id)
                        }
                        Rectangle { anchors.fill: parent; color: Kit.accent(0.10); visible: rowMa.containsMouse }
                        Rectangle { visible: row.index < root.rows.length - 1; x: 4; y: parent.height - 1; width: parent.width - 8; height: 1; color: Kit.dark(0.12) }

                        Glyph {
                            x: 9
                            y: 9
                            tone: row.summons ? root.kit.awaiting : row.critical ? root.livery.notifUrgent : row.rec.urgency === "low" ? "#8db0ba" : "#25bbcf"
                            bang: row.summons || row.critical
                        }

                        Column {
                            id: info
                            x: 33
                            y: 8
                            width: parent.width - 33 - 28

                            Text {
                                width: parent.width
                                text: "" + (row.rec.summary || row.rec.app || "")
                                color: Kit.ink
                                font: Kit.boldFont(12)
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }
                            Text {
                                width: parent.width
                                topPadding: 1
                                text: [("" + (row.rec.app || "")), Notice.ago(row.rec, root.now.getTime())].filter(function (p) { return p !== "" }).join(" · ")
                                elide: Text.ElideRight
                                color: Kit.dark(0.72)
                                font: Kit.bodyFont(11)
                                textFormat: Text.PlainText
                            }
                            Item {
                                visible: row.hasText || row.hasCmd
                                width: parent.width
                                height: visible ? 4 + (row.hasCmd ? Math.max(cmdLabel.implicitHeight, chip.height) : bodyText.implicitHeight) : 0
                                Text {
                                    id: bodyText
                                    visible: row.hasText
                                    y: 4
                                    width: parent.width
                                    text: "" + (row.rec.body || "")
                                    color: Kit.ink
                                    font: Kit.bodyFont(12)
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                }
                                Text {
                                    id: cmdLabel
                                    visible: row.hasCmd
                                    y: 4
                                    text: row.cmd.label
                                    color: Kit.ink
                                    font: Kit.bodyFont(12)
                                    textFormat: Text.PlainText
                                }
                                TextMetrics { id: codeProbe; font: Notice.monoFont(11); text: row.cmd.code }
                                Rectangle {
                                    id: chip
                                    visible: row.hasCmd
                                    x: cmdLabel.implicitWidth + 4
                                    y: 4 + (cmdLabel.implicitHeight - 15) / 2
                                    width: Math.min(codeProbe.advanceWidth + 8, parent.width - x)
                                    height: codeText.implicitHeight
                                    radius: 2
                                    color: Kit.dark(0.06)
                                    Text {
                                        id: codeText
                                        x: 3
                                        width: parent.width - 6
                                        text: row.cmd.code
                                        color: Kit.ink
                                        font: Notice.monoFont(11)
                                        wrapMode: Text.WrapAnywhere
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                    }
                                }
                            }
                            Item {
                                visible: row.pct >= 0
                                width: parent.width
                                height: visible ? 8 + 15 : 0
                                Rectangle { y: 8 + 4.5; width: parent.width - 40; height: 6; radius: 3; color: Kit.dark(0.20); border.width: 1; border.color: Kit.dark(0.25) }
                                Rectangle { y: 8 + 4.5; width: Math.max(6, (parent.width - 40) * Math.min(100, row.pct) / 100); height: 6; radius: 3; color: "#25bbcf" }
                                Text {
                                    anchors { right: parent.right; top: parent.top; topMargin: 8 }
                                    height: 15
                                    verticalAlignment: Text.AlignVCenter
                                    text: Math.min(100, row.pct) + "%"
                                    color: Kit.dark(0.72)
                                    font: Kit.bodyFont(11)
                                    textFormat: Text.PlainText
                                }
                            }
                            Item {
                                visible: row.summons
                                width: parent.width
                                height: visible ? 8 + 22 : 0
                                Row {
                                    y: 8
                                    spacing: 8
                                    Pill { label: "Approve"; tone: root.livery.paletteHot; onClicked: root.verdict(row.rec, "approve") }
                                    Pill { label: "Deny"; tone: root.livery.notifUrgent; onClicked: root.verdict(row.rec, "deny") }
                                }
                            }
                        }

                        Item {
                            visible: !row.summons && rowMa.containsMouse
                            anchors { right: parent.right; rightMargin: 8; top: parent.top; topMargin: 8 }
                            width: 16
                            height: 16
                            Rectangle { anchors.fill: parent; radius: 2; color: Kit.accent(0.15) }
                            Text { anchors.centerIn: parent; text: "×"; color: Kit.dark(0.72); font: Kit.bodyFont(13); textFormat: Text.PlainText }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: flick.contentHeight > flick.height
            x: parent.width - 4
            y: 1 + flick.height * flick.visibleArea.yPosition
            width: 3
            height: Math.max(12, flick.height * flick.visibleArea.heightRatio)
            radius: 1.5
            color: Kit.dark(0.35)
        }

        Rectangle {
            visible: root.rows.length > 0
            x: 1
            y: parent.height - 1 - 26
            width: parent.width - 2
            height: 26
            color: Kit.accent(0.10)
            Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: Kit.dark(0.15) }
            Text {
                id: clearText
                anchors.horizontalCenter: parent.horizontalCenter
                y: 5
                height: 15
                verticalAlignment: Text.AlignVCenter
                text: "Clear all"
                color: Kit.ink
                font: Kit.bodyFont(11)
                textFormat: Text.PlainText
            }
            Rectangle { visible: clearMa.containsMouse; x: clearText.x; y: 19; width: clearText.width; height: 1; color: Kit.ink }
            MouseArea {
                id: clearMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismiss("*")
            }
        }
    }
}
