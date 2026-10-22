# rices/fugue/_widgets/default.nix — the widget-record roll-up.
#
# The only file in this shelf that names the rice. Every sibling `<slot>.nix`
# is a plain record that never types "fugue"; this file discovers them with
# `builtins.readDir` and binds `owner`/`slot` through `rice.mkWidget`. Returns
# the resolved `slot -> record` attrset that `rice.composeRice` expects.
#
# The shelf is underscore-prefixed, so `lib/rices.nix` prunes it from the
# module walk: it is score, not a module.
{ lib, rice, ... }:
let
  owner = "fugue";

  slotFiles = lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".nix" n && n != "default.nix") (
    builtins.readDir ./.
  );

  slotOf = n: lib.removeSuffix ".nix" n;
in
lib.mapAttrs' (
  n: _: lib.nameValuePair (slotOf n) (rice.mkWidget owner (slotOf n) (import (./. + "/${n}")))
) slotFiles
