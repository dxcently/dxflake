# Core Aoide: the `aoide.enable` switch and the A2A door's default, no paint.
#
# Aoide's nucleus (`nixosModules.nucleus`, an extra module on every host) is
# the option contract: `aoide.enable`, the enable facts
# (`aoide.quickshell.enable`, `aoide.stylix.enable`, …), `aoide.lyra.enable`,
# and so on. The service options come with their own catalogue entries:
# `aoide.a2a.*` is declared by `aoided`, and `aoide.secrets.*` by
# `aoide-secrets`. Every knob that varies per host
# (a2a.spawnAgent/spawnPath/discoveryAdvertise/tokenFile, secrets.members, …)
# is set by the host on the raw `aoide.*` namespace once those are in scope.
# The song is the exception: a host names it as `habit.song.declared`, and the
# songs hook sets `aoide.song` from that, so a host never writes `aoide.song`.
#
# ── Dependency ──────────────────────────────────────────────────────────────
# This dendrite sets `aoide.a2a.enable`, so it needs `aoide.a2a.*` declared,
# which means `aoided` selected. Select the `aoide` aggregation
# (modules/aggregations/aoide), which selects `aoided` with the rest of the
# service floor. Without `aoided`, evaluation fails with "The option
# `aoide.a2a' does not exist".
#
# ── What "core" means ────────────────────────────────────────────────────
#   aoide.enable     — Aoide is on for this host
#   aoide.a2a.enable — the A2A (Agent2Agent) door, loopback by default;
#                      a default, so a host that fronts a public relay
#                      (sakaki) turns the door off with a plain `false`
#
# ── Paint is NOT this dendrite's business ──────────────────────────────────
# Lyra (the rice/paint binary) and the Quickshell render surface come from
# selecting Aoide's lanes, which report themselves through two facts —
# `aoide.quickshell.enable` (the actual shell surface:
# bar/dock/notifications/…, set by the quickshell lane) and
# `aoide.lyra.enable` (installs the `lyra` binary; false by default, set
# `mkDefault true` by the painting lane). This dendrite never touches either,
# so they stay at their off-by-default value on every host that only imports
# this baseline — paint is a per-host opt-in laid on TOP of this baseline, by
# selecting Aoide's lanes in that host's own file, never inferred here.
#
# A host with no Aoide paint keeps dxflake's own compositor + stylix dendrites (the
# compositor selected by the shell aggregation, stylix by the host) painting its desktop; with the
# quickshell fact left off, aoided anchors to default.target and the door
# rides it (loopback only). Such a host must never ALSO select Aoide's
# compositor or stylix lane (catalogued here as `aoide-compositor` and
# `aoide-stylix`) beside dxflake's own Hyprland/Stylix dendrites.
# Setting `aoide.compositor.enable` or `aoide.stylix.enable` by hand is no
# substitute and paints nothing: facts are set by the lane that owns the
# thing. For stylix the two writers meet on
# `stylix.base16Scheme`, an attrs-merge leaf: nix eval stays clean and the two
# silently combine into a value neither author intended, so the failure shows
# up only at runtime. Two `services.greetd`/`services.displayManager.ly`
# definitions fail the same quiet way, leaving two login managers racing a tty
# rather than erroring at eval.
#
# The compositor pair no longer merges quietly. dxflake's dendrite sets
# `wayland.windowManager.hyprland.systemd.enable = false` and does the session
# handoff itself, guarded (see AGENTS.md, "The session handoff"), so a host
# that selected both would now hit a plain conflicting-definition error on that
# bool at eval instead of concatenating dxflake's `["--all"]` onto Aoide's five
# named `systemd.variables` and having dbus reject the mixed line at session
# start. Still do not select both — but it now tells you.
#
# The Quickshell lane and shellbridge (the lyra lane's
# `modules/dendrites/lyra/shellbridge.nix` in the Aoide input) have no such
# collision: they only need graphical-session.target and a compositor that
# imports WAYLAND_DISPLAY/HYPRLAND_INSTANCE_SIGNATURE into the user session,
# which either dxflake's own Hyprland dendrite OR Aoide's own compositor
# lane can provide. A host that takes Aoide's paint lanes instead leaves
# dxflake's Hyprland/Stylix dendrites unselected, so only one writer ever
# touches those leaf options; the rest of the desktop aggregation (pipewire,
# fonts, fcitx5, portals, ly login) does not collide and stays selected.
{ lib, ... }:
{
  config = {
    aoide.enable = true;
    aoide.a2a.enable = lib.mkDefault true;
  };
}
