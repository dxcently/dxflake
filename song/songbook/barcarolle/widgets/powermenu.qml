import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "Kit.js" as Kit
import "Power.js" as Power

PanelWindow {
    id: root

    required property var livery
    required property var bridge

    readonly property var actions: Power.actions
    readonly property int defaultSel: 5

    property int sel: root.defaultSel
    property int hot: root.defaultSel
    property int focusIdx: 1
    property bool listOpen: false
    property bool helpOpen: false

    property bool shown: false
    property real rise: 0
    Behavior on rise {
        NumberAnimation { duration: root.shown ? 160 : 110; easing.type: Easing.OutCubic }
    }

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
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: root.shown || root.rise > 0.01
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "aoide-powermenu"
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    GlobalShortcut {
        appid: "aoide"
        name: "powermenu"
        description: "Summon the Shut Down dialog"
        onPressed: root.toggle()
    }

    function show(preselect) {
        if (root.shown) return
        var s = root.focusedScreen()
        if (s) root.targetScreen = s
        var at = root.actions.findIndex(function (a) { return a.action === preselect })
        root.sel = at >= 0 ? at : root.defaultSel
        root.hot = root.sel
        root.focusIdx = 1
        root.listOpen = false
        root.helpOpen = false
        root.shown = true
        Qt.callLater(function () { keys.forceActiveFocus() })
    }
    function hide() { root.shown = false }
    function toggle() { if (root.shown) root.hide(); else root.show() }
    onShownChanged: root.rise = root.shown ? 1 : 0

    function ok() {
        root.bridge.sendCommand({ cmd: "power", action: root.actions[root.sel].action })
        root.hide()
    }
    function pick(i) {
        root.sel = Math.max(0, Math.min(root.actions.length - 1, i))
        root.hot = root.sel
    }
    function activateFocused() {
        if (root.focusIdx === 2) root.hide()
        else if (root.focusIdx === 3) root.helpOpen = !root.helpOpen
        else root.ok()
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: function (e) {
            var n = root.actions.length
            if (e.key === Qt.Key_Escape) {
                if (root.listOpen) root.listOpen = false
                else root.hide()
            } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Down) {
                var d = e.key === Qt.Key_Up ? -1 : 1
                if (root.listOpen) root.hot = Math.max(0, Math.min(n - 1, root.hot + d))
                else root.pick(root.sel + d)
            } else if (e.key === Qt.Key_Home) {
                if (root.listOpen) root.hot = 0; else root.pick(0)
            } else if (e.key === Qt.Key_End) {
                if (root.listOpen) root.hot = n - 1; else root.pick(n - 1)
            } else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
                root.listOpen = false
                root.focusIdx = (root.focusIdx + (e.key === Qt.Key_Tab ? 1 : 3)) % 4
            } else if (e.key === Qt.Key_F1) {
                root.helpOpen = !root.helpOpen
            } else if (e.key === Qt.Key_Space && root.focusIdx === 0 && !root.listOpen) {
                root.listOpen = true
                root.hot = root.sel
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                if (root.listOpen) {
                    root.pick(root.hot)
                    root.listOpen = false
                } else {
                    root.activateFocused()
                }
            } else {
                return
            }
            e.accepted = true
        }
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

    component Btn: Item {
        id: bt
        property string label: ""
        property bool primary: false
        property bool focused: false
        signal activated()
        width: 75
        height: 23
        Rectangle {
            anchors.fill: parent
            radius: 3
            border.width: 1
            border.color: btMa.pressed ? Kit.dark(0.90) : (btMa.containsMouse || bt.primary || bt.focused ? "#2aa3b8" : Kit.dark(0.55))
            gradient: Gradient {
                GradientStop { position: 0; color: btMa.pressed ? "#bfe3e8" : (btMa.containsMouse ? "#e9fbfd" : "#f7fcfc") }
                GradientStop { position: 0.5; color: btMa.pressed ? "#a9d7de" : (btMa.containsMouse ? "#c9f0f5" : "#e4eeee") }
                GradientStop { position: 0.5; color: btMa.pressed ? "#94cdd6" : (btMa.containsMouse ? "#a9e6ee" : "#d3e1e2") }
                GradientStop { position: 1; color: btMa.pressed ? "#8cc6cf" : (btMa.containsMouse ? "#8ddbe6" : "#c5d6d8") }
            }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: bt.primary || bt.focused ? Kit.accent(0.85) : Kit.white(0.7)
        }
        Text {
            anchors.centerIn: parent
            text: bt.label
            color: Kit.ink
            font: Kit.bodyFont(12)
            textFormat: Text.PlainText
        }
        MouseArea {
            id: btMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bt.activated()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
        Rectangle {
            anchors.fill: parent
            color: Kit.dark(0.04)
            opacity: root.rise
        }
    }

    Item {
        id: dlg
        width: 400
        height: 290
        anchors.centerIn: parent
        opacity: root.rise
        scale: 0.95 + 0.05 * root.rise

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: Kit.rimTint()
            border.width: 1
            border.color: Kit.dark(0.85)
        }
        Item {
            x: 1; y: 1; width: parent.width - 2; height: parent.height - 2
            clip: true
            Svg { d: Kit.streaks(dlg.width - 2, dlg.height - 2); fill: Kit.white(0.035) }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 5
            color: "transparent"
            border.width: 1
            border.color: Kit.white(0.35)
        }

        Rectangle {
            id: title
            x: 1; y: 1; width: parent.width - 2; height: 30
            topLeftRadius: 5; topRightRadius: 5
            color: Kit.dark(0.80)
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 15
                topLeftRadius: 5; topRightRadius: 5
                gradient: Gradient {
                    GradientStop { position: 0; color: Kit.white(0.22) }
                    GradientStop { position: 1; color: Kit.white(0.06) }
                }
            }
            Rectangle { x: 0; y: parent.height - 1; width: parent.width; height: 1; color: Kit.dark(0.85) }
            Item {
                x: 9; y: 6; width: 12; height: 18
                scale: 0.8
                transformOrigin: Item.TopLeft
                Item {
                    x: 1.97; y: -1.4
                    Svg { d: Kit.clef; stroke: Kit.withA("#081e2b", 0.55); sw: 2.2 }
                    Svg { d: Kit.clef; stroke: "#c3d0d9"; sw: 0.9 }
                    Shape {
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: "transparent"
                            fillGradient: LinearGradient {
                                x1: 0; y1: 0; x2: 0; y2: 24
                                GradientStop { position: 0; color: "#ffffff" }
                                GradientStop { position: 0.45; color: "#d6e0e8" }
                                GradientStop { position: 0.55; color: "#9fb1bf" }
                                GradientStop { position: 1; color: "#e4ebf0" }
                            }
                            PathSvg { path: Kit.clef }
                        }
                    }
                }
            }
            Text { x: 31; y: 8.5; text: "Shut Down"; color: Kit.withA("#000000", 0.45); font: Kit.bodyFont(12); textFormat: Text.PlainText }
            Text { x: 31; y: 7; text: "Shut Down"; color: "#ffffff"; font: Kit.bodyFont(12); textFormat: Text.PlainText }
            Item {
                x: parent.width - 52; y: 3; width: 44; height: 19
                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    border.width: 1
                    border.color: Kit.dark(0.85)
                    gradient: Gradient {
                        GradientStop { position: 0; color: xMa.containsMouse ? "#ffb4a8" : "#f79a8c" }
                        GradientStop { position: 0.5; color: xMa.containsMouse ? "#f2705f" : "#e0604f" }
                        GradientStop { position: 0.5; color: xMa.containsMouse ? "#d9402c" : "#c4402f" }
                        GradientStop { position: 1; color: xMa.containsMouse ? "#e8604a" : "#d9584a" }
                    }
                }
                Rectangle { x: 1; y: 1; width: parent.width - 2; height: parent.height - 2; radius: 2; color: "transparent"; border.width: 1; border.color: Kit.white(0.45) }
                Svg { x: 17; y: 6; d: "M1 1 L10 8 M10 1 L1 8"; stroke: "#ffffff"; sw: 2; cap: ShapePath.RoundCap }
                MouseArea {
                    id: xMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.hide()
                }
            }
        }

        Rectangle {
            id: content
            x: 8; y: 32; width: 384; height: 250
            radius: 2
            color: Kit.plate()
            border.width: 1
            border.color: Kit.dark(0.55)

            Item {
                id: banner
                x: 1; y: 1; width: parent.width - 2; height: 72
                clip: true
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#0f5b78" }
                        GradientStop { position: 1; color: "#0a2c3e" }
                    }
                }
                Shape {
                    x: -30; y: -10; width: 220; height: 92
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: "transparent"
                        fillGradient: RadialGradient {
                            centerX: 110; centerY: 46; centerRadius: 100
                            focalX: 110; focalY: 46
                            GradientStop { position: 0; color: Kit.withA(Kit.cyan, 0.34) }
                            GradientStop { position: 1; color: Kit.withA(Kit.cyan, 0) }
                        }
                        PathSvg { path: "M0 0 H220 V92 H0 Z" }
                    }
                }
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        x: 0; y: 12 + index * 11; width: banner.width; height: 1
                        color: Kit.white(0.13)
                    }
                }
                Svg { d: Kit.streaks(banner.width, banner.height); fill: Kit.white(0.05) }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 36
                    gradient: Gradient {
                        GradientStop { position: 0; color: Kit.white(0.14) }
                        GradientStop { position: 1; color: Kit.white(0.04) }
                    }
                }
                Item {
                    x: 26; y: 16; width: 40; height: 48
                    scale: 2.3
                    transformOrigin: Item.TopLeft
                    Item {
                        x: 1.97; y: -1.4
                        Svg { d: Kit.clef; stroke: Kit.withA("#081e2b", 0.55); sw: 2.2 }
                        Svg { d: Kit.clef; stroke: "#c3d0d9"; sw: 0.9 }
                        Shape {
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: "transparent"
                                fillGradient: LinearGradient {
                                    x1: 0; y1: 0; x2: 0; y2: 24
                                    GradientStop { position: 0; color: "#ffffff" }
                                    GradientStop { position: 0.45; color: "#d6e0e8" }
                                    GradientStop { position: 0.55; color: "#9fb1bf" }
                                    GradientStop { position: 1; color: "#e4ebf0" }
                                }
                                PathSvg { path: Kit.clef }
                            }
                        }
                    }
                }
                Text {
                    x: 91; y: 16
                    text: "barcarolle"
                    color: Kit.withA("#000000", 0.35)
                    font: Kit.lightFont(34)
                    textFormat: Text.PlainText
                }
                Text {
                    x: 90; y: 14.5
                    text: "barcarolle"
                    color: "#ffffff"
                    font: Kit.lightFont(34)
                    textFormat: Text.PlainText
                }
                Rectangle { x: 0; y: parent.height - 1; width: parent.width; height: 1; color: Kit.dark(0.85) }
            }

            Text {
                x: 17; y: 87
                text: "What do you want the computer to do?"
                color: Kit.ink
                font: Kit.bodyFont(12)
                textFormat: Text.PlainText
            }

            Item {
                id: combo
                x: 17; y: 111; width: 350; height: 24
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: "#ffffff"
                    border.width: 1
                    border.color: root.focusIdx === 0 || root.listOpen ? "#2aa3b8" : Kit.dark(0.55)
                    Rectangle {
                        x: 1; y: 1; width: parent.width - 2; height: 3
                        gradient: Gradient {
                            GradientStop { position: 0; color: Kit.dark(0.12) }
                            GradientStop { position: 1; color: Kit.dark(0) }
                        }
                    }
                }
                Text {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.actions[root.sel].name
                    color: Kit.ink
                    font: Kit.bodyFont(12)
                    textFormat: Text.PlainText
                }
                Rectangle {
                    x: parent.width - 21; y: 1; width: 20; height: parent.height - 2
                    radius: 1
                    gradient: Gradient {
                        GradientStop { position: 0; color: comboMa.containsMouse ? "#e9fbfd" : "#f7fcfc" }
                        GradientStop { position: 0.5; color: comboMa.containsMouse ? "#c9f0f5" : "#e4eeee" }
                        GradientStop { position: 0.5; color: comboMa.containsMouse ? "#a9e6ee" : "#d3e1e2" }
                        GradientStop { position: 1; color: comboMa.containsMouse ? "#8ddbe6" : "#c5d6d8" }
                    }
                    Rectangle { x: 0; y: 0; width: 1; height: parent.height; color: Kit.dark(0.25) }
                    Svg { x: 6.5; y: 9; d: "M0 0 H7 L3.5 4.5 Z"; fill: Kit.ink }
                }
                MouseArea {
                    id: comboMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.focusIdx = 0
                        root.hot = root.sel
                        root.listOpen = !root.listOpen
                    }
                }
            }

            Text {
                x: 17; y: 145; width: 350
                text: root.actions[root.sel].hint
                wrapMode: Text.WordWrap
                color: Kit.dark(0.78)
                font: Kit.bodyFont(12)
                textFormat: Text.PlainText
            }
            Text {
                visible: root.helpOpen
                x: 17; y: 186; width: 350
                text: "Up and Down choose, Tab moves on, Enter confirms, Esc cancels."
                elide: Text.ElideRight
                color: Kit.dark(0.55)
                font.family: Kit.family
                font.pixelSize: 11
                font.italic: true
                textFormat: Text.PlainText
            }

            Rectangle {
                x: 1; y: parent.height - 47; width: parent.width - 2; height: 46
                color: Kit.dark(0.05)
                Rectangle { x: 0; y: 0; width: parent.width; height: 1; color: Kit.dark(0.15) }
                Btn {
                    x: 130; y: 12
                    label: "OK"
                    primary: root.focusIdx === 1
                    focused: root.focusIdx === 1
                    onActivated: root.ok()
                }
                Btn {
                    x: 211; y: 12
                    label: "Cancel"
                    focused: root.focusIdx === 2
                    onActivated: root.hide()
                }
                Btn {
                    x: 292; y: 12
                    label: "Help"
                    focused: root.focusIdx === 3
                    onActivated: root.helpOpen = !root.helpOpen
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.listOpen
                z: 5
                onClicked: root.listOpen = false
            }

            Rectangle {
                visible: root.listOpen
                z: 10
                x: combo.x; y: combo.y + combo.height - 1; width: combo.width
                height: root.actions.length * 22 + 4
                radius: 2
                color: "#f5fbfb"
                border.width: 1
                border.color: Kit.dark(0.55)
                Column {
                    x: 1; y: 2; width: parent.width - 2
                    Repeater {
                        model: root.actions
                        Item {
                            required property var modelData
                            required property int index
                            width: parent.width
                            height: 22
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 2
                                color: root.hot === index ? Kit.accent(0.22) : "transparent"
                                border.width: 1
                                border.color: root.hot === index ? Kit.dark(0.55) : "transparent"
                            }
                            Text {
                                x: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: Kit.ink
                                font: Kit.bodyFont(12)
                                textFormat: Text.PlainText
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.hot = index
                                onClicked: {
                                    root.pick(index)
                                    root.listOpen = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
