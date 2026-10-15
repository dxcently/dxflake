# modules/packages-entries.nix — the catalogue entries generated from a list of
# package paths, merged with the hand-written catalogue.
#
# A function of builtins only, called by modules/default.nix and by
# tests/selection/cases.nix alike, so the suite exercises the code the registry
# runs. `packages` is a list of `pkgs` attribute paths, `file` the path they came
# from (named in each entry's `_file`), and `handWritten` the catalogue they must
# not collide with. Forcing the result throws, naming the name, on a clash, a
# repeated path, or two paths that share a last segment.
{
  packages,
  file,
  handWritten,
}:
let
  # `kdePackages.filelight` is catalogue entry `filelight`.
  nameOf = path: baseNameOf (builtins.replaceStrings [ "." ] [ "/" ] path);
  count = x: list: builtins.length (builtins.filter (y: y == x) list);
  unique = list: builtins.foldl' (acc: x: if builtins.elem x acc then acc else acc ++ [ x ]) [ ] list;

  paths = unique packages;
  names = unique (map nameOf paths);

  clashing = builtins.filter (n: builtins.hasAttr n handWritten) names;
  listedTwice = builtins.filter (p: count p packages > 1) paths;
  sharing = builtins.filter (n: count n (map nameOf paths) > 1) names;

  entry = path: {
    _file = "${file}#${nameOf path}";
    imports = [
      (
        { pkgs, lib, ... }:
        {
          environment.systemPackages = lib.mkOrder 1400 [
            (lib.getAttrFromPath (lib.splitString "." path) pkgs)
          ];
        }
      )
    ];
  };

  generated = builtins.listToAttrs (
    map (path: {
      name = nameOf path;
      value = entry path;
    }) paths
  );

  checked =
    if clashing != [ ] then
      throw "${file}: '${builtins.head clashing}' names both a package line and a hand-written catalogue entry; rename one, or make the package a dendrite of its own"
    else if listedTwice != [ ] then
      throw "${file}: '${builtins.head listedTwice}' is listed twice; every package line needs its own path"
    else if sharing != [ ] then
      throw "${file}: ${
        builtins.concatStringsSep " and " (builtins.filter (p: nameOf p == builtins.head sharing) paths)
      } share the catalogue name '${builtins.head sharing}'; every package needs a distinct last segment"
    else
      generated;
in
handWritten // checked
