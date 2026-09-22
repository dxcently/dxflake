# modules/overrides/default.nix — discovery, one level deep.
#
# Every `*.nix` file beside this one is an override record: a fix that belongs
# to a capability rather than to a host. Names and paths only — but unlike an
# aggregation body, a record IS imported on every host, because matching means
# reading which dendrites it targets. What an unmatched record never costs is
# its work: `overlay` and the lane modules are functions, and nothing calls
# them. See lib/composition.nix for the boundary stated exactly.
#
# Empty is a real answer. This tree ships no live record.
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
