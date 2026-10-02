# Cases over dxflake's real registry and a real host, composed through habit.
# Each attribute is one case, evaluated on its own by tests/selection/run.sh.
# Composition itself is habit's and is tested there.
{ lib, habit }:
let
  composition = habit.lib.composition { inherit lib; };
  registry = import ../../modules;

  sakaki = composition.evalSelection {
    inherit registry;
    modules = [ ../../hosts/sakaki ];
  };
in
{
  # The headless host selects exactly what its file names.
  realRegistryResolvesSakaki = builtins.concatStringsSep "," (
    builtins.attrNames (
      composition.inventoryOf {
        hostName = "sakaki";
        selection = sakaki;
      }
    ).dendrites
  );

  # Every nixos lane file the selection kept imports.
  realRegistryLanesImport =
    let
      lanes = composition.lanesFor {
        inherit (sakaki) catalogue;
        selected = sakaki.dendrites;
        lane = "nixos";
        scope = "for the system";
      };
    in
    lanes != [ ] && builtins.all (m: builtins.isAttrs m || builtins.isFunction m || builtins.isPath m) lanes;

  # The groups the host reports.
  realRegistryInventory = builtins.concatStringsSep "," (
    composition.inventoryOf {
      hostName = "sakaki";
      selection = sakaki;
    }
  ).aggregation;
}
