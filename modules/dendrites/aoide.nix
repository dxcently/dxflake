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
# chiyo is the worked example (hosts/chiyo/default.nix): it enables this
# dendrite for the core baseline, then separately sets
# `aoide.facets.quickshell.enable` and `aoide.lyra.enable` itself. Notably it
# does NOT enable `aoide.facets.compositor` or `aoide.facets.stylix` — chiyo
# already runs dxflake's own Hyprland + Stylix dendrites
# (dx.aggregations.hyprland/desktop), and Aoide's compositor/stylix facets
# would fight them for the same options (Aoide's compositor facet sets its own
# `wayland.windowManager.hyprland.systemd.variables` and a second
# `extraConfig` block alongside dxflake's; its stylix facet assigns
# `stylix.base16Scheme` outright, which dxflake's stylix.nix already sets to a
# different scheme — two plain assignments to the same unique-merge leaf
# options, a guaranteed eval conflict, confirmed by reading both modules
# rather than assumed). The Quickshell facet and shellbridge
# (nucleus/shellbridge.nix) have no such dependency: they only need
# graphical-session.target and a compositor that imports WAYLAND_DISPLAY/
# HYPRLAND_INSTANCE_SIGNATURE into the user session, which dxflake's own
# Hyprland dendrite already provides. So a host with its own working desktop
# only needs quickshell + lyra to gain paint; the compositor/stylix facets
# exist for a host with no desktop of its own yet (yomi-strix's separate
# ~/Aoide flake is that case).
{ lib, config, ... }:
{
  options.dx.aoide.enable = lib.mkEnableOption "core Aoide (binaries + aoided + A2A door + secrets broker), no paint";

  config = lib.mkIf config.dx.aoide.enable {
    aoide.enable = true;
    aoide.a2a.enable = true;
    aoide.secrets.enable = true;
  };
}
