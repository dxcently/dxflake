# Core Aoide (the aoide/aoided binaries, the A2A door, the secrets broker) —
# no paint.
#
# Aoide ships its own complete option contract (modules/nucleus/options.nix in
# the Aoide input, brought into every host by its `nixosModules.nucleus`):
# `aoide.enable`, `aoide.a2a.*`, `aoide.secrets.*`, the enable facts
# (`aoide.quickshell.enable`, `aoide.stylix.enable`, …), `aoide.lyra.enable`,
# and so on. This dendrite is not a second option surface over that contract — it
# is one import that turns on the CORE baseline every fleet box wants, so
# hosts.wiring stops repeating the same three flags. Every knob that
# genuinely varies per host (a2a.spawnAgent/spawnPath/discoveryAdvertise/
# tokenFile, secrets.members, …) is set by the host directly on the raw
# `aoide.*` namespace once this dendrite (or any aoide-carrying host) has put
# it in scope. The song is the exception: a host names it as `song.declared`
# on its record, and the songs hook sets `aoide.song` from that, so a host
# never writes `aoide.song` itself. Wrapping those in a parallel `dx.aoide.*` mirror would
# just rename Aoide's own documented options for no reason; convention here
# follows the option contract that already exists rather than inventing one.
#
# ── What "core" means ────────────────────────────────────────────────────
#   aoide.enable        — the aoide/aoided binaries + daemon (nucleus/aoided.nix)
#   aoide.a2a.enable     — the A2A (Agent2Agent) door, loopback by default
#   aoide.secrets.enable — the secrets broker (its own uid, group-gated socket;
#                          empty aoide.secrets.members means nobody can reach
#                          it yet — a host adds itself explicitly)
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
# A core-only host keeps dxflake's own compositor + stylix dendrites (selected
# by the shell and base aggregations) painting its desktop; with the
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
{
  nixos = {
    config = {
      aoide.enable = true;
      aoide.a2a.enable = true;
      aoide.secrets.enable = true;
    };
  };
}
