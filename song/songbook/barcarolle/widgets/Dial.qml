import QtQuick
import QtQuick.Shapes
import "Kit.js" as Kit

Item {
    id: dial

    required property var livery
    property bool big: false
    property bool inverted: false
    property real value: -1
    property string label: ""
    property string readout: value < 0 ? "—" : Math.round(value) + "%"

    readonly property var kit: Kit.make(dial.livery)
    readonly property var b16: (dial.livery && dial.livery.raw && dial.livery.raw.base16) ? dial.livery.raw.base16 : ({})
    readonly property color bad: dial.b16.base08 ? dial.b16.base08 : "#f47a72"

    readonly property var g: dial.big
        ? ({ R: 55, face: 49, arcW: 5, tick0: 40, tick1: 46, tickW: 1.6, glossY: -24, glossRx: 36, glossRy: 20,
             labelY: 30, labelPx: 9, base: 4, half: 2, len: 40, tip: 32, tipHalf: 1.2, hub: 6, hubRim: true,
             chipX: -17, chipY: 38, chipW: 34, chipH: 14, chipPx: 11, chipBase: 49 })
        : ({ R: 35, face: 30, arcW: 4, tick0: 24, tick1: 28, tickW: 1.3, glossY: -15, glossRx: 22, glossRy: 12,
             labelY: 19, labelPx: 7, base: 3, half: 1.6, len: 24, tip: 19, tipHalf: 1, hub: 4, hubRim: false,
             chipX: -15, chipY: 24, chipW: 30, chipH: 13, chipPx: 10, chipBase: 34 })

    width: g.R * 2
    height: g.R * 2

    property real angle: -135 + Math.max(0, Math.min(100, dial.value)) * 2.7
    Behavior on angle { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    function bandPath(r, w, mirror) {
        var s = mirror ? -1 : 1, ro = r + w / 2, ri = r - w / 2
        function at(rad, sinv, cosv) { return (s * rad * sinv) + " " + (-rad * cosv) }
        return "M" + at(ro, 0.5, 0.8660254) + " A" + ro + " " + ro + " 0 0 " + (mirror ? 0 : 1) + " " + at(ro, 0.8660254, -0.5)
             + " L" + at(ri, 0.8660254, -0.5) + " A" + ri + " " + ri + " 0 0 " + (mirror ? 1 : 0) + " " + at(ri, 0.5, 0.8660254) + " Z"
    }

    function tickPath(r0, r1) {
        var d = ""
        for (var i = 0; i < 11; i++) {
            var a = (-135 + i * 27) * Math.PI / 180
            d += "M" + (Math.sin(a) * r0) + " " + (-Math.cos(a) * r0) + " L" + (Math.sin(a) * r1) + " " + (-Math.cos(a) * r1) + " "
        }
        return d
    }

    component Svg: Shape {
        id: sv
        property string d: ""
        property color stroke: "transparent"
        property real sw: 1
        property color fill: "transparent"
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: sv.stroke
            strokeWidth: sv.sw
            fillColor: sv.fill
            capStyle: ShapePath.FlatCap
            PathSvg { path: sv.d }
        }
    }

    component Chrome: Shape {
        id: ch
        property real r: 6
        property bool rim: true
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: ch.rim ? Kit.dark(0.6) : "transparent"
            strokeWidth: 1
            fillGradient: LinearGradient {
                x1: -ch.r; y1: -ch.r; x2: ch.r; y2: ch.r
                GradientStop { position: 0; color: "#f5fbfb" }
                GradientStop { position: 0.35; color: "#8db0ba" }
                GradientStop { position: 0.6; color: "#f5fbfb" }
                GradientStop { position: 1; color: "#6a8f9c" }
            }
            PathSvg { path: Kit.ell(0, 0, ch.r, ch.r, 0) }
        }
    }

    component Label: Text {
        property real base: 0
        anchors.horizontalCenter: parent.horizontalCenter
        y: base - baselineOffset
        color: "#ffffff"
        textFormat: Text.PlainText
    }

    Item {
        x: dial.g.R
        y: dial.g.R

        Chrome { r: dial.g.R }

        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: 0; centerY: -dial.g.face * 0.1; centerRadius: dial.g.face * 1.2
                    focalX: 0; focalY: -dial.g.face * 0.1
                    GradientStop { position: 0; color: "#17384a" }
                    GradientStop { position: 1; color: "#081e2b" }
                }
                PathSvg { path: Kit.ell(0, 0, dial.g.face, dial.g.face, 0) }
            }
        }

        Shape {
            opacity: 0.9
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: dial.inverted ? -dial.g.face : dial.g.face * 0.5; y1: 0
                    x2: dial.inverted ? -dial.g.face * 0.5 : dial.g.face; y2: 0
                    GradientStop { position: 0; color: dial.inverted ? dial.bad : dial.kit.working }
                    GradientStop { position: 0.5; color: dial.kit.awaiting }
                    GradientStop { position: 1; color: dial.inverted ? dial.kit.working : dial.bad }
                }
                PathSvg { path: dial.bandPath(dial.g.face, dial.g.arcW, dial.inverted) }
            }
        }

        Svg { d: dial.tickPath(dial.g.tick0, dial.g.tick1); stroke: Kit.white(0.65); sw: dial.g.tickW }
        Svg { d: Kit.ell(0, dial.g.glossY, dial.g.glossRx, dial.g.glossRy, 0); fill: Kit.white(0.16) }

        Label {
            base: dial.g.labelY
            text: dial.label
            font: Kit.bodyFont(dial.g.labelPx)
            opacity: 0.75
        }

        Item {
            rotation: dial.angle
            Svg { d: "M" + (-dial.g.half) + " " + dial.g.base + " L0 " + (-dial.g.len) + " L" + dial.g.half + " " + dial.g.base + " Z"; fill: "#ffffff" }
            Svg {
                d: "M" + (-dial.g.tipHalf) + " " + (-dial.g.tip) + " L0 " + (-dial.g.len) + " L" + dial.g.tipHalf + " " + (-dial.g.tip) + " Z"
                fill: dial.bad
            }
        }

        Chrome { r: dial.g.hub; rim: dial.g.hubRim }

        Rectangle {
            x: dial.g.chipX; y: dial.g.chipY
            width: dial.g.chipW; height: dial.g.chipH
            radius: 2
            color: Kit.ink
        }
        Label {
            base: dial.g.chipBase
            text: dial.readout
            font: Kit.boldFont(dial.g.chipPx)
        }
    }
}
