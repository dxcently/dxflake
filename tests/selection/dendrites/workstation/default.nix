# A system-scope group. Membership and provider choice are mkDefault, so an
# ordinary selection outranks them.
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
  options.aggregation.workstation.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Select the workstation group.";
  };

  config = mkIf (scope == "system" && config.aggregation.workstation.enable) {
    dendrites.systemonly.enable = mkDefault true;
    dendrites.notifications = {
      enable = mkDefault true;
      provider = mkDefault "dunst";
    };
  };
}
