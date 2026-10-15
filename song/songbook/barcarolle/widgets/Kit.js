.pragma library

var family = "Noto Sans"

var barHeight = 40
var buttonWidth = 62
var emptyWidth = 40
var orbWidth = 54
var stripLeft = 58
var tickInterval = 1000

var ink = "#0c2130"
var cyan = "#77fffc"
var working = "#3bdcac"
var awaiting = "#e8cf6a"
var urgent = "#f2a65e"

var tray = { clock: 53, vol: 107, net: 131, flag: 155, agents: 179 }

function helper(name) { return Qt.resolvedUrl(name + ".qml") }

function bodyFont(px)  { return Qt.font({ family: family, pixelSize: px }) }
function boldFont(px)  { return Qt.font({ family: family, pixelSize: px, weight: 600 }) }
function heavyFont(px) { return Qt.font({ family: family, pixelSize: px, weight: 700 }) }
function lightFont(px) { return Qt.font({ family: family, pixelSize: px, weight: 300 }) }

function withA(c, a) { var q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
function white(a) { return Qt.rgba(1, 1, 1, a) }
function dark(a) { return Qt.rgba(12 / 255, 33 / 255, 48 / 255, a) }
function accent(a) { return Qt.rgba(37 / 255, 187 / 255, 207 / 255, a) }
function plate() { return Qt.rgba(245 / 255, 251 / 255, 251 / 255, 0.97) }
function rimTint() { return Qt.rgba(42 / 255, 163 / 255, 184 / 255, 0.58) }

function className(w) { return (w && ((w.lastIpcObject && w.lastIpcObject["class"]) || (w.wayland && w.wayland.appId))) || "" }

function scopeArgv(e) {
    var argv = ["systemd-run", "--user", "--scope", "--quiet", "--collect"]
    if (e.workingDirectory) argv.push("--working-directory=" + e.workingDirectory)
    argv.push("--")
    for (var i = 0; i < e.command.length; i++) argv.push(e.command[i])
    return argv
}

function make(livery) {
    var b = (livery && livery.raw && livery.raw.base16) ? livery.raw.base16 : {}
    function slot(n, fb) { return b[n] ? b[n] : fb }
    return {
        ink:      "#0c2130",
        text:     "#ffffff",
        accent:   "#77fffc",
        working:  slot("base0B", "#3bdcac"),
        awaiting: slot("base0A", "#e8cf6a"),
        urgent:   slot("base09", "#f2a65e")
    }
}

function ell(cx, cy, rx, ry, deg) {
    var a = deg * Math.PI / 180
    var dx = rx * Math.cos(a), dy = rx * Math.sin(a)
    var x1 = cx - dx, y1 = cy - dy, x2 = cx + dx, y2 = cy + dy
    return "M" + x1 + " " + y1 + " A" + rx + " " + ry + " " + deg + " 1 0 " + x2 + " " + y2
         + " A" + rx + " " + ry + " " + deg + " 1 0 " + x1 + " " + y1 + " Z"
}

function streaks(w, h) {
    var d = "", lean = 14.6 * h / 40
    for (var x = 63.8 - 4 * 340.5; x < w + 40 + lean; x += 340.5)
        d += "M" + x + " 0 L" + (x + 63.9) + " 0 L" + (x + 63.9 - lean) + " " + h + " L" + (x - lean) + " " + h + " Z "
    return d
}

var clef = "M3.66 7.39C2.52 8.49 1.32 9.69 0.57 11.14C0.18 11.89 0 12.67 0 13.48C0 15.24 0.9 16.85 2.38 17.76C3.13 18.22 3.91 18.46 4.71 18.46C5.11 18.46 5.49 18.42 5.82 18.32C5.86 18.53 5.96 19.01 6.14 19.75C6.32 20.49 6.39 21.02 6.39 21.33C6.39 22.63 5.63 23.54 4.35 23.54C3.82 23.54 3.45 23.36 3.21 23H3.35C4.09 23 4.6 22.42 4.6 21.76C4.6 20.98 4.06 20.33 3.28 20.33C2.37 20.33 1.87 20.99 1.87 21.88C1.87 23.13 2.9 24 4.34 24C5.74 24 6.87 23 6.87 21.6C6.87 21.13 6.85 20.94 6.68 20.11C6.46 18.97 6.32 18.29 6.28 18.14C7.73 17.61 8.47 16.39 8.47 14.97C8.47 13.12 7.18 11.53 5.5 11.53C5.4 11.53 5.22 11.54 4.95 11.58L4.46 9.26C5.88 7.95 6.71 5.93 6.71 3.95C6.71 2.9 6.53 1.97 6.14 1.18C5.75 0.39 5.45 0 5.22 0C4.71 0 3.92 1.08 3.56 2.18C3.34 2.83 3.21 3.59 3.21 4.46C3.21 5.46 3.39 6.42 3.66 7.39ZM4.03 7.04C3.89 6.68 3.76 6.19 3.76 5.6C3.76 3.87 4.57 2.08 5.47 2.08C5.97 2.08 6.15 2.49 6.15 3.16C6.15 4.41 4.86 6.58 4.03 7.04ZM4.82 13.23 5.74 17.86C5.31 17.97 4.95 18.06 4.57 18.06C2.51 18.06 0.97 16.45 0.97 14.65C0.97 13 1.94 11.33 4.09 9.6L4.49 11.7C3.37 12.15 2.58 13.33 2.58 14.51C2.58 15.63 3.37 16.61 4.43 16.86C4.52 16.84 4.57 16.81 4.57 16.78C4.57 16.7 4.49 16.66 4.36 16.6C4.25 16.55 4.12 16.45 4 16.35C3.66 16.06 3.38 15.51 3.38 15.05C3.38 14.2 4.06 13.4 4.82 13.23ZM6.17 17.72 5.25 13.18C6.53 13.18 7.52 14.15 7.52 15.34C7.52 16.55 7.07 17.33 6.17 17.72Z"

var hub = {}
