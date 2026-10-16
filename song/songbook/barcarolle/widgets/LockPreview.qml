// LockPreview.qml — the Aero logon and lock picture, drawn, with a live
// password field.
//
// A helper (uppercase, not a slot), shared by `lockscreen.qml` and
// `greeter.qml`. Paint and input only: no Process, no session or PAM call. What
// the user types leaves through `submitted(text)`, and the slot hands it to the
// host's `auth.respond`; the buttons only raise signals. The two corner
// icons (ease of access, power) are dead paint: no handler, no hover, so no
// power action is reachable from a lock or logon screen.
//
// `mode`: "lock" shows Locked under the name, "logon" does not. `page`:
// "attention" (the secure-attention hint), "password" (the glass panel: tile,
// name, field and arrow), "tiles" (a glass card per account in `users`, the
// `current` one lit and lifted; a card raises `hovered(index)` and
// `chose(name)`), "failure" (the same panel tinted and glowing red,
// the field cleared with the host's message as its placeholder; the first key
// typed raises `dismissFailure()` and keeps that key) or "ground" (the
// background alone, for a page the slot draws itself). `busy` turns the
// password page into Welcome — a Mac OS 9 startup box with an Aero spinner —
// for as long as the host is checking. `inputEnabled` is whether the host
// takes an answer now; while it does not, the field is shut and emptied and,
// unless a `note` explains why, reads "Please wait…" with a spinner in the
// arrow. `prompt` is the field's placeholder (the host's
// own question when it is not a plain password prompt); `note` is a host
// message shown in a glass line under the field (`noteIsError` tints it).
// `showSwitchUser` adds the Switch User button under the field. `userName`
// comes from the host: the account name.
//
// The tray (top right, in the taskbar's order: layout, volume, network,
// battery, then the time) and, on a lock, the Now Playing gadget under it read
// Quickshell's services directly and read-only; a badge whose service is
// missing is not drawn. The network badge names the link kind only (Wired,
// Wi-Fi, Not connected), never a network's name, and the cover art loads only
// a `file:` URL — anything else keeps the placeholder tile, so a locked screen
// fetches nothing. `layoutName` comes from the slot. Caps Lock is read
// from the letters typed (Qt has no lock-key state), so its balloon shows from
// the first letter on.
//
// The tile picture follows the Start menu's rule: `~/.face`, else the song's
// `icons/user/chrome-sash.svg` under $AOIDE_ROOT. A logon reads no home, so it
// always shows chrome-sash. The account cards live here too, one `Tile` each,
// named by the account name alone.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "Kit.js" as Kit

Item {
    id: root

    property string mode: "lock"
    property string page: "password"
    // No page keeps what was typed on another: Switch User and the way back
    // to the banner start from an empty field. Leaving a failure by typing
    // keeps the key that left it.
    property string _was: ""
    onPageChanged: {
        if (!(root._was === "failure" && root.page === "password")) input.text = ""
        if (root.page === "failure") shake.restart()
        root._was = root.page
        root._focusField()
    }
    // What was typed never outlives the prompt it answered.
    onInputEnabledChanged: {
        if (!root.inputEnabled) input.text = ""
        root._focusField()
    }
    function _focusField() {
        if (root.inputEnabled && (root.page === "password" || root.page === "failure")) input.forceActiveFocus()
    }
    property var livery: null
    property string userName: ""
    property string failureText: ""
    property string prompt: "Password"
    property string note: ""
    property bool noteIsError: false
    property bool showSwitchUser: false
    property bool inputEnabled: true
    property bool busy: false
    property string layoutName: Kit.layoutCode((Quickshell.env("XKB_DEFAULT_LAYOUT") || "").split(",")[0])
    property bool capsLock: false
    property var users: []
    property int current: 0
    readonly property alias field: input

    signal submitted(string text)
    signal switchUser()
    signal dismissFailure()
    signal hovered(int index)
    signal chose(string name)

    implicitWidth: 1920
    implicitHeight: 1080

    readonly property bool lockMode: root.mode !== "logon"
    // A note that only repeats the refusal is not drawn: the field says it, and
    // the red fades as typing starts.
    readonly property string shownNote: root.note === root.failureText ? "" : root.note
    readonly property bool welcome: root.busy && root.page === "password" && root.shownNote === ""
    readonly property bool failed: root.page === "failure"
    readonly property bool waiting: !root.inputEnabled && !root.busy && root.shownNote === "" && (root.page === "password" || root.page === "failure")
    // The field lights up only while the host takes an answer.
    readonly property bool live: input.activeFocus && root.inputEnabled
    readonly property bool fieldHot: fieldHover.containsMouse && root.inputEnabled
    readonly property bool panelShown: !root.welcome && (root.page === "password" || root.page === "failure")
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string aoideRoot: Quickshell.env("AOIDE_ROOT") || (root.home + "/.aoide")
    readonly property string fSys: ["Segoe UI", "Selawik", "Noto Sans", "Open Sans", "DejaVu Sans"]
        .find(function (f) { return Qt.fontFamilies().indexOf(f) >= 0 }) || "sans-serif"
    readonly property string fPlat: Qt.fontFamilies().indexOf("Tahoma") >= 0 ? "Tahoma" : Kit.family
    readonly property var pl: ({ face: "#dddddd", hi: "#ffffff", sh: "#8a8a8a", line: "#1d1d1d", sel: "#0f6d80" })

    function _submit() {
        if (!root.inputEnabled || root.page !== "password") return
        var text = input.text
        input.text = ""
        root.submitted(text)
    }

    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    property real shakeX: 0
    SequentialAnimation {
        id: shake
        NumberAnimation { target: root; property: "shakeX"; to: -16; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeX"; to: 14; duration: 70; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeX"; to: -10; duration: 65; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeX"; to: 6; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeX"; to: 0; duration: 55; easing.type: Easing.OutQuad }
    }

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

    // The account picture in its Aero frame: a white halo at rest, the bar's
    // cyan when `lit`, a gloss on the frame and a sheen that `sweep()` runs
    // across it.
    component Tile: Item {
        id: t
        property bool useFace: true
        property bool lit: false
        property int size: 138
        property real glow: t.lit ? 1 : 0
        Behavior on glow { NumberAnimation { duration: 220 } }
        readonly property string home: Quickshell.env("HOME") || ""
        readonly property string aoideRoot: Quickshell.env("AOIDE_ROOT") || (t.home + "/.aoide")
        readonly property string bust: "?v=" + Date.now()
        readonly property int inset: Math.round(t.size * 6 / 138)
        function sweep() { sweepRun.restart() }
        width: t.size
        height: t.size

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: Math.round(t.size * 12 / 138)
            color: Kit.white(0.24 + 0.1 * t.glow)
            border.width: 1
            border.color: Kit.white(0.76)
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.tint(Kit.white(0.78), Kit.withA(Kit.cyan, t.glow))
                shadowBlur: 1.0
                shadowScale: 1.04 + 0.04 * t.glow
            }
        }
        Image {
            x: t.inset
            y: t.inset
            width: t.size - 2 * t.inset
            height: width
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width, height)
            asynchronous: true
            property int tryIndex: 0
            readonly property var candidates: (t.useFace ? ["file://" + t.home + "/.face" + t.bust] : [])
                .concat(["file://" + t.aoideRoot + "/song/songbook/barcarolle/icons/user/chrome-sash.svg" + t.bust])
            source: candidates[tryIndex]
            onStatusChanged: if (status === Image.Error && tryIndex < candidates.length - 1) tryIndex++
        }
        Rectangle {
            x: 1
            y: 1
            width: t.size - 2
            height: Math.round(t.size * 0.48)
            radius: frame.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Kit.white(0.62) }
                GradientStop { position: 1.0; color: Kit.white(0) }
            }
        }
        Item {
            anchors.fill: parent
            clip: true
            Rectangle {
                id: band
                x: -t.size
                y: -t.size * 0.25
                width: t.size * 0.32
                height: t.size * 1.5
                rotation: 24
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Kit.white(0) }
                    GradientStop { position: 0.5; color: Kit.white(0.55) }
                    GradientStop { position: 1.0; color: Kit.white(0) }
                }
                NumberAnimation on x { id: sweepRun; running: false; from: -t.size * 0.6; to: t.size * 1.3; duration: 750; easing.type: Easing.InOutQuad }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: frame.radius
            color: "transparent"
            border.width: 2
            border.color: Kit.withA(Kit.cyan, 0.9)
            opacity: t.glow
        }
    }

    // Aero glass: the bar's dark outer line, a white inner rim, the colorized
    // body, the glass streaks, a top sheen, and a cyan halo at `glow`. `alarm`
    // tints the body and turns the halo red.
    component Glass: Item {
        id: g
        property real radius: 10
        property real glow: 0
        property real alarm: 0
        readonly property color red: "#ff3b30"
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: g.radius + 3
            color: "transparent"
            border.width: 5
            border.color: Qt.tint(Kit.withA(Kit.cyan, 0.85), Kit.withA(g.red, g.alarm))
            opacity: Math.max(g.glow, g.alarm)
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 28 }
        }
        Rectangle {
            anchors.fill: parent
            radius: g.radius
            border.width: 1
            border.color: Kit.dark(0.6)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Kit.white(0.30) }
                GradientStop { position: 0.45; color: Kit.white(0.12) }
                GradientStop { position: 1.0; color: Qt.rgba(42 / 255, 163 / 255, 184 / 255, 0.30) }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: g.radius
            color: Kit.withA(g.red, 0.32)
            opacity: g.alarm
        }
        Item {
            anchors.fill: parent
            anchors.margins: 2
            clip: true
            Shape {
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: Kit.white(0.05)
                    PathSvg { path: Kit.streaks(g.width, g.height) }
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: g.radius - 1
            color: "transparent"
            border.width: 1
            border.color: Qt.tint(Kit.white(0.42 + 0.3 * Math.max(g.glow, g.alarm)), Kit.withA(g.red, 0.6 * g.alarm))
        }
        Rectangle {
            x: 2
            y: 2
            width: g.width - 4
            height: Math.min(g.height * 0.4, 90)
            radius: g.radius - 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Kit.white(0.26) }
                GradientStop { position: 1.0; color: Kit.white(0) }
            }
        }
    }

    // A tray glyph from the song's own tray icons, the taskbar's vocabulary.
    component TrayGlyph: Image {
        property string name: ""
        width: 16
        height: 16
        sourceSize: Qt.size(16, 16)
        source: name === "" ? "" : "file://" + root.aoideRoot + "/song/songbook/barcarolle/icons/tray/" + name + ".svg"
    }

    component TrayText: Text {
        color: "#ffffff"
        font.family: root.fSys
        font.pixelSize: 12
        style: Text.Raised
        styleColor: "#99000000"
    }

    Item {
        id: ground
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

    // ── attention: the secure-attention hint in a breathing glass pill ────
    Item {
        id: attn
        anchors.fill: parent
        opacity: root.page === "attention" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 280 } }
        transform: Translate { y: (attn.opacity - 1) * 40 }

        Glass {
            id: hint
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(root.height * 0.46)
            width: hintText.implicitWidth + 56
            height: 44
            radius: 22
            SequentialAnimation on glow {
                running: attn.visible
                loops: Animation.Infinite
                NumberAnimation { from: 0.15; to: 0.75; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.75; to: 0.15; duration: 1400; easing.type: Easing.InOutSine }
            }
            Text {
                id: hintText
                anchors.centerIn: parent
                text: root.lockMode ? "Press CTRL + ALT + DELETE to unlock" : "Press CTRL + ALT + DELETE to log on"
                color: "#ffffff"
                font.family: root.fSys
                font.pixelSize: 17
                style: Text.Raised
                styleColor: "#99000000"
            }
        }
    }

    // ── tiles: one glass card per account, for a logon with a choice ───────
    Row {
        id: cards
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.27)
        spacing: 40
        opacity: root.page === "tiles" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 260 } }

        Repeater {
            model: root.users

            Item {
                id: card
                required property var modelData
                required property int index
                readonly property bool hot: root.current === index
                width: 196
                height: 236
                transform: Translate { y: card.hot ? -8 : 0; Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutBack } } }

                Glass {
                    anchors.fill: parent
                    radius: 12
                    glow: card.hot ? 0.9 : 0
                    Behavior on glow { NumberAnimation { duration: 220 } }
                }
                Tile {
                    id: cardTile
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 24
                    size: 138
                    useFace: false
                    lit: card.hot
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: cardTile.y + cardTile.height + 18
                    text: card.modelData.name
                    color: "#ffffff"
                    font.family: root.fSys
                    font.pixelSize: 20
                    style: Text.Raised
                    styleColor: "#99000000"
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: { root.hovered(card.index); cardTile.sweep() }
                    onClicked: root.chose(card.modelData.name)
                }
            }
        }
    }

    // ── the glass panel: tile, name, field; red while a refusal stands ────
    Glass {
        id: panel
        readonly property real enter: root.panelShown ? 1 : 0
        width: 380
        height: col.implicitHeight + 48
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.shakeX
        y: Math.round(root.height * 0.20) + (1 - opacity) * 36
        opacity: enter
        visible: opacity > 0
        radius: 12
        glow: root.live || panelHover.containsMouse ? 0.85 : 0
        alarm: root.failed ? 1 : 0
        Behavior on alarm { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on glow { NumberAnimation { duration: 220 } }

        MouseArea {
            id: panelHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Column {
            id: col
            x: 0
            y: 24
            width: panel.width
            spacing: 8

            Item {
                width: col.width
                height: 150
                Tile {
                    id: tile
                    useFace: root.lockMode
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 10 - 10 * lift
                    property real lift: root.page === "password" && root.panelShown ? 1 : 0
                    Behavior on lift { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
                    scale: 1 + 0.04 * lift
                    lit: tileHover.containsMouse || (lift > 0.5 && root.live)
                    MouseArea { id: tileHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                }
                Connections {
                    target: root
                    function onPanelShownChanged() { if (root.panelShown) tile.sweep() }
                    function onPageChanged() { if (root.page === "password") tile.sweep() }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.userName
                color: "#ffffff"
                font.family: root.fSys
                font.pixelSize: 24
                style: Text.Raised
                styleColor: "#99000000"
            }
            Text {
                visible: root.lockMode
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: -8
                text: "Locked"
                color: Kit.white(0.85)
                font.family: root.fSys
                font.pixelSize: 15
                style: Text.Raised
                styleColor: "#99000000"
            }
            Item { width: 1; height: 4 }

            Item {
                id: fieldRow
                z: 2
                visible: root.page === "password" || root.page === "failure"
                anchors.horizontalCenter: parent.horizontalCenter
                width: 256
                height: 27

                Rectangle {
                    id: field
                    width: 225
                    height: 27
                    radius: 3
                    color: root.inputEnabled ? "#ffffff" : "#e6eef5"
                    border.width: 1
                    border.color: root.failed ? "#e0443a" : root.live || root.fieldHot ? Kit.accent(1) : "#7eb4ea"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        // A shadow at alpha 0 still blooms; a shut field has none.
                        shadowEnabled: root.failed || root.live || root.fieldHot
                        shadowColor: root.failed ? "#f2ff3b30" : Kit.withA(Kit.cyan, root.live ? 0.95 : 0.6)
                        shadowBlur: 0.6
                        shadowScale: 1.02
                    }
                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 7
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        enabled: root.inputEnabled && (root.page === "password" || root.page === "failure")
                        color: "#000000"
                        font.family: root.fSys
                        font.pixelSize: 13
                        clip: true
                        cursorDelegate: Item {
                            width: 1
                            height: input.cursorRectangle.height
                            Rectangle { anchors.fill: parent; color: "#000000"; visible: root.inputEnabled && !(root.failed && input.text === "") }
                        }
                        onAccepted: root._submit()
                        onTextChanged: if (root.page === "failure" && text !== "") root.dismissFailure()
                        Keys.onPressed: event => {
                            var t = event.text
                            if (t.length === 1 && t.toUpperCase() !== t.toLowerCase())
                                root.capsLock = (t === t.toUpperCase()) !== !!(event.modifiers & Qt.ShiftModifier)
                            else if (event.key === Qt.Key_CapsLock)
                                root.capsLock = !root.capsLock
                        }
                    }
                    Text {
                        x: 9
                        width: field.width - 18
                        visible: input.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: 10
                        elide: Text.ElideRight
                        text: root.failed ? root.failureText : root.waiting ? "Please wait…" : root.prompt
                        color: root.failed ? "#d0281e" : "#8c8c8c"
                        font.family: root.fSys
                        font.pixelSize: 13
                    }
                    MouseArea { id: fieldHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                }
                Rectangle {
                    x: field.width + 6
                    width: 27
                    height: 27
                    radius: 13.5
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#e4fbff" }
                        GradientStop { position: 0.5; color: "#3fb6c9" }
                        GradientStop { position: 1.0; color: "#0f6d80" }
                    }
                    border.width: 1
                    border.color: "#e8fdff"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Kit.withA(Kit.cyan, arrowMa.containsMouse ? 1 : 0)
                        shadowBlur: 0.7
                        shadowScale: 1.1
                    }
                    Shape {
                        anchors.fill: parent
                        visible: !root.waiting
                        ShapePath {
                            strokeColor: "#ffffff"
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: "M 9.5 13.5 H 17 M 13.5 9.5 L 17.5 13.5 L 13.5 17.5" }
                        }
                    }
                    Repeater {
                        model: root.waiting ? 8 : 0
                        Rectangle {
                            required property int index
                            readonly property real a: index * Math.PI / 4 + waitTurn.angle
                            width: 3.5; height: 3.5; radius: 1.75
                            x: 13.5 + Math.cos(a) * 7 - 1.75
                            y: 13.5 + Math.sin(a) * 7 - 1.75
                            color: Kit.white(0.3 + 0.7 * index / 7)
                        }
                    }
                    QtObject {
                        id: waitTurn
                        property real angle: 0
                        property NumberAnimation spin: NumberAnimation {
                            target: waitTurn; property: "angle"
                            from: 0; to: Math.PI * 2; duration: 900
                            loops: Animation.Infinite
                            running: root.waiting && root.panelShown
                        }
                    }
                    MouseArea {
                        id: arrowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.inputEnabled
                        onClicked: root._submit()
                    }
                }

                // Win7's Caps Lock balloon, pointing up at the field.
                Item {
                    id: capsBalloon
                    x: 8
                    y: field.height + 9
                    z: 5
                    width: capsCol.implicitWidth + 50
                    height: capsCol.implicitHeight + 16
                    opacity: root.capsLock && root.live ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Shape {
                        x: 18; y: -8
                        width: 16; height: 9
                        ShapePath {
                            strokeColor: Kit.dark(0.55)
                            fillColor: "#fdfdfd"
                            PathSvg { path: "M0 9 L8 0.5 L16 9" }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        border.width: 1
                        border.color: Kit.dark(0.55)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#fdfdfd" }
                            GradientStop { position: 1.0; color: "#e4ecf3" }
                        }
                    }
                    Rectangle { x: 19; y: 0; width: 14; height: 1.5; color: "#fdfdfd" }
                    Shape {
                        x: 10; y: 9
                        width: 22; height: 20
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: "#9a6a00"
                            strokeWidth: 1
                            joinStyle: ShapePath.RoundJoin
                            fillGradient: LinearGradient {
                                x1: 0; y1: 0; x2: 0; y2: 20
                                GradientStop { position: 0; color: "#ffe680" }
                                GradientStop { position: 1; color: "#f2b600" }
                            }
                            PathSvg { path: "M11 1 L21 19 H1 Z" }
                        }
                        ShapePath {
                            strokeColor: "transparent"
                            fillColor: "#2a1d00"
                            PathSvg { path: "M10 6.5 H12 L11.6 13.5 H10.4 Z M11 15 A1.2 1.2 0 1 1 10.99 15 Z" }
                        }
                    }
                    Column {
                        id: capsCol
                        x: 40; y: 8
                        Text { text: "Caps Lock is on"; color: "#1e1e1e"; font.family: root.fSys; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Text { text: "The password may be typed in the wrong case."; color: "#1e1e1e"; font.family: root.fSys; font.pixelSize: 11 }
                    }
                }
            }

            Item { width: 1; height: 2; visible: noteBox.visible }
            Item {
                id: noteBox
                visible: root.shownNote !== "" && (root.page === "password" || root.page === "failure")
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                height: noteText.implicitHeight + 12
                Glass {
                    anchors.fill: parent
                    radius: 4
                    alarm: root.noteIsError ? 0.6 : 0
                }
                Text {
                    id: noteText
                    anchors.centerIn: parent
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: root.shownNote
                    color: "#ffffff"
                    font.family: root.fSys
                    font.pixelSize: 13
                    style: Text.Raised
                    styleColor: "#99000000"
                }
            }

            Item { width: 1; height: 4; visible: switchBtn.visible }
            Item {
                id: switchBtn
                visible: root.showSwitchUser && (root.page === "password" || root.page === "failure")
                anchors.horizontalCenter: parent.horizontalCenter
                width: 150
                height: 30
                Glass {
                    anchors.fill: parent
                    radius: 4
                    glow: switchMa.containsMouse ? 0.8 : 0
                }
                Text {
                    anchors.centerIn: parent
                    text: "Switch User"
                    color: "#ffffff"
                    font.family: root.fSys
                    font.pixelSize: 13
                    style: Text.Raised
                    styleColor: "#99000000"
                }
                MouseArea {
                    id: switchMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.switchUser()
                }
            }
        }
    }

    // ── Welcome: a Mac OS 9 startup box with an Aero spinner ───────────────
    Item {
        id: welcomeBox
        width: 340
        height: 210
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.height * 0.05
        opacity: root.welcome ? 1 : 0
        visible: opacity > 0
        scale: 0.94 + 0.06 * opacity
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Rectangle { x: 4; y: 4; width: parent.width; height: parent.height; color: Kit.dark(0.25) }
        Rectangle { x: 1; y: 1; width: parent.width; height: parent.height; color: Kit.dark(0.55) }
        Rectangle {
            anchors.fill: parent
            border.width: 1
            border.color: root.pl.line
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#eeeeee" }
                GradientStop { position: 1.0; color: root.pl.face }
            }
        }
        Rectangle { x: 1; y: 1; width: parent.width - 2; height: 1; color: root.pl.hi }
        Rectangle { x: 1; y: 1; width: 1; height: parent.height - 2; color: root.pl.hi }
        Rectangle { x: 1; y: parent.height - 2; width: parent.width - 2; height: 1; color: root.pl.sh }
        Rectangle { x: parent.width - 2; y: 1; width: 1; height: parent.height - 2; color: root.pl.sh }

        Tile {
            size: 72
            useFace: root.lockMode
            anchors.horizontalCenter: parent.horizontalCenter
            y: 22
        }
        Text {
            id: welcomeText
            anchors.horizontalCenter: parent.horizontalCenter
            y: 108
            text: "Welcome"
            color: "#000000"
            font.family: root.fPlat
            font.pixelSize: 26
        }
        Item {
            id: spinner
            width: 30
            height: 30
            anchors.horizontalCenter: parent.horizontalCenter
            y: welcomeText.y + welcomeText.height + 10
            RotationAnimation on rotation {
                running: welcomeBox.visible
                loops: Animation.Infinite
                from: 0; to: 360; duration: 1100
            }
            Repeater {
                model: 10
                Rectangle {
                    required property int index
                    readonly property real a: index * Math.PI * 2 / 10
                    width: 6; height: 6; radius: 3
                    x: 15 + Math.cos(a) * 11 - 3
                    y: 15 + Math.sin(a) * 11 - 3
                    color: Kit.accent(0.15 + 0.85 * index / 9)
                    border.width: index > 6 ? 1 : 0
                    border.color: Kit.withA(Kit.cyan, 0.9)
                }
            }
        }
    }

    // ── the brand: the NixOS snowflake and its name, on every page ─────────
    Row {
        id: brand
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(root.height * 0.045)
        spacing: 12
        opacity: root.page === "attention" ? 1 : 0.75
        Behavior on opacity { NumberAnimation { duration: 280 } }
        Image {
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            height: 38
            sourceSize: Qt.size(76, 76)
            source: "file://" + root.aoideRoot + "/song/songbook/barcarolle/icons/brand/nix-snowflake.svg"
            visible: status === Image.Ready
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "NixOS"
            color: "#ffffff"
            font.family: root.fSys
            font.pixelSize: 28
            font.weight: Font.Light
            style: Text.Raised
            styleColor: "#66000000"
        }
    }

    // ── the tray: what the taskbar's notification area says, read-only ────
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    readonly property bool volKnown: !!root.sink && !!root.sink.audio
    readonly property var battery: UPower.displayDevice
    readonly property bool batKnown: !!root.battery && root.battery.ready && root.battery.isLaptopBattery
    readonly property real batPct: root.batKnown ? (root.battery.percentage <= 1 ? root.battery.percentage * 100 : root.battery.percentage) : 0
    readonly property bool netKnown: Networking.backend !== NetworkBackendType.None
    readonly property var netDev: {
        var ds = Networking.devices ? Networking.devices.values : []
        for (var i = 0; i < ds.length; i++) if (ds[i].connected) return ds[i]
        return null
    }
    readonly property string netLabel: !root.netDev ? "Not connected" : root.netDev.type === DeviceType.Wifi ? "Wi-Fi" : "Wired"

    Glass {
        id: tray
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        width: trayRow.implicitWidth + 28
        height: 42
        radius: 6
        Row {
            id: trayRow
            x: 14
            height: parent.height
            spacing: 16

            Rectangle {
                visible: root.layoutName !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: layoutText.implicitWidth + 10
                height: 18
                radius: 2
                color: Kit.dark(0.85)
                border.width: 1
                border.color: Kit.white(0.25)
                TrayText { id: layoutText; anchors.centerIn: parent; text: root.layoutName; font.pixelSize: 11; font.weight: Font.DemiBold; style: Text.Normal }
            }
            Row {
                visible: root.volKnown
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                TrayGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    name: !root.volKnown ? "" : root.sink.audio.muted ? "tray-vol-mute" : root.sink.audio.volume < 0.4 ? "tray-vol-low" : "tray-vol-high"
                }
                TrayText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.volKnown ? (root.sink.audio.muted ? "Muted" : Math.round(root.sink.audio.volume * 100) + "%") : ""
                }
            }
            Row {
                visible: root.netKnown
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                TrayGlyph { anchors.verticalCenter: parent.verticalCenter; name: root.netDev ? "tray-net-up" : "tray-net-down" }
                TrayText { anchors.verticalCenter: parent.verticalCenter; text: root.netLabel }
            }
            Row {
                visible: root.batKnown
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 12
                    Rectangle { width: 21; height: 12; radius: 2; color: Kit.dark(0.5); border.width: 1; border.color: "#ffffff" }
                    Rectangle { x: 21; y: 3.5; width: 2.5; height: 5; radius: 1; color: "#ffffff" }
                    Rectangle {
                        x: 2; y: 2
                        width: Math.max(1, 17 * root.batPct / 100)
                        height: 8
                        radius: 1
                        color: root.batPct <= 15 ? "#ff5a4a" : Kit.cyan
                    }
                }
                TrayText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.batPct) + "%" + (root.batKnown && root.battery.state === UPowerDeviceState.Charging ? " ⚡" : "")
                }
            }
            Rectangle {
                visible: root.layoutName !== "" || root.volKnown || root.netKnown || root.batKnown
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 26
                color: Kit.white(0.3)
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                TrayText { anchors.right: parent.right; text: Qt.formatTime(root.now, "h:mm AP") }
                TrayText { anchors.right: parent.right; text: Qt.formatDate(root.now, "ddd, MMM d") }
            }
        }
    }

    // ── Now Playing: a sidebar gadget under the tray, lock only, no controls
    readonly property var player: {
        var ps = Mpris.players ? Mpris.players.values : []
        var best = null
        for (var i = 0; i < ps.length; i++) {
            if (ps[i].isPlaying) return ps[i]
            if (!best) best = ps[i]
        }
        return best
    }
    readonly property string artUrl: {
        var u = root.player ? String(root.player.trackArtUrl || "") : ""
        return u.indexOf("file:") === 0 ? u : ""
    }
    Glass {
        id: nowPlaying
        anchors.top: tray.bottom
        anchors.topMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 16
        width: 300
        height: 112
        radius: 8
        opacity: root.lockMode && !!root.player && root.player.trackTitle !== "" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        TrayText {
            x: 14; y: 8
            text: "Now Playing" + (root.player && root.player.identity ? "  ·  " + root.player.identity : "")
            font.pixelSize: 11
            color: Kit.white(0.8)
        }
        Rectangle {
            id: art
            x: 14; y: 28
            width: 72; height: 72
            radius: 4
            color: Kit.dark(0.6)
            border.width: 1
            border.color: Kit.white(0.7)
            Image {
                id: artImage
                anchors.fill: parent
                anchors.margins: 3
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(132, 132)
                asynchronous: true
                source: root.artUrl
            }
            TrayText {
                anchors.centerIn: parent
                visible: artImage.status !== Image.Ready
                text: "♪"
                font.pixelSize: 34
                color: Kit.white(0.55)
            }
            Rectangle {
                x: 1; y: 1
                width: parent.width - 2
                height: parent.height * 0.45
                radius: 3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Kit.white(0.45) }
                    GradientStop { position: 1.0; color: Kit.white(0) }
                }
            }
        }
        Column {
            x: art.x + art.width + 12
            y: 30
            width: nowPlaying.width - x - 14
            spacing: 2
            TrayText {
                width: parent.width
                text: root.player ? root.player.trackTitle : ""
                font.pixelSize: 14
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            TrayText {
                width: parent.width
                text: root.player ? root.player.trackArtist : ""
                color: Kit.white(0.8)
                elide: Text.ElideRight
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            spacing: 3
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    anchors.bottom: parent.bottom
                    width: 3
                    radius: 1
                    color: Kit.cyan
                    height: 4
                    SequentialAnimation on height {
                        running: nowPlaying.visible && !!root.player && root.player.isPlaying
                        loops: Animation.Infinite
                        NumberAnimation { to: 6 + (index * 5) % 11; duration: 260 + index * 70 }
                        NumberAnimation { to: 3; duration: 300 + index * 50 }
                    }
                }
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
