.pragma library

function isSummons(r) { return !!r && r.kind === "summons" }

function stamp(r) {
    var t = Date.parse(r.receivedAt)
    return isNaN(t) ? 0 : t
}

function key(r) { return r.id + "|" + r.receivedAt }

function lapseAt(r) {
    var t = r.timeoutMs | 0, s = stamp(r)
    return t > 0 && s > 0 ? s + t : 0
}

function ago(r, now) {
    var s = Math.floor((now - stamp(r)) / 1000)
    if (stamp(r) === 0) return ""
    if (s < 45) return "just now"
    if (s < 3600) return Math.round(s / 60) + " min ago"
    if (s < 86400) return Math.round(s / 3600) + " h ago"
    return Math.round(s / 86400) + " d ago"
}

function command(body) {
    var m = /^([A-Za-z][\w.-]{0,24}):\s+([\s\S]+)$/.exec("" + (body || ""))
    return m ? { label: m[1] + ":", code: m[2] } : { label: "", code: "" }
}

function newest(records) {
    var out = []
    for (var i = records.length - 1; i >= 0; i--)
        if (records[i] && records[i].id !== undefined) out.push(records[i])
    return out
}

function monoFont(px) { return Qt.font({ family: "Noto Sans Mono", pixelSize: px }) }

function bare(a) { return ("" + (a || "")).toLowerCase().replace(/^0x/, "") }

function place(s, tops) {
    if (!s) return ""
    var segs = ("" + (s.cwd || "")).split("/").filter(function (p) { return p !== "" })
    var out = segs.length ? [segs[segs.length - 1]] : []
    var addr = bare(s.windowAddress)
    for (var i = 0; addr !== "" && i < tops.length; i++)
        if (bare(tops[i].address) === addr && tops[i].workspace) {
            out.push("workspace " + ("" + tops[i].workspace.name).replace(/^special:/, ""))
            break
        }
    return out.join(" · ")
}
