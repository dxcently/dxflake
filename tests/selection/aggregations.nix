# Fixture aggregations, instantiated once per scope from one file — the shape
# modules/aggregations.nix uses. Membership and shared preferences use
# mkDefault, so an ordinary selection outranks them and two aggregations that
# disagree at equal priority collide instead of one quietly winning on import
# order. workstation and kiosk steer the system scope; desk steers a user's.
scope:
{ lib, config, ... }:
let
  inherit (lib)
    mkIf
    mkOption
    mkDefault
    types
    ;
  enableOption =
    name:
    mkOption {
      type = types.bool;
      default = false;
      description = "Select the ${name} aggregation.";
    };
in
{
  options.aggregations = {
    workstation.enable = enableOption "workstation";
    kiosk.enable = enableOption "kiosk";
    desk.enable = enableOption "desk";
  };

  config = lib.mkMerge [
    (mkIf (scope == "system" && config.aggregations.workstation.enable) {
      dendrites.systemonly.enable = mkDefault true;
      dendrites.notifications = {
        enable = mkDefault true;
        provider = mkDefault "dunst";
      };
    })
    (mkIf (scope == "system" && config.aggregations.kiosk.enable) {
      dendrites.notifications = {
        enable = mkDefault true;
        provider = mkDefault "herald";
      };
    })
    (mkIf (scope == "home" && config.aggregations.desk.enable) {
      dendrites.notifications = {
        enable = mkDefault true;
        provider = mkDefault "dunst";
      };
    })
  ];
}
