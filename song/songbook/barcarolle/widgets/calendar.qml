import QtQuick
import QtQuick.Shapes
import Quickshell
import "Kit.js" as Kit

Item {
    id: root

    required property var livery
    required property var bridge

    readonly property var qsWin: QsWindow.window
    readonly property bool shown: !!(qsWin && qsWin.visible)

    property date now: new Date()
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()

    readonly property int firstDay: Qt.locale().firstDayOfWeek
    readonly property date gridStart: {
        var offset = (new Date(root.viewYear, root.viewMonth, 1).getDay() - root.firstDay + 7) % 7
        return new Date(root.viewYear, root.viewMonth, 1 - offset)
    }
    readonly property bool onToday: root.viewYear === root.now.getFullYear() && root.viewMonth === root.now.getMonth()

    function snap() {
        root.now = new Date()
        root.viewYear = root.now.getFullYear()
        root.viewMonth = root.now.getMonth()
    }
    function step(n) {
        var d = new Date(root.viewYear, root.viewMonth + n, 1)
        root.viewYear = d.getFullYear()
        root.viewMonth = d.getMonth()
    }
    onShownChanged: if (root.shown) root.snap()

    Timer {
        interval: 1000
        repeat: true
        running: root.shown
        onTriggered: root.now = new Date()
    }

    implicitWidth: 338
    implicitHeight: 234

    MouseArea {
        property real acc: 0
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function (w) {
            acc += w.angleDelta.y
            if (Math.abs(acc) >= 120) {
                root.step(acc < 0 ? 1 : -1)
                acc = 0
            }
        }
    }

    Rectangle {
        width: 338
        height: 26
        radius: 2
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Kit.dark(0.80)
        Text {
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(root.now, "dddd, MMMM d, yyyy")
            color: "#ffffff"
            font: Kit.boldFont(12)
            textFormat: Text.PlainText
        }
    }

    Rectangle {
        y: 26
        width: 338
        height: 208
        radius: 2
        topLeftRadius: 0
        topRightRadius: 0
        color: Kit.plate()
        border.width: 1
        border.color: Kit.dark(0.55)
    }

    Item {
        id: nav
        x: 8
        y: 30
        width: 196
        height: 28

        Item {
            id: prev
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            Rectangle { anchors.fill: parent; radius: 2; color: prevMa.containsMouse ? Kit.accent(0.10) : "transparent" }
            Shape {
                x: 8
                y: 7
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Kit.dark(0.72)
                    strokeWidth: 1.5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M6 1 L2 5 L6 9" }
                }
            }
            MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.step(-1) }
        }
        Item {
            id: next
            width: 24
            height: 24
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            Rectangle { anchors.fill: parent; radius: 2; color: nextMa.containsMouse ? Kit.accent(0.10) : "transparent" }
            Shape {
                x: 10
                y: 7
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Kit.dark(0.72)
                    strokeWidth: 1.5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M2 1 L6 5 L2 9" }
                }
            }
            MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.step(1) }
        }
        Item {
            anchors { left: prev.right; right: next.left; verticalCenter: parent.verticalCenter }
            height: 24
            Rectangle { anchors.fill: parent; radius: 2; color: titleMa.containsMouse && !root.onToday ? Kit.accent(0.10) : "transparent" }
            Text {
                anchors.centerIn: parent
                text: Qt.locale().monthName(root.viewMonth, Locale.LongFormat) + " " + root.viewYear
                color: Kit.ink
                font: Kit.boldFont(12)
                textFormat: Text.PlainText
            }
            MouseArea {
                id: titleMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.onToday ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: root.snap()
            }
        }
    }

    Item {
        x: 8
        y: 58
        width: 196
        height: 20
        Row {
            Repeater {
                model: 7
                Item {
                    required property int index
                    width: 28
                    height: 20
                    Text {
                        anchors.centerIn: parent
                        text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.ShortFormat).substring(0, 2)
                        color: Kit.dark(0.72)
                        font: Kit.bodyFont(11)
                        textFormat: Text.PlainText
                    }
                }
            }
        }
        Rectangle { x: 0; y: 19; width: 196; height: 1; color: Kit.dark(0.20) }
    }

    Grid {
        x: 8
        y: 82
        columns: 7
        Repeater {
            model: 42
            Item {
                id: day
                required property int index
                readonly property date d: new Date(root.gridStart.getFullYear(), root.gridStart.getMonth(), root.gridStart.getDate() + index)
                readonly property bool inMonth: d.getMonth() === root.viewMonth
                readonly property bool today: d.getFullYear() === root.now.getFullYear() && d.getMonth() === root.now.getMonth() && d.getDate() === root.now.getDate()
                width: 28
                height: 24
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 2
                    visible: day.today
                    color: Kit.accent(0.22)
                    border.width: 1
                    border.color: "#25bbcf"
                }
                Text {
                    anchors.centerIn: parent
                    text: day.d.getDate()
                    color: day.inMonth ? Kit.ink : Kit.dark(0.45)
                    font: day.today ? Kit.heavyFont(12) : Kit.bodyFont(12)
                    textFormat: Text.PlainText
                }
            }
        }
    }

    Rectangle { x: 212; y: 34; width: 1; height: 192; color: Kit.dark(0.15) }

    Item {
        id: face
        x: 228
        y: 56
        width: 96
        height: 96

        readonly property real cx: 48
        readonly property real cy: 48

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            border.width: 1
            border.color: Kit.dark(0.55)
            gradient: Gradient {
                GradientStop { position: 0; color: "#ffffff" }
                GradientStop { position: 0.5; color: "#e3f1f3" }
                GradientStop { position: 0.5; color: "#d3e9ec" }
                GradientStop { position: 1; color: "#f0f8f9" }
            }
        }
        Repeater {
            model: 12
            Rectangle {
                required property int index
                readonly property bool major: index % 3 === 0
                x: face.cx - 1
                y: 5
                width: 2
                height: major ? 7 : 4
                radius: 1
                color: major ? Kit.dark(0.85) : Kit.dark(0.55)
                transform: Rotation { origin.x: 1; origin.y: face.cy - 5; angle: index * 30 }
            }
        }
        Rectangle {
            x: face.cx - 1.5
            y: face.cy - 24
            width: 3
            height: 24
            radius: 1.5
            color: Kit.ink
            transform: Rotation { origin.x: 1.5; origin.y: 24; angle: (root.now.getHours() % 12 + root.now.getMinutes() / 60) * 30 }
        }
        Rectangle {
            x: face.cx - 1
            y: face.cy - 36
            width: 2
            height: 36
            radius: 1
            color: Kit.ink
            transform: Rotation { origin.x: 1; origin.y: 36; angle: (root.now.getMinutes() + root.now.getSeconds() / 60) * 6 }
        }
        Rectangle {
            x: face.cx - 0.5
            y: face.cy - 38
            width: 1
            height: 46
            color: "#f47a72"
            transform: Rotation { origin.x: 0.5; origin.y: 38; angle: root.now.getSeconds() * 6 }
        }
        Rectangle {
            x: face.cx - 3.5
            y: face.cy - 3.5
            width: 7
            height: 7
            radius: 3.5
            color: Kit.ink
            border.width: 1
            border.color: Kit.white(0.55)
        }
    }

    Text {
        x: 213
        y: 162
        width: 125
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatTime(root.now, "h:mm:ss AP")
        color: Kit.ink
        font: Kit.boldFont(15)
        textFormat: Text.PlainText
    }
}
