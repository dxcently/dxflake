import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../.."
import "Kit.js" as Kit

Item {
    id: root

    required property var livery
    required property var bridge
    property var shared: null
    property var powermenu: null
    property var dock: null
    property var stagingEngine: null

    readonly property var kit: Kit.make(root.livery)

    implicitHeight: 0
    width: parent ? parent.width : implicitWidth

    readonly property var wsList: {
        var vs = (Hyprland.workspaces && Hyprland.workspaces.values)
                 ? Hyprland.workspaces.values.slice() : []
        vs = vs.filter(function (w) { return w && w.id > 0 })
        vs.sort(function (a, b) { return a.id - b.id })
        return vs
    }

    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    PanelWindow {
        id: win
        screen: QsWindow.window ? QsWindow.window.screen : null
        anchors { bottom: true; left: true; right: true }
        implicitHeight: Kit.barHeight
        exclusiveZone: Kit.barHeight
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "aoide-bar"

        Rectangle {
            anchors.fill: parent
            color: root.kit.glass
            opacity: 0.82
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Kit.withA("#ffffff", 0.34) }
                GradientStop { position: 0.5; color: Kit.withA("#ffffff", 0.10) }
                GradientStop { position: 0.5; color: Kit.withA("#000000", 0.10) }
                GradientStop { position: 1.0; color: Kit.withA(root.kit.flag, 0.18) }
            }
        }
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 1
            color: Kit.withA("#ffffff", 0.7)
        }

        Item {
            id: orb
            width: Kit.orbSize
            height: Kit.orbSize
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                border.width: 1
                border.color: Kit.withA("#ffffff", 0.85)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.kit.flag }
                    GradientStop { position: 0.55; color: root.kit.accent }
                    GradientStop { position: 1.0; color: "#0a3d52" }
                }
            }
            Rectangle {
                x: 5; y: 2
                width: parent.width - 10
                height: parent.height / 2 - 2
                radius: height
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Kit.withA("#ffffff", 0.85) }
                    GradientStop { position: 1.0; color: Kit.withA("#ffffff", 0.05) }
                }
            }
            Grid {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 3
                columns: 2
                spacing: 1
                Repeater {
                    model: ["#f47a72", "#3bdcac", "#4aa8ff", "#e8cf6a"]
                    Rectangle { width: 6; height: 6; radius: 1; color: modelData }
                }
            }
        }

        Row {
            id: strip
            anchors.left: orb.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: root.wsList
                Rectangle {
                    id: btn
                    required property var modelData
                    readonly property bool active: modelData.active || modelData.focused
                    width: Kit.buttonWidth
                    height: Kit.barHeight - 2
                    radius: 3
                    border.width: 1
                    border.color: active ? Kit.withA("#ffffff", 0.75) : Kit.withA("#ffffff", hover.containsMouse ? 0.5 : 0.18)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: btn.active ? Kit.withA(root.kit.glow, 0.55) : Kit.withA("#ffffff", hover.containsMouse ? 0.30 : 0.14) }
                        GradientStop { position: 0.5; color: btn.active ? Kit.withA(root.kit.accent, 0.40) : Kit.withA("#ffffff", 0.04) }
                        GradientStop { position: 0.5; color: btn.active ? Kit.withA(root.kit.accent, 0.60) : Kit.withA("#000000", 0.08) }
                        GradientStop { position: 1.0; color: btn.active ? Kit.withA(root.kit.glow, 0.45) : Kit.withA(root.kit.flag, 0.10) }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: btn.modelData.id
                        color: root.kit.text
                        font: Kit.titleFont(15)
                    }
                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btn.modelData.activate()
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            WidgetSlot {
                livery: root.livery
                bridge: root.bridge
                stagingEngine: root.stagingEngine
                slot: "ricemode"
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.right: parent.right
                    text: Qt.formatTime(root.now, "h:mm AP")
                    color: root.kit.text
                    font: Kit.bodyFont(12)
                }
                Text {
                    anchors.right: parent.right
                    text: Qt.formatDate(root.now, "M/d/yyyy")
                    color: root.kit.text
                    font: Kit.bodyFont(12)
                }
            }
        }
    }
}
