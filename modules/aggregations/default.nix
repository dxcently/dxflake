# modules/aggregations/default.nix — shallow discovery, and nothing else.
#
# Every immediate child directory that holds a `default.nix` is an aggregation,
# named by its directory. This file produces `name = path`; it NEVER imports a
# body. `lib/composition.nix` imports only the bodies the host, or one of its
# users, selected — so an aggregation nobody selects is never read, and a body
# that throws on import proves it (tests/selection/aggregations/landmine).
#
# Discovery is one level deep on purpose. Dendrites are named by
# `modules/default.nix` because an implementation must never become reachable
# by dropping a file in a directory; an aggregation body is inert data whose
# only effect is the gate it answers, so its directory name is enough.
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
