# Fixture aggregations. Membership and shared preferences use mkDefault, so a
# host's ordinary selection outranks them and two aggregations that disagree at
# equal priority collide instead of one quietly winning on import order.
# workstation and kiosk steer the system scope; desk steers one user's, which
# is the shape a real desktop aggregation uses.
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
    (mkIf config.aggregations.workstation.enable {
      dendrites.systemonly.enable = mkDefault true;
      dendrites.notifications = {
        enable = mkDefault true;
        provider = mkDefault "dunst";
      };
    })
    (mkIf config.aggregations.kiosk.enable {
      dendrites.notifications = {
        enable = mkDefault true;
        provider = mkDefault "herald";
      };
    })
    (mkIf config.aggregations.desk.enable {
      users.alice.homeManager.enable = mkDefault true;
      users.alice.dendrites.notifications = {
        enable = mkDefault true;
        provider = mkDefault "dunst";
      };
    })
  ];
}
