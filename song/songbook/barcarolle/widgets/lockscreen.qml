// lockscreen.qml — barcarolle's lock face (the `lockscreen` slot).
//
// Two pages over LockPreview: the secure-attention banner, then, after
// Ctrl+Alt+Del, the tile with the password field. Esc, or a minute with no
// key or pointer, goes back to the banner. A refused password shows the host's
// message with an OK button. Paint only: the password goes to `auth.respond`,
// and the host's PAM conversation decides. The face reports itself up with
// `auth.ready` once created.
import QtQuick

Item {
    id: face

    property var livery
    property var bridge
    property var auth

    property string page: "attention"

    function toPassword() {
        face.page = "password"
        idle.restart()
        preview.field.forceActiveFocus()
    }

    function toAttention() {
        face.page = "attention"
        idle.stop()
        face.forceActiveFocus()
    }

    function dismissFailure() {
        face.toPassword()
    }

    focus: true
    Component.onCompleted: {
        face.forceActiveFocus()
        face.auth.ready = true
    }

    Timer {
        id: idle
        interval: 60000
        onTriggered: face.toAttention()
    }

    Connections {
        target: face.auth
        function onFailuresChanged() {
            if (face.auth.failures > 0) {
                face.page = "failure"
                idle.restart()
                face.forceActiveFocus()
            }
        }
        function onUnlocked() {
            face.toAttention()
        }
    }

    Keys.onPressed: event => {
        idle.restart()
        if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.AltModifier)) {
            if (face.page === "attention") face.toPassword()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            face.toAttention()
            event.accepted = true
        } else if (face.page === "failure" && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            face.dismissFailure()
            event.accepted = true
        }
    }

    LockPreview {
        id: preview
        anchors.fill: parent
        mode: "lock"
        page: face.page
        livery: face.livery
        userName: face.auth ? face.auth.userName : ""
        failureText: face.auth ? face.auth.message : ""
        inputEnabled: !!face.auth && !face.auth.busy
        onSubmitted: text => face.auth.respond(text)
        onDismissFailure: face.dismissFailure()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: if (face.page !== "attention") idle.restart()
    }
}
