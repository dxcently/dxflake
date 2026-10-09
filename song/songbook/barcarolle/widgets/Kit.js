.pragma library

var family = "Noto Sans"

var barHeight = 40
var buttonWidth = 62
var orbSize = 36

function bodyFont(px)  { return Qt.font({ family: family, pixelSize: px }) }
function titleFont(px) { return Qt.font({ family: family, pixelSize: px, bold: true }) }

function withA(c, a) { var q = Qt.color(c); return Qt.rgba(q.r, q.g, q.b, a) }

function make(livery) {
    var b = (livery && livery.raw && livery.raw.base16) ? livery.raw.base16 : {}
    function slot(n, fb) { return b[n] ? b[n] : fb }
    return {
        glass:   slot("base00", "#0c2130"),
        raised:  slot("base01", "#1a3d4d"),
        select:  slot("base02", "#2a5a6d"),
        dim:     slot("base03", "#6a8f9c"),
        mid:     slot("base04", "#8db0ba"),
        text:    "#ffffff",
        glow:    livery.paletteAccent,
        accent:  slot("base0D", "#25bbcf"),
        working: slot("base0B", "#3bdcac"),
        urgent:  slot("base08", "#f47a72"),
        flag:    slot("base0C", "#4fd8e6")
    }
}
