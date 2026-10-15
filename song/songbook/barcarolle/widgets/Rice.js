.pragma library

// The RICE menu's rows, for every surface that offers them (the G3, the Start menu).
// A surface paints rows and calls act(); it never decides what a row means.
// `answer` is bridge.riceMenu's reply, `mode` is livery.riceMode.
// A row: { label, mark ("✓" in force, "○" where staging returns, ""), live, kind, name, here }.

function ready(answer) { return !!answer && answer.ok === true }

function waiting(answer) {
    return { label: !answer ? "…" : "" + (answer.message || "no answer"), mark: "", live: false, kind: "", name: "", here: false }
}

// every song in the runtime songbook, then the declared build (kind "declarative", the last row)
function switchRows(answer, mode) {
    if (!ready(answer)) return [waiting(answer)]
    var rows = []
    var songs = Array.isArray(answer.songs) ? answer.songs : []
    for (var i = 0; i < songs.length; i++) {
        var name = "" + songs[i].name
        var here = mode === "staging" && name === answer.song
        var back = mode === "declarative" && name === answer.stagingSong
        rows.push({ label: songs[i].ok ? name : name + " · unreadable", mark: here ? "✓" : (back ? "○" : ""),
                    live: !!songs[i].ok, kind: "stage", name: name, here: here })
    }
    var decl = mode === "declarative"
    rows.push({ label: "Declarative" + (answer.declared ? ": " + answer.declared : ""), mark: decl ? "✓" : "",
                live: true, kind: "declarative", name: "", here: decl })
    return rows
}

// the staged song's saved drafts (answer.draftsSong names it)
function draftRows(answer) {
    if (!ready(answer)) return [waiting(answer)]
    var drafts = Array.isArray(answer.drafts) ? answer.drafts : []
    return drafts.map(function (d) {
        return { label: "" + d.name, mark: d.current ? "✓" : "", live: true, kind: "enter", name: "" + d.name, here: !!d.current }
    })
}

function newDraft() { return { label: "New Draft", mark: "", live: true, kind: "new", name: "", here: false } }

// a draft's delete row (offered from the draft row's context menu); not live on the draft in force
function dropDraft(draft) {
    return { label: "Delete " + draft.name, mark: "", live: !draft.here, kind: "drop", name: "" + draft.name, here: false }
}

function saveDraft(mode) { return { label: "Save as Draft", mark: "", live: mode === "staging", kind: "save", name: "", here: false } }

// runs a row; true when the surface should show "…" until the livery's mode/song/draft changes (or 10 s pass);
// save and drop change none of those, so they never wait
function act(bridge, row) {
    if (!row.live || row.here || row.kind === "") return false
    if (row.kind === "stage") bridge.riceMode("stage", row.name)
    else if (row.kind === "declarative") bridge.riceMode("declarative")
    else bridge.riceDraft(row.kind, row.name)
    return row.kind !== "save" && row.kind !== "drop"
}
