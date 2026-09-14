# The hyprland group — the compositor and the surfaces dxflake draws on it.
#
# A selection module: imported in pass one from ../default.nix, into both
# scopes. The compositor ITSELF is an ordinary capability and lives beside this
# file in compositor.nix, named by the catalogue as `hyprland`; this file only
# selects it. Same name, two different things, two different passes — that is
# why the implementation moved out of default.nix.
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
  options.aggregation.hyprland.enable = mkOption {
    type = types.bool;
    default = false;
    description = "The Hyprland compositor and the surfaces dxflake draws on it.";
  };

  config = mkIf config.aggregation.hyprland.enable (
    if scope == "system" then
      members [
        "hyprland"
        "hyprland-packages"
      ]
    else
      members [
        "rofi"
        "satty"
        "waybar"
        "wlogout"
      ]
  );
}
