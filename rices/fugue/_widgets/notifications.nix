# fugue's `notifications` slot — the notification popup, hosted by shell.qml's
# `SurfaceSlot { slot: "notifications" }`. `kind` absent → null: shell-anchored,
# never a declared `arrangement.widgets` entry.
#
# `dependsOn`: absent. notifications.qml declares `required property var theme` and
# `bridge` only — no `WidgetSlot`, no `SurfaceSlot`, no sibling slot addressed
# anywhere but header prose.
#
# `helpers`: notifications.qml instantiates `Cell` (fugue's own uppercase helper).
_: {
  file = "notifications.qml";

  helpers = [ "Cell.qml" ];
}
