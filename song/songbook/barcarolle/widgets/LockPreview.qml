// LockPreview.qml — the Aero logon and lock picture, drawn. Visual mock only.
//
// A helper (uppercase, not a slot). Paint only: no TextInput, no MouseArea, no
// Process, no session or PAM call. The password field is drawn with a static
// caret. `mode`: "lock" shows Locked and Switch User, "logon" shows neither.
// The name sits above the field in both. Layout is anchors and fractions of the
// output; the pixel sizes are the Aero logon's own.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "Kit.js" as Kit

Item {
    id: root

    property string mode: "lock"
    property var livery: null

    implicitWidth: 1920
    implicitHeight: 1080

    readonly property bool lockMode: root.mode !== "logon"
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string aoideRoot: Quickshell.env("AOIDE_ROOT") || (root.home + "/.aoide")
    readonly property string userName: Quickshell.env("USER") || "khoa"
    readonly property string bust: "?v=" + Date.now()
    readonly property string tileRel: "/song/songbook/barcarolle/icons/user/silhouette.svg"
    readonly property string fSys: ["Segoe UI", "Selawik", "Noto Sans", "Open Sans", "DejaVu Sans"]
        .find(function (f) { return Qt.fontFamilies().indexOf(f) >= 0 }) || "sans-serif"

    property string coverPath: Quickshell.env("AOIDE_WALLPAPER") || ""
    property bool coverTile: false
    FileView {
        path: root.aoideRoot + "/song/stage/cover.json"
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var baked = Quickshell.env("AOIDE_WALLPAPER") || ""
            try {
                var d = JSON.parse(text())
                var applies = !!d && !!d.path && (!d.song || d.song === (root.livery ? root.livery.songName : ""))
                root.coverPath = applies ? "" + d.path : baked
                root.coverTile = applies && d.pick === true && d.tile === true
            } catch (e) { root.coverPath = baked; root.coverTile = false }
        }
        onLoadFailed: { root.coverPath = Quickshell.env("AOIDE_WALLPAPER") || ""; root.coverTile = false }
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#7fd0ee" }
                GradientStop { position: 0.5; color: "#1f7ea6" }
                GradientStop { position: 1.0; color: "#06283a" }
            }
        }
        Rectangle {
            x: parent.width * 0.12
            y: -parent.height * 0.25
            width: parent.width * 0.22
            height: parent.height * 1.5
            rotation: 22
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00ffffff" }
                GradientStop { position: 0.5; color: "#2effffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }
        Loader {
            id: art
            anchors.fill: parent
            visible: root.coverPath !== ""
            Component.onCompleted: setSource(Kit.helper("CoverArt"), {
                source: Qt.binding(function () { return root.coverPath !== "" ? "file://" + root.coverPath : "" }),
                tile: Qt.binding(function () { return root.coverTile }),
                screenWidth: Qt.binding(function () { return root.width })
            })
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.7
                blurMax: 40
                brightness: -0.2
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#3d000000" }
                GradientStop { position: 1.0; color: "#8c000000" }
            }
        }
    }

    Item {
        id: stack
        width: 256
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.30)

        Rectangle {
            id: frame
            x: (stack.width - width) / 2
            width: 138
            height: 138
            radius: 12
            color: "#3dffffff"
            border.width: 1
            border.color: "#c2ffffff"
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#c8ffffff"
                shadowBlur: 1.0
                shadowScale: 1.04
            }
        }
        Image {
            id: picture
            x: frame.x + 6
            y: frame.y + 6
            width: 126
            height: 126
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(126, 126)
            asynchronous: true
            property int tryIndex: 0
            readonly property var candidates: [
                "file://" + root.home + "/.face" + root.bust,
                "file://" + root.aoideRoot + root.tileRel + root.bust,
                "file://" + root.home + "/.aoide" + root.tileRel + root.bust
            ]
            source: candidates[tryIndex]
            onStatusChanged: if (status === Image.Error && tryIndex < candidates.length - 1) tryIndex++
        }
        Rectangle {
            x: frame.x + 1
            y: frame.y + 1
            width: frame.width - 2
            height: 66
            radius: 11
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#8cffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }

        Text {
            id: nameText
            x: (stack.width - width) / 2
            y: frame.y + frame.height + 10
            text: root.userName
            color: "#ffffff"
            font.family: root.fSys
            font.pixelSize: 22
            style: Text.Raised
            styleColor: "#99000000"
        }
        Text {
            id: lockedText
            visible: root.lockMode
            x: (stack.width - width) / 2
            y: nameText.y + nameText.height - 2
            text: "Locked"
            color: "#ffffff"
            font.family: root.fSys
            font.pixelSize: 15
            style: Text.Raised
            styleColor: "#99000000"
        }

        Rectangle {
            id: field
            x: 0
            y: (root.lockMode ? lockedText.y + lockedText.height : nameText.y + nameText.height) + 12
            width: 225
            height: 25
            radius: 2
            color: "#ffffff"
            border.width: 2
            border.color: "#7eb4ea"
            Rectangle {
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 13
                color: "#000000"
            }
            Text {
                x: 11
                anchors.verticalCenter: parent.verticalCenter
                text: "Password"
                color: "#8c8c8c"
                font.family: root.fSys
                font.pixelSize: 13
            }
        }
        Rectangle {
            x: field.x + field.width + 6
            y: field.y
            width: 25
            height: 25
            radius: 12.5
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#e4f4ff" }
                GradientStop { position: 0.5; color: "#5ca6e6" }
                GradientStop { position: 1.0; color: "#2466b0" }
            }
            border.width: 1
            border.color: "#e8f5ff"
            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeColor: "#ffffff"
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathSvg { path: "M 8.5 12.5 H 16 M 12.5 8.5 L 16.5 12.5 L 12.5 16.5" }
                }
            }
        }
        Rectangle {
            visible: root.lockMode
            x: (stack.width - width) / 2
            y: field.y + field.height + 16
            width: 150
            height: 28
            radius: 4
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#5cffffff" }
                GradientStop { position: 1.0; color: "#12ffffff" }
            }
            border.width: 1
            border.color: "#a8ffffff"
            Text {
                anchors.centerIn: parent
                text: "Switch User"
                color: "#ffffff"
                font.family: root.fSys
                font.pixelSize: 13
                style: Text.Raised
                styleColor: "#99000000"
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: root.width * 0.025
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height * 0.05
        width: 36
        height: 36
        radius: 18
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#c4e6ff" }
            GradientStop { position: 0.5; color: "#3a86c8" }
            GradientStop { position: 1.0; color: "#1b4f8a" }
        }
        border.width: 1
        border.color: "#d8efff"
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeColor: "#ffffff"
                strokeWidth: 2.2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathSvg { path: "M 10 14.5 H 26 M 18 14.5 V 22 M 18 22 L 13.5 30 M 18 22 L 22.5 30" }
            }
            ShapePath {
                strokeColor: "transparent"
                fillColor: "#ffffff"
                PathSvg { path: "M 21.2 8.3 A 3.2 3.2 0 1 1 14.8 8.3 A 3.2 3.2 0 1 1 21.2 8.3 Z" }
            }
        }
    }

    Item {
        anchors.right: parent.right
        anchors.rightMargin: root.width * 0.03
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height * 0.05
        width: 50
        height: 36
        Rectangle {
            width: 36
            height: 36
            radius: 18
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffb8ad" }
                GradientStop { position: 0.5; color: "#e0402f" }
                GradientStop { position: 1.0; color: "#8f1a12" }
            }
            border.width: 1
            border.color: "#ffd6cf"
            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeColor: "#ffffff"
                    strokeWidth: 2.2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathSvg { path: "M 12.21 11.11 A 9 9 0 1 0 23.79 11.11 M 18 8.5 V 17.5" }
                }
            }
        }
        Shape {
            x: 42
            y: 13
            width: 8
            height: 10
            ShapePath {
                strokeColor: "transparent"
                fillColor: "#ffffff"
                PathSvg { path: "M 0 0 L 8 5 L 0 10 Z" }
            }
        }
    }
}
