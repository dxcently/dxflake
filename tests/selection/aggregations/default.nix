# Shallow discovery, the same shape modules/aggregations/default.nix uses: names
# and paths, never a body. `landmine/` throws on import and sits right here, so
# a body that is discovered but not selected proves it was never read.
let
  entries = builtins.readDir ./.;
  names = builtins.filter (
    name: entries.${name} == "directory" && builtins.pathExists (./. + "/${name}/default.nix")
  ) (builtins.attrNames entries);
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = ./. + "/${name}";
  }) names
)
