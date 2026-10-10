.pragma library

var RANK = { awaiting: 0, working: 1, stopped: 2, idle: 3, done: 4 }
var ICONS = ["claude", "codex", "eidolon", "hermes", "kimi", "shell", "agent"]
var NICK = { claude: "#b5532f", codex: "#1d7a4f", kimi: "#4a4fc4", hermes: "#8a6a00", eidolon: "#2368b8", shell: "#4e5f6b", agent: "#1b8a99" }
var GROUP_H = 26, ROW_H = 37, KNOCK_H = 69, DAY = 86400000

function str(v) { return v === undefined || v === null ? "" : "" + v }
function ms(iso) { var t = Date.parse(str(iso)); return isNaN(t) ? 0 : t }
function rank(st) { var r = RANK[st]; return r === undefined ? 5 : r }
function iconName(agent) { return ICONS.indexOf(agent) >= 0 ? agent : "agent" }
function nickColor(agent) { return NICK[agent] || NICK.agent }
function isShell(s) { return s.kind === "shell" || s.agent === "shell" }
function nickOf(s) { return isShell(s) ? str(s.petname) : (str(s.title) || str(s.petname) || str(s.sessionId).slice(0, 8)) }
function dots(list) { return list.filter(function (x) { return x !== "" }).join(" · ") }

function parentIn(s, byId) {
    var p = str(s.parentSessionId)
    return p !== "" && p !== str(s.sessionId) && byId[p] ? byId[p] : null
}
function rootIn(s, byId) {
    var seen = {}, cur = s
    while (parentIn(cur, byId) && !seen[str(cur.sessionId)]) { seen[str(cur.sessionId)] = true; cur = parentIn(cur, byId) }
    return cur
}
function displayAgent(s, byId) {
    var a = s.kind === "subagent" ? str(rootIn(s, byId).agent) : str(s.agent)
    return a || "agent"
}
function groupOf(s, byId) {
    var r = rootIn(s, byId)
    return str(r.windowAddress) !== "" && typeof r.workspace === "number" ? "ws" + r.workspace : "else"
}

function tail(p, home) {
    var t = str(p)
    if (t === "") return ""
    if (home && (t === home || t.indexOf(home + "/") === 0)) t = "~" + t.slice(home.length)
    var segs = t.split("/").filter(function (x) { return x !== "" && x !== "~" })
    if (segs.length <= 2) return t
    return (t.charAt(0) === "~" ? "~" : "") + "/…/" + segs.slice(-2).join("/")
}
function ago(d) {
    var m = Math.max(0, Math.round(d / 60000))
    if (m < 1) return "now"
    if (m < 60) return m + "m"
    if (m < 1440) return Math.floor(m / 60) + "h"
    return Math.floor(m / 1440) + "d"
}
function fill(text, d) {
    var a = ago(d)
    return str(text).replace("%AGE% ago", a === "now" ? "just now" : a + " ago").replace("%AGE%", a)
}
function dur(a, b) {
    var m = Math.max(0, Math.round((ms(b) - ms(a)) / 60000))
    return m >= 60 ? Math.floor(m / 60) + "h " + (m % 60) + "m" : m + "m"
}
function hm(t) {
    var d = new Date(t), h = d.getHours() % 12 || 12, m = d.getMinutes()
    return h + ":" + (m < 10 ? "0" : "") + m
}
function toolName(t) { return str(t).split(":")[0].trim() }
function toolArg(t) { var s = str(t), i = s.indexOf(":"); return i >= 0 ? s.slice(i + 1).trim() : "" }
function pct(s) {
    if (s.contextTokens === undefined || s.contextTokens === null) return -1
    var t = Number(s.contextTokens), c = Number(s.contextCeiling)
    if (!(t >= 0) || !(c > 0)) return -1
    return Math.max(0, Math.min(100, Math.round(100 * t / c)))
}
function tone(p) { return p >= 85 ? "hot" : p >= 60 ? "warn" : "ok" }
function summonsCmd(body) { var b = str(body), i = b.lastIndexOf(" — "); return i >= 0 ? b.slice(0, i) : "" }
function summonsHandle(body) { var b = str(body), i = b.lastIndexOf(" — "); return i >= 0 ? b.slice(i + 3) : b }

function line2(s, tl) {
    var st = str(s.state)
    if (isShell(s)) {
        var mono = str(s.activity), rest = dots([tl, st === "idle" ? "idle %AGE%" : ""])
        return { pre: "", mono: mono, post: (mono !== "" && rest !== "" ? " · " : "") + rest, say: false }
    }
    var tn = toolName(s.tool), ta = toolArg(s.tool)
    if (st === "awaiting") return { pre: tn !== "" ? "asking · " : "asking", mono: tn, post: tl !== "" ? " · " + tl : "", say: false }
    if (st === "working") return { pre: "", mono: tn, post: (ta !== "" ? " " + ta : "") + (tl !== "" ? (tn !== "" || ta !== "" ? " · " : "") + tl : ""), say: false }
    if (st === "stopped" && str(s.say) !== "") return { pre: "", mono: "", post: "“" + str(s.say) + "”", say: true }
    if (st === "idle") return { pre: "", mono: "", post: dots(["idle %AGE%", tl]), say: false }
    if (st === "done") return { pre: "", mono: "", post: dots(["done %AGE% ago", tl]), say: false }
    return { pre: "", mono: "", post: tl, say: false }
}

function build(sessions, o) {
    var list = sessions || [], byId = {}, idx = {}, i, q
    o = o || {}
    for (i = 0; i < list.length; i++) { byId[str(list[i].sessionId)] = list[i]; idx[str(list[i].sessionId)] = i }
    var counts = { working: 0, awaiting: 0, stopped: 0, idle: 0, done: 0 }
    for (i = 0; i < list.length; i++) { var c = str(list[i].state); if (counts[c] !== undefined) counts[c]++ }
    function byRank(a, b) { return (rank(str(a.state)) - rank(str(b.state))) || (idx[str(a.sessionId)] - idx[str(b.sessionId)]) }
    var kids = {}, roots = []
    for (i = 0; i < list.length; i++) {
        var p = parentIn(list[i], byId)
        if (p) { var pk = str(p.sessionId); if (!kids[pk]) kids[pk] = []; kids[pk].push(list[i]) }
        else roots.push(list[i])
    }
    function flatten(s, sub, out, seen) {
        var id = str(s.sessionId)
        if (seen[id]) return
        seen[id] = true
        out.push({ s: s, sub: sub })
        var k = (kids[id] || []).slice().sort(byRank)
        for (var j = 0; j < k.length; j++) flatten(k[j], true, out, seen)
    }
    var groups = {}
    for (i = 0; i < roots.length; i++) {
        var key = groupOf(roots[i], byId)
        if (!groups[key]) groups[key] = { key: key, ws: key === "else" ? null : roots[i].workspace, roots: [] }
        groups[key].roots.push(roots[i])
    }
    var keys = Object.keys(groups).sort(function (a, b) {
        if (groups[a].ws === null) return 1
        if (groups[b].ws === null) return -1
        return groups[a].ws - groups[b].ws
    })
    var outG = [], outR = [], y = 0
    for (var g = 0; g < keys.length; g++) {
        var G = groups[keys[g]], flat = [], seen = {}
        G.roots.sort(byRank)
        for (q = 0; q < G.roots.length; q++) flatten(G.roots[q], false, flat, seen)
        var live = 0, wash = "", minis = []
        for (q = 0; q < flat.length; q++) {
            var fst = str(flat[q].s.state)
            if (fst === "working" || fst === "awaiting") live++
            if (fst === "awaiting") wash = "awaiting"
            else if (fst === "working" && wash === "") wash = "working"
            var ic = iconName(displayAgent(flat[q].s, byId))
            if (minis.length < 2 && minis.indexOf(ic) < 0) minis.push(ic)
        }
        var collapsed = !!(o.collapsed && o.collapsed[G.key])
        outG.push({ key: G.key, ws: G.ws, y: y, label: G.ws === null ? "Elsewhere" : "Workspace " + G.ws,
                    count: "(" + live + "/" + flat.length + ")", wash: wash, minis: minis, collapsed: collapsed })
        y += GROUP_H
        if (collapsed) continue
        for (q = 0; q < flat.length; q++) {
            var s = flat[q].s, sid = str(s.sessionId), state = str(s.state), ag = displayAgent(s, byId)
            var knock = null
            if (state === "awaiting") {
                var sm = o.summons ? o.summons[sid] : null
                if (o.answered && o.answered[sid] !== undefined) knock = { mode: "answered", cmd: str(o.answered[sid]) }
                else if (sm) knock = { mode: "verdict", cmd: summonsCmd(sm.body) || toolArg(s.tool) }
                else knock = { mode: "terminal", cmd: toolArg(s.tool) }
            }
            var pc = pct(s), h = knock ? KNOCK_H : ROW_H, l2 = line2(s, tail(s.cwd, o.home))
            var label = (isShell(s) ? "shell" : ag) + " · " + nickOf(s)
            outR.push({ sid: sid, y: y, h: h, sub: flat[q].sub, group: G.key, state: state,
                        icon: iconName(ag), label: label, word: state === "idle" ? "" : state,
                        pre: l2.pre, mono: l2.mono, post: l2.post, say: l2.say,
                        pct: pc, tone: pc < 0 ? "" : tone(pc),
                        activeMs: (o.activeAt && o.activeAt[sid]) || (o.hookAt && o.hookAt[sid]) || ms(s.startedAt),
                        clickId: G.ws === null ? "" : str(rootIn(s, byId).sessionId),
                        knock: knock, tip: G.ws === null ? { title: label, say: str(s.say) } : null })
            y += h
        }
    }
    return { groups: outG, rows: outR, height: y, counts: counts, total: list.length, byId: byId }
}

function lineJoin(s, byId) {
    var p = parentIn(s, byId)
    return { t: ms(s.startedAt) || Date.now(), kind: "join", glyph: "join", orb: "", nick: nickOf(s),
             color: nickColor(displayAgent(s, byId)), tool: "", text: p ? "joined · subagent of " + nickOf(p) : "joined",
             sid: str(s.sessionId) }
}
function lineLeave(r) {
    return { t: ms(r.endedAt), kind: "leave", glyph: "leave", orb: "", nick: str(r.title) || str(r.petname),
             color: nickColor(str(r.agent)), tool: "", text: "left · " + str(r.agent) + " · " + dur(r.startedAt, r.endedAt),
             sid: str(r.sessionId) }
}
function lineState(s, phase, at, byId) {
    if (phase !== "done" && phase !== "stopped") return null
    var say = str(s.say)
    return { t: ms(at) || Date.now(), kind: "state", glyph: "", orb: phase, nick: nickOf(s),
             color: nickColor(displayAgent(s, byId)), tool: "",
             text: phase === "done" ? "is done" : (say !== "" ? "stopped · “" + say + "”" : "stopped"), sid: str(s.sessionId) }
}
function lineHerald(n, byId) {
    var t = ms(n.receivedAt) || Date.now()
    if (str(n.kind) === "summons") {
        var s = byId[str(n.sessionId)]
        return { t: t, kind: "ask", glyph: "", orb: "awaiting", nick: s ? nickOf(s) : summonsHandle(n.body),
                 color: s ? nickColor(displayAgent(s, byId)) : NICK.claude, tool: str(n.summary).split(" · ")[0],
                 text: summonsCmd(n.body), sid: str(n.sessionId) }
    }
    if (str(n.app) === "notify-send")
        return { t: t, kind: "song", glyph: "song", orb: "", nick: str(n.summary), color: "#1b7f8f", tool: "",
                 text: str(n.body).replace(/\x60/g, ""), sid: "" }
    return { t: t, kind: "herald", glyph: "herald", orb: "", nick: str(n.summary), color: nickColor(str(n.app).toLowerCase()),
             tool: "", text: str(n.body), sid: "" }
}
function heraldKey(n) { return str(n.id) + "|" + str(n.receivedAt) }

function joins(seen, sessions, byId) {
    var lines = [], next = {}, k, i
    for (k in seen) next[k] = true
    for (i = 0; i < sessions.length; i++) {
        var id = str(sessions[i].sessionId)
        if (!next[id]) lines.push(lineJoin(sessions[i], byId))
        next[id] = true
    }
    return { lines: lines, seen: next }
}
function phases(seen, hooks, byId) {
    var lines = [], next = {}, k, i
    for (k in seen) next[k] = seen[k]
    for (i = 0; i < hooks.length; i++) {
        var id = str(hooks[i].sessionId), ph = str(hooks[i].phase).toLowerCase()
        if (next[id] !== ph && byId[id]) { var l = lineState(byId[id], ph, hooks[i].updatedAt, byId); if (l) lines.push(l) }
        next[id] = ph
    }
    return { lines: lines, seen: next }
}
function heralds(seen, notes, byId) {
    var lines = [], next = {}, k, i
    for (k in seen) next[k] = true
    for (i = 0; i < notes.length; i++) {
        var key = heraldKey(notes[i])
        if (!next[key]) lines.push(lineHerald(notes[i], byId))
        next[key] = true
    }
    return { lines: lines, seen: next }
}
function leaves(ledger, from, now) {
    var lines = []
    for (var i = Math.max(0, from); i < ledger.length; i++)
        if (now - ms(ledger[i].endedAt) <= DAY) lines.push(lineLeave(ledger[i]))
    return lines
}
function merge(feed, lines) {
    return feed.concat(lines).sort(function (a, b) { return a.t - b.t }).slice(-200)
}
