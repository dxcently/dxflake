# A second system-scope group, defaulting the same provider option to a
# different value. Enabling both must collide, not let import order decide.
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
in
{
  options.aggregation.kiosk.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Select the kiosk group.";
  };

  config = mkIf (scope == "system" && config.aggregation.kiosk.enable) {
    dendrites.notifications = {
      enable = mkDefault true;
      provider = mkDefault "herald";
    };
  };
}
