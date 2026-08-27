# Core Aoide (the aoide/aoided binaries, the A2A door, the secrets broker) —
# no paint.
#
# Aoide ships its own complete option contract (modules/nucleus/options.nix in
# the Aoide input, walked into every host's tree by flake.nix): `aoide.enable`,
# `aoide.a2a.*`, `aoide.secrets.*`, `aoide.facets.*`, `aoide.lyra.enable`, and
# so on. This dendrite is not a second option surface over that contract — it
# is one line (`dx.aoide.enable`) that turns on the CORE baseline every
# fleet box wants, so hosts.wiring stops repeating the same three flags. Every
# knob that genuinely varies per host (a2a.spawnAgent/spawnPath/
# discoveryAdvertise/tokenFile, secrets.members, aoide.song, …) is set by the
# host directly on the raw `aoide.*` namespace once this dendrite (or any
# aoide-enabled host) has put it in scope — exactly how sakaki and osaka
# already did before this dendrite existed. Wrapping those in a parallel
# `dx.aoide.*` mirror would just rename Aoide's own documented options for no
# reason; convention here follows the option contract that already exists
# rather than inventing one.
#
# ── What "core" means ────────────────────────────────────────────────────
#   aoide.enable        — the aoide/aoided binaries + daemon (nucleus/aoided.nix)
#   aoide.a2a.enable     — the A2A (Agent2Agent) door, loopback by default
#   aoide.secrets.enable — the secrets broker (its own uid, group-gated socket;
#                          empty aoide.secrets.members means nobody can reach
#                          it yet — a host adds itself explicitly)
#
# ── Paint is NOT this dendrite's business ──────────────────────────────────
# Lyra (the rice/paint binary) and the Quickshell render surface are gated by
# Aoide's own flags — `aoide.facets.quickshell.enable` (the actual shell
# surface: bar/dock/notifications/…) and `aoide.lyra.enable` (installs the
# `lyra` binary; defaults to following the quickshell facet, independently
# overridable). This dendrite never touches either, so they stay at their
# off-by-default value on every host that only flips `dx.aoide.enable` — paint
# is a per-host opt-in laid on TOP of this baseline, in that host's own file,
# never inferred here.
#
# osaka is the worked example of core-only (hosts/osaka/default.nix): it
# enables this dendrite for the core baseline and sets nothing else under
# `aoide.*` — dxflake's own Hyprland + Stylix dendrites
# (dx.aggregations.hyprland/desktop) keep painting osaka's desktop, so with
# the quickshell facet left off, aoided anchors to default.target and the
# door rides it (loopback only). A host in this shape must never ALSO flip
# `aoide.facets.compositor` or `aoide.facets.stylix` beside dxflake's own
# Hyprland/Stylix dendrites: both pairs write the same unique-merge leaf
# options (`wayland.windowManager.hyprland.systemd.variables`,
# `stylix.base16Scheme`), and because those options are list-concat/attrs-merge
# rather than a single value, nix eval stays clean — the two writers silently
# combine into a value neither author intended, and the failure shows up only
# at runtime (systemd.variables concatenates dxflake's `["--all"]` with
# Aoide's five named vars, and dbus rejects the mixed "--all + names" line at
# session start; two `services.greetd`/`services.displayManager.ly`
# definitions would similarly leave two login managers racing a tty rather
# than erroring at eval).
#
# The Quickshell facet and shellbridge (nucleus/shellbridge.nix) have no such
# collision: they only need graphical-session.target and a compositor that
# imports WAYLAND_DISPLAY/HYPRLAND_INSTANCE_SIGNATURE into the user session,
# which either dxflake's own Hyprland dendrite OR Aoide's own compositor
# facet can provide. chiyo (hosts/chiyo/default.nix) is the other shape: it
# runs the full Aoide paint stack (`aoide.facets.compositor`,
# `aoide.facets.stylix`, `aoide.facets.quickshell`, `aoide.hyprland.enable`)
# and turns dxflake's own Hyprland/Stylix dendrites OFF
# (`dx.aggregations.hyprland = false`, `dx.stylix.enable = false`) so only one
# writer ever touches those leaf options — `dx.aggregations.desktop` stays on
# for the pieces that don't collide (pipewire, fonts, fcitx5, portals, ly
# login).
{ lib, config, ... }:
{
  options.dx.aoide.enable = lib.mkEnableOption "core Aoide (binaries + aoided + A2A door + secrets broker), no paint";

  config = lib.mkIf config.dx.aoide.enable {
    aoide.enable = true;
    aoide.a2a.enable = true;
    aoide.secrets.enable = true;
  };
}
