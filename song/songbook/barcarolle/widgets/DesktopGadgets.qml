import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

PanelWindow {
    id: root

    required property var livery
    required property var bridge
    required property var stagingEngine
    required property var bar

    screen: root.bar ? root.bar.screen : null

    readonly property bool primary: {
        var best = null, me = root.screen
        for (var i = 0; me && i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i], land = s.width >= s.height
            if (!best || (land && !best.land) || (land === best.land && s.x < best.s.x)) best = { s: s, land: land }
        }
        return !!best && best.s.name === me.name
    }

    anchors { top: true; right: true }
    margins { top: 24; right: 24 }
    implicitWidth: 196
    implicitHeight: body.item ? body.item.implicitHeight : 0
    exclusiveZone: 0
    color: "transparent"
    visible: root.primary && implicitHeight > 0
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "aoide-gadgets"

    Loader {
        id: body
        active: root.primary
        sourceComponent: Column {
            spacing: 6
            WidgetSlot {
                livery: root.livery
                bridge: root.bridge
                stagingEngine: root.stagingEngine
                slot: "meters"
                visible: implicitHeight > 0
            }
            WidgetSlot {
                livery: root.livery
                bridge: root.bridge
                stagingEngine: root.stagingEngine
                slot: "usage"
                visible: implicitHeight > 0
            }
            WidgetSlot {
                livery: root.livery
                bridge: root.bridge
                stagingEngine: root.stagingEngine
                slot: "power"
                visible: implicitHeight > 0
            }
        }
    }
}
