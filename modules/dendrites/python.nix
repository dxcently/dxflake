# modules/dendrites/python.nix — the Jupyter environment, a member of `core`.
#
# Not a line in packages.nix: it is a python3 environment, and it must answer
# `python3` ahead of ros-env's. `lib.mkBefore` puts it first in system.path,
# where a file collision resolves first-wins.
{ lib, pkgs, ... }:
{
  environment.systemPackages = lib.mkBefore [ pkgs.jupyter ];
}
