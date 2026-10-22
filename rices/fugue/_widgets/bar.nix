# fugue's `bar` slot — the always-visible top-edge lattice, hosted by
# shell.qml's PanelWindow. `kind` is absent → null: `bar` is a shell-anchored
# slot (`WidgetSlot { slot: "bar" }`, slots.md's own wired-slot table), never
# a declared `arrangement.widgets` entry.
#
# `dependsOn`: `ricemode` ONLY, despite two more real runtime dependencies —
# read this before adding either.
#
# widgets/bar.qml embeds `WidgetSlot { slot: "ricemode" }` (the rice-mode
# control, first cell of the right row). fugue authors that slot itself
# (`ricemode.nix`), so it is a key of this composition and `composeSong`'s
# closure holds. At runtime the slot still resolves through `StagingEngine`,
# which is how quodlibet's borrowed bar reaches fugue's body.
#
# The clef (powermenu) and the dock cell are not dependencies of this record.
# bar.qml asks the bridge for each (`bridge.component("powermenu", "toggle")`,
# `bridge.component("dock", "toggle")`), and the bridge runs whichever component
# fills the slot. No QML item is handed in, so no closure has to hold one.
#
# `shared`: declared, unused by fugue's own bar. `stagingEngine`: handed on to
# the embedded `ricemode` slot.
#
# The one `WidgetSlot` it embeds is `ricemode` — fugue's bar has no popout of
# its own, so no `calendar` dependency either.
#
# `helpers`: bar.qml instantiates `Cell` (fugue's own uppercase helper, this
# song's `qmldir` proof — `Cell.qml`).
_: {
  file = "bar.qml";

  dependsOn = [ "ricemode" ];

  helpers = [ "Cell.qml" ];
}
