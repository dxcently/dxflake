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

    # Optional. A preference or a package that belongs with the group rather
    # than with any one member. An ordinary NixOS module, evaluated only in the
    # platform pass — never during selection.
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.jq ];
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
