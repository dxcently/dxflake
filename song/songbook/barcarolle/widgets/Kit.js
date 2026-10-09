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

function bodyFont(px)  { return Qt.font({ family: family, pixelSize: px }) }
function boldFont(px)  { return Qt.font({ family: family, pixelSize: px, weight: 600 }) }
function heavyFont(px) { return Qt.font({ family: family, pixelSize: px, weight: 700 }) }
function lightFont(px) { return Qt.font({ family: family, pixelSize: px, weight: 300 }) }

function withA(c, a) { var q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }
function white(a) { return Qt.rgba(1, 1, 1, a) }
function dark(a) { return Qt.rgba(12 / 255, 33 / 255, 48 / 255, a) }

function className(w) { return (w && w.lastIpcObject && w.lastIpcObject["class"]) || "" }

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
    var d = ""
    for (var x = 63.8 - 4 * 340.5; x < w + 40; x += 340.5)
        d += "M" + x + " 0 L" + (x + 63.9) + " 0 L" + (x + 63.9 - 14.6) + " " + h + " L" + (x - 14.6) + " " + h + " Z "
    return d
}
