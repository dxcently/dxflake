# A home-scope group: the same file is imported into both scopes and answers
# only in one, which is how a group owns both halves of its membership without
# leaking either into the other.
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
  options.aggregation.desk.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Select the desk group.";
  };

  config = mkIf (scope == "home" && config.aggregation.desk.enable) {
    dendrites.notifications = {
      enable = mkDefault true;
      provider = mkDefault "dunst";
    };
  };
}
