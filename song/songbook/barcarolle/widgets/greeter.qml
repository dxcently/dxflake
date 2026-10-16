// greeter.qml — barcarolle's logon face (the `greeter` slot).
//
// The account tiles (LockPreview's "tiles" page) first; choosing one (or a machine with only one) opens
// LockPreview's password page for it, with Switch User back to the tiles. A
// refused password turns the panel red with "The user name or password is
// incorrect." in the emptied field; typing goes on from there. Any other
// greetd message ("No session to start.", a question that is not a plain
// password prompt) shows under or in the field. Accounts show by their
// name, never the passwd comment. Paint only:
// the choice goes to `auth.selectUser`, the password to `auth.respond`, and
// greetd decides. The face reports itself up with
// `auth.ready` once created.
import QtQuick
import "Kit.js" as Kit

Item {
    id: face

    property var livery
    property var bridge
    property var auth

    property bool failed: false
    property int current: 0
    readonly property var users: face.auth ? face.auth.users : []
    readonly property string selected: face.auth ? face.auth.selectedUser : ""
    readonly property string fSys: ["Segoe UI", "Selawik", "Noto Sans", "Open Sans", "DejaVu Sans"]
        .find(function (f) { return Qt.fontFamilies().indexOf(f) >= 0 }) || "sans-serif"

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
                preview.field.forceActiveFocus()
            }
        }
    }

    Keys.onPressed: event => {
        if (face.failed && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            face.dismissFailure()
            event.accepted = true
        } else if (face.selected === "" && face.users.length > 0 && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            face.choose(face.users[face.current].name)
            event.accepted = true
        } else if (face.selected === "" && event.key === Qt.Key_Right) {
            face.current = Math.min(face.users.length - 1, face.current + 1)
            event.accepted = true
        } else if (face.selected === "" && event.key === Qt.Key_Left) {
            face.current = Math.max(0, face.current - 1)
            event.accepted = true
        }
    }

    LockPreview {
        id: preview
        anchors.fill: parent
        mode: "logon"
        page: face.selected === "" ? "tiles" : face.failed ? "failure" : "password"
        users: face.users
        current: face.current
        livery: face.livery
        userName: face.selected
        failureText: "The user name or password is incorrect."
        prompt: Kit.hostPrompt(face.auth)
        // While greetd checks, only an error replaces Welcome.
        note: !!face.auth && face.auth.busy && !face.auth.messageIsError ? "" : Kit.hostNote(face.auth)
        noteIsError: !!face.auth && face.auth.messageIsError
        showSwitchUser: face.users.length > 1
        inputEnabled: !!face.auth && !face.auth.busy && face.auth.responseRequired
        busy: !!face.auth && face.auth.busy
        onSubmitted: text => face.auth.respond(text)
        onSwitchUser: face.choose("")
        onDismissFailure: face.dismissFailure()
        onHovered: index => face.current = index
        onChose: name => face.choose(name)
    }
}
