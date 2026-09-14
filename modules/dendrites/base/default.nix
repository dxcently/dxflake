# The base group — what every host carries beyond the nucleus.
#
# A selection module: imported in pass one from ../default.nix, into both
# scopes. It owns its own gate, its membership in each scope, and nothing else.
# Membership is by catalogue name, so base's members stay where they are, in
# modules/dendrites/*.nix, rather than being moved under this directory.
#
# Membership is mkDefault: a host's ordinary selection outranks it, and two
# groups that default the same option to different values collide rather than
# letting import order pick a winner.
{
  lib,
  config,
  scope,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkDefault
    types
    ;

  members = names: {
    dendrites = lib.genAttrs names (_: {
      enable = mkDefault true;
    });
  };
in
{
  options.aggregation.base.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Shell, editor and prompt tooling every host carries.";
  };

  config = mkIf config.aggregation.base.enable (
    if scope == "system" then
      # stylix rides base on every host, including hosts that leave
      # `dx.stylix.enable` false: Aoide probes `options ? stylix`, so the option
      # tree has to exist even where nothing paints with it.
      members [ "stylix" ]
    else
      members [
        "bash"
        "btop"
        "direnv"
        "git"
        "mcfly"
        "neovim"
        "nh"
        "starship"
        "yazi"
      ]
  );
}
