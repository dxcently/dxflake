// greeter.qml — barcarolle's logon face (the `greeter` slot).
//
// The account tiles first; choosing one (or a machine with only one) opens
// LockPreview's password page for it, with Switch User back to the tiles. A
// refused password shows "The user name or password is incorrect." with an OK
// button. Paint only: the choice goes to `auth.selectUser`, the password to
// `auth.respond`, and greetd decides. The face reports itself up with
// `auth.ready` once created.
import QtQuick
import QtQuick.Shapes

Item {
    id: face

    property var livery
    property var bridge
    property var auth

    property bool failed: false
    readonly property var users: face.auth ? face.auth.users : []
    readonly property string selected: face.auth ? face.auth.selectedUser : ""
    readonly property string fSys: ["Segoe UI", "Selawik", "Noto Sans", "Open Sans", "DejaVu Sans"]
        .find(function (f) { return Qt.fontFamilies().indexOf(f) >= 0 }) || "sans-serif"

    function displayName(name) {
        for (var i = 0; i < face.users.length; i++)
            if (face.users[i].name === name) return face.users[i].realName || name
        return name
    }

    function choose(name) {
        face.failed = false
        face.auth.selectUser(name)
    }

    function dismissFailure() {
        face.failed = false
        preview.field.forceActiveFocus()
    }

    focus: true
    Component.onCompleted: {
        face.forceActiveFocus()
        face.auth.ready = true
    }

    onSelectedChanged: if (face.selected !== "") Qt.callLater(function () { preview.field.forceActiveFocus() })

    Connections {
        target: face.auth
        function onFailuresChanged() {
            if (face.auth.failures > 0) {
                face.failed = true
                face.forceActiveFocus()
            }
        }
    }

    Keys.onPressed: event => {
        if (face.failed && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            face.dismissFailure()
            event.accepted = true
        } else if (face.selected === "" && face.users.length > 0 && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            face.choose(face.users[tiles.current].name)
            event.accepted = true
        } else if (face.selected === "" && event.key === Qt.Key_Right) {
            tiles.current = Math.min(face.users.length - 1, tiles.current + 1)
            event.accepted = true
        } else if (face.selected === "" && event.key === Qt.Key_Left) {
            tiles.current = Math.max(0, tiles.current - 1)
            event.accepted = true
        }
    }

    LockPreview {
        id: preview
        anchors.fill: parent
        mode: "logon"
        page: face.selected === "" ? "ground" : face.failed ? "failure" : "password"
        livery: face.livery
        userName: face.displayName(face.selected)
        failureText: "The user name or password is incorrect."
        showSwitchUser: face.users.length > 1
        inputEnabled: !!face.auth && !face.auth.busy && face.auth.responseRequired
        onSubmitted: text => face.auth.respond(text)
        onSwitchUser: face.choose("")
        onDismissFailure: face.dismissFailure()
    }

    // The account tiles, on the preview's ground while no account is chosen.
    Item {
        id: tiles
        visible: face.selected === ""
        anchors.fill: parent

        property int current: 0

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.32)
            spacing: 40

            Repeater {
                model: face.users

                Item {
                    required property var modelData
                    required property int index
                    width: 160
                    height: 200

                    Rectangle {
                        id: tileFrame
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 138
                        height: 138
                        radius: 12
                        color: tiles.current === index ? "#5cffffff" : "#3dffffff"
                        border.width: tiles.current === index ? 2 : 1
                        border.color: tiles.current === index ? "#ffffff" : "#c2ffffff"

                        Shape {
                            x: 6
                            y: 6
                            width: 126
                            height: 126
                            ShapePath {
                                strokeColor: "transparent"
                                fillColor: "#d9e8f2"
                                PathSvg { path: "M 63 26 A 22 22 0 1 1 62.99 26 Z M 22 120 C 22 88 40 74 63 74 C 86 74 104 88 104 120 Z" }
                            }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: tileFrame.height + 10
                        text: modelData.realName || modelData.name
                        color: "#ffffff"
                        font.family: face.fSys
                        font.pixelSize: 18
                        style: Text.Raised
                        styleColor: "#99000000"
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: tiles.current = index
                        onClicked: face.choose(modelData.name)
                    }
                }
            }
        }
    }
}
