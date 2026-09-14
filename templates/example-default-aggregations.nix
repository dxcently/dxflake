# example-default-aggregations.nix — the aggregation discovery file.
#
# Copy to:  modules/aggregations/default.nix
# Replace:  nothing. This file is complete as written; it exists here so a new
#           tree can be stood up from the templates alone.
#
# Every immediate child directory holding a `default.nix` is an aggregation,
# named by its directory. This produces `name = path` and NEVER imports a body:
# the constructor imports only the ones a host or one of its users selected.
#
# Discovery is one level deep on purpose, and it is the only filesystem read in
# the whole tree. Dendrites are named by modules/default.nix instead, because an
# implementation must never become reachable by dropping a file in a directory;
# an aggregation body is inert data whose only effect is the gate it answers, so
# its directory name is enough. A directory here is discovered, not enabled —
# nothing happens until a host selects it by name.
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
