# example-default-overrides.nix — the override discovery point.
#
# Copy to:  modules/overrides/default.nix
# Then:     nothing. It is named once, by `overrides = import ./overrides;` in
#           modules/default.nix.
# Replace:  nothing. This file is the whole mechanism.
#
# Every `*.nix` file beside it is a record. Names and paths only here — but a
# record IS imported by the constructor on every host, because matching means
# reading which dendrites it targets. What an unmatched record never costs is
# its work: `overlay` and the lane modules are functions, and nothing calls
# them. See example-override.nix.
#
# Empty is a real answer: the directory can hold nothing but this file.
let
  entries = builtins.readDir ./.;

  isRecord =
    name:
    entries.${name} == "regular" && name != "default.nix" && builtins.match ".*\\.nix" name != null;

  names = builtins.filter isRecord (builtins.attrNames entries);
in
builtins.listToAttrs (
  map (name: {
    name = builtins.substring 0 (builtins.stringLength name - 4) name;
    value = ./. + "/${name}";
  }) names
)
