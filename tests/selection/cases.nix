# Cases over dxflake's real registry and a real host, composed through habit.
# Each attribute is one case, evaluated on its own by tests/selection/run.sh.
# Composition itself is habit's and is tested there.
{ lib, habit }:
let
  composition = habit.lib.composition { inherit lib; };
  # The flake's own merged registry, so the cases see the Aoide catalogue
  # the hosts see (sakaki selects the aoide aggregation, whose members are
  # Aoide's dendrites).
  registry = (builtins.getFlake (toString ../..)).registry;

  sakaki = composition.evalSelection {
    inherit registry;
    host = ../../hosts/sakaki;
  };

  inventory = composition.inventoryOf {
    hostName = "sakaki";
    selection = sakaki;
  };

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

  # The registry is its own package-entry generator: a test passes a package list
  # and forces the catalogue, which runs the checks the real list runs.
  packageEntriesNamedByLastSegment =
    let
      c =
        (import ../../modules {
          packages = [
            "kdePackages.filelight"
            "vim"
          ];
        }).catalogue;
    in
    c ? filelight && c ? vim && !(c ? "kdePackages.filelight");

  packageEntriesClashWithHandWritten = builtins.attrNames (
    (import ../../modules { packages = [ "bash" ]; }).catalogue
  );

  packageEntriesListedTwice = builtins.attrNames (
    (import ../../modules {
      packages = [
        "hugo"
        "hugo"
      ];
    }).catalogue
  );

  packageEntriesSharedName = builtins.attrNames (
    (import ../../modules {
      packages = [
        "hugo"
        "kdePackages.hugo"
      ];
    }).catalogue
  );
}
