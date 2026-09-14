# example-aggregation.nix — a named group of capabilities.
#
# Copy to:  modules/aggregations/<group>/default.nix
# Then:     nothing. modules/aggregations/default.nix discovers every immediate
#           child directory that holds a default.nix — there is no collector
#           line to add and no catalogue entry. Select it with
#           `aggregation.<group>.enable = true;` on a host, or the same line
#           under `users.<u>` for that person's home half.
# Replace:  <group>, the description, and both membership halves.
#
# An aggregation body is DATA. It declares no options, carries no `mkIf`, and
# never imports the capabilities it names — it names them by CATALOGUE NAME and
# the constructor imports whichever survived selection. Keep it small: profile
# membership plus what genuinely rides along. Service implementation belongs in
# the dendrite.
#
# A body is imported only if this host, or one of its users, selected it. A
# group nobody selects is discovered by name and never read.
{
  # Shown on the generated `aggregation.<group>.enable` option.
  description = "One line: what selecting this group gets you.";

  # The half that answers for the HOST. `aggregation.<group>.enable = true` in
  # hosts/<host>/default.nix selects exactly these.
  system = {
    # Single-implementation members: catalogue names, nothing else.
    members = [
      "exampletool"
      "examplebar"
    ];

    # Provider-bearing members. The key is the catalogue name, the value is the
    # shared default — and each key becomes a selector on this group's own
    # interface, which is where a host states its choice:
    #
    #   aggregation.<group> = {
    #     enable = true;
    #     compositor.provider = "niri";   # this host differs
    #   };
    #
    # `null` means the group has no opinion and every host that selects it must
    # say which implementation it wants; a host that forgets is named in the
    # error along with the providers that exist.
    providers.compositor = null;

    # ── When a member only ONE provider can run ──────────────────────────────
    # Membership is static: this list is the same whatever `providers.compositor`
    # resolves to. So a member that only works under one implementation — a
    # plugin compiled against it, a config written in its own language — must
    # NOT be named here, or picking a different provider would evaluate it
    # anyway.
    #
    # Give those members a group of their own, beside this one, and let the host
    # select both. `modules/aggregations/hyprland/` is the worked example: it
    # holds what only Hyprland can run, `shell` holds what any wlroots
    # compositor can, and a host on another compositor selects `shell` alone.
    # tests/selection's `backendAggregationIsInert` proves the separation
    # against a member that throws on import.

    # ── What the group INSTALLS ─────────────────────────────────────────────
    # Not membership. A package list answers no question a host could answer
    # differently, so it gets no catalogue line and is not a dendrite — it goes
    # here, in the group's own half. Long lists earn a ./packages.nix beside
    # this file (`imports = [ ./packages.nix ];`); short ones stay inline.
    #
    # `mkAfter` because system.path resolves file collisions first-wins: order
    # the group's convenience list last and it can never shadow a capability a
    # host actually selected. An ordinary NixOS module, evaluated only in the
    # platform pass — never during selection.
    nixos =
      { pkgs, lib, ... }:
      {
        environment.systemPackages = lib.mkAfter [ pkgs.jq ];
        boot.kernel.sysctl."vm.max_map_count" = 2147483642;
      };
  };

  # The half that answers for a PERSON. `users.<u>.aggregation.<group>.enable`
  # selects these into that user's home lane. Same file, same name, two halves
  # that never leak into each other. Drop this whole attribute for a group with
  # nothing to say about a user — an absent half is a real answer.
  home = {
    members = [ "examplewidget" ];

    # A per-user daemon: the choice belongs to the person, so the selector
    # appears under `users.<u>.aggregation.<group>`. "mako" is the shared
    # default and any user may name the other one instead.
    providers.notifications = "mako";

    # Optional, and the home-lane twin of `system.nixos`.
    homeManager =
      { lib, ... }:
      {
        programs.example.fontSize = lib.mkDefault 12;
      };
  };
}
