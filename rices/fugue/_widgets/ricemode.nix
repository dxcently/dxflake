# fugue's `ricemode` slot -- the rice-mode control, embedded by bar.qml as
# `WidgetSlot { slot: "ricemode" }` in the right row. `kind` absent -> null:
# a bar-embedded WidgetSlot, never a declared `arrangement.widgets` entry.
# fugue dresses it itself rather than falling back to sonata's floor; it keeps
# the same bridge calls (riceMenu, riceMode, riceDraft).
#
# `dependsOn`: absent. ricemode.qml addresses no sibling slot.
#
# `helpers`: ricemode.qml instantiates `Cell` (fugue's own uppercase helper).
_: {
  file = "ricemode.qml";

  helpers = [ "Cell.qml" ];
}
