.pragma library

// The Trash backend's pure half. The launcher runs these argv arrays through Quickshell.Io Process (gio, argv
// only, never a shell string); this file only builds them, reads what gio printed, and labels it.

var uriPrefix = "trash:///"
var listArgv = ["gio", "list", "--hidden", "--print-uris", "--attributes=trash::orig-path,trash::deletion-date", uriPrefix]
var emptyArgv = ["gio", "trash", "--empty"]
function restoreArgv(uri) { return ["gio", "trash", "--restore", uri] }

// `gio list --print-uris --attributes=...` prints one record per entry: "<uri>\t<size>\t(<type>)\t<key>=<value> ...".
// The URI is escaped, so it never holds a raw tab or newline. A raw attribute value (the original path) can, so a
// line continues the record above it unless it opens a record: a URI, a size and a (type).
function parse(text) {
    var src = ("" + text).replace(/\n$/, "")
    var lines = src.length ? src.split("\n") : []
    var recs = [], cur = null
    for (var i = 0; i < lines.length; i++) {
        if (/^trash:\/\/\/[^\t]*\t\d+\t\(\w+\)\t/.test(lines[i])) {
            if (cur !== null) recs.push(cur)
            cur = lines[i]
        } else if (cur !== null) cur += "\n" + lines[i]
    }
    if (cur !== null) recs.push(cur)
    var out = []
    for (var r = 0; r < recs.length; r++) {
        var e = entry(recs[r])
        if (e) out.push(e)
    }
    out.sort(function (a, b) {
        var x = a.name.toLowerCase(), y = b.name.toLowerCase()
        return x < y ? -1 : (x > y ? 1 : 0)
    })
    return out
}

function entry(rec) {
    var t1 = rec.indexOf("\t")
    var t2 = t1 < 0 ? -1 : rec.indexOf("\t", t1 + 1)
    var t3 = t2 < 0 ? -1 : rec.indexOf("\t", t2 + 1)
    var uri = t1 < 0 ? rec : rec.substring(0, t1)
    if (uri.indexOf(uriPrefix) !== 0) return null
    var type = t2 < 0 ? "" : rec.substring(t2 + 1, t3 < 0 ? rec.length : t3)
    var attrs = t3 < 0 ? "" : rec.substring(t3 + 1)
    return {
        uri: uri,
        name: decode(uri.substring(uriPrefix.length)),
        dir: type === "(directory)",
        orig: field(attrs, "trash::orig-path"),
        when: field(attrs, "trash::deletion-date").trim()
    }
}

// A value runs from its "key=" to the next " trash::" key, or to the end of the record. The last "key=" wins: gio
// prints the deletion date after the original path, which may hold the same text.
function field(attrs, key) {
    var k = attrs.lastIndexOf(key + "=")
    if (k < 0) return ""
    var rest = attrs.substring(k + key.length + 1)
    var end = rest.search(/ trash::[a-z-]+=/)
    return end < 0 ? rest : rest.substring(0, end)
}

function decode(s) {
    try { return decodeURIComponent(s) } catch (e) { return s }
}

var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

// gio writes the deletion date in local time without a zone, which Date reads as local time too.
function when(iso) {
    var d = new Date(iso)
    if (!iso || isNaN(d.getTime())) return ""
    var h = d.getHours()
    return months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear() + "  "
        + (h % 12 || 12) + ":" + ("0" + d.getMinutes()).slice(-2) + (h < 12 ? " AM" : " PM")
}
