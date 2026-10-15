# Cases over dxflake's real registry and a real host, composed through habit.
# Each attribute is one case, evaluated on its own by tests/selection/run.sh.
# Composition itself is habit's and is tested there.
{ lib, habit }:
let
  composition = habit.lib.composition { inherit lib; };
  registry = import ../../modules;

  sakaki = composition.evalSelection {
    inherit registry;
    host = ../../hosts/sakaki;
  };

  inventory = composition.inventoryOf {
    hostName = "sakaki";
    selection = sakaki;
  };

  # The package-entry generator is the one the registry runs (modules/default.nix
  # calls it too). Forcing the names forces its checks.
  packageEntries =
    args: import ../../modules/packages-entries.nix ({ file = "fixture/packages.nix"; } // args);
in
{
  # The headless host selects exactly what its file names.
  realRegistryResolvesSakaki = builtins.concatStringsSep "," (builtins.attrNames inventory.dendrites);

  # Every module the selection kept resolves to a file that imports as a plain
  # module: an attribute set or a function, never a nixos/homeManager record.
  realRegistryModulesImport =
    let
      impls = lib.mapAttrsToList (name: d: composition.implOf sakaki.catalogue name d.provider) (
        lib.filterAttrs (_: d: d.enable) sakaki.dendrites
      );
      plain =
        i:
        let
          m = if i.path != null then import i.path else i.value;
        in
        builtins.isFunction m || (builtins.isAttrs m && !(m ? nixos || m ? homeManager));
    in
    impls != [ ] && builtins.all plain impls;

  # The groups the host reports.
  realRegistryInventory = builtins.concatStringsSep "," inventory.aggregation;

  packageEntriesNamedByLastSegment = builtins.concatStringsSep "," (
    builtins.attrNames (packageEntries {
      packages = [
        "kdePackages.filelight"
        "vim"
      ];
      handWritten = { };
    })
  );

  packageEntriesClashWithHandWritten = builtins.attrNames (packageEntries {
    packages = [ "bash" ];
    handWritten = {
      bash = ./dendrites/none;
    };
  });

  packageEntriesListedTwice = builtins.attrNames (packageEntries {
    packages = [
      "hugo"
      "hugo"
    ];
    handWritten = { };
  });

  packageEntriesSharedName = builtins.attrNames (packageEntries {
    packages = [
      "hugo"
      "kdePackages.hugo"
    ];
    handWritten = { };
  });
}
