import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "Kit.js" as Kit

Item {
    id: root

    required property var livery
    required property var bridge

    readonly property var rig: (Quickshell.env("AOIDE_RIG_BATTERY") || "").split(":")
    readonly property bool forced: rig[0] !== ""
    readonly property var dev: UPower.displayDevice

    readonly property bool present: forced || (!!dev && dev.isLaptopBattery && dev.isPresent)
    readonly property real pct: forced ? parseFloat(rig[0]) : (dev ? dev.percentage * 100 : 0)
    readonly property bool charging: forced ? rig[1] === "charging" : (!!dev && dev.state === UPowerDeviceState.Charging)
    readonly property bool full: forced ? rig[1] === "full" : (!!dev && dev.state === UPowerDeviceState.FullyCharged)
    readonly property real secs: forced ? 4980 : (!dev ? 0 : (charging ? dev.timeToFull : dev.timeToEmpty))

    readonly property string phase: full ? "Fully charged" : (charging ? "Charging" : "On battery")
    readonly property string span: {
        if (full || secs <= 0) return ""
        var m = Math.round(secs / 60)
        return (charging ? "full in " : "") + Math.floor(m / 60) + "h" + (m % 60 < 10 ? "0" : "") + (m % 60) + "m" + (charging ? "" : " left")
    }

    implicitWidth: 196
    implicitHeight: present ? 78 : 0

    component Use: Loader {
        property var props: ({})
        Component.onCompleted: setSource(Kit.helper("Dial"), props)
    }

    component Cap: Rectangle {
        id: cap
        property string label: ""
        height: 13
        radius: 2
        color: Kit.ink
        Text {
            anchors.centerIn: parent
            text: cap.label
            color: "#ffffff"
            font: Kit.bodyFont(9)
            textFormat: Text.PlainText
        }
    }

    Use { x: 17; y: 3; props: ({ livery: root.livery, inverted: true, label: "BATT", value: Qt.binding(function () { return root.pct }) }) }
    Cap { x: 100; y: 24; width: 88; label: root.phase }
    Cap { visible: root.span !== ""; x: 100; y: 41; width: 88; label: root.span }
}
