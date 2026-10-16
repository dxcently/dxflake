// lockscreen.qml — barcarolle's lock face (the `lockscreen` slot).
//
// Two pages over LockPreview: the secure-attention banner, then, after
// Ctrl+Alt+Del, the tile with the password field. Esc, or a minute with no
// key or pointer, goes back to the banner. A refused password turns the panel
// red with the host's message in the emptied field; typing goes on from there.
// Any other host message (a hand-over, a question that is not a plain password
// prompt) shows under or in the field, and the field takes an answer only while
// the host asks for one.
// Under Hyprland the keyboard layout badge follows its `activelayout` event.
// Paint only: the password goes to `auth.respond`,
// and the host's PAM conversation decides. The face reports itself up with
// `auth.ready` once created.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "Kit.js" as Kit

Item {
    id: face

    property var livery
    property var bridge
    property var auth

    property string page: "attention"
    // The host's words for the last refusal, which the field shows in red.
    property string refusal: ""

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
                // The host counts the failure before it words it: the page
                // turns red once the words are there, in one step.
                Qt.callLater(function () {
                    face.refusal = face.auth.message
                    face.page = "failure"
                    idle.restart()
                    preview.field.forceActiveFocus()
                })
            }
        }
        function onUnlocked() {
            face.toAttention()
        }
    }

    Connections {
        target: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? Hyprland : null
        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            preview.layoutName = Kit.layoutCode(event.data.substring(event.data.lastIndexOf(",") + 1))
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
        failureText: face.refusal
        prompt: Kit.hostPrompt(face.auth)
        note: Kit.hostNote(face.auth)
        noteIsError: !!face.auth && face.auth.messageIsError
        inputEnabled: !!face.auth && !face.auth.busy && face.auth.responseRequired
        busy: !!face.auth && face.auth.busy
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
