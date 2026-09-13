# The fixture catalogue and aggregations the selection cases select from.
# Deliberately includes implementations that throw when imported: that is how
# "an unselected file is never evaluated" is proved rather than asserted.
{ lib, composition }:
let
  catalogue = {
    homeonly = ./dendrites/homeonly;
    landmine = ./dendrites/landmine;
    notifications = ./dendrites/notifications;
    systemonly = ./dendrites/systemonly;
  };
in
{
  imports = [
    (composition.mkSchema { inherit catalogue; })
    ./aggregations.nix
  ];
}
