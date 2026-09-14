# The gaming group — Steam, gamescope and the launchers.
#
# A selection module: imported in pass one from ../default.nix, into both
# scopes. Every member is a system capability; the home scope selects nothing,
# which is a real answer, not a placeholder.
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
  options.aggregation.gaming.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Steam, gamescope and the launchers.";
  };

  config = mkIf config.aggregation.gaming.enable (
    if scope == "system" then
      members [
        "aagl"
        "gaming-packages"
        "steam"
      ]
    else
      members [ ]
  );
}
