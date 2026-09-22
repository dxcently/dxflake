# example-dendrite.nix — a capability with ONE implementation.
#
# Copy to:  modules/dendrites/<capability>.nix
# Then:     add `<capability> = ./dendrites/<capability>.nix;` to the catalogue
#           in modules/default.nix, and select it from a host, a user, or an
#           aggregation's `members`.
# Replace:  <capability>, the packages, and everything under each lane.
#
# A dendrite is a plain attribute set naming the LANES it supports. A lane is a
# module for one evaluator:
#
#   nixos        the host's NixOS module — services, system packages, hardware
#   homeManager  one user's Home Manager module — dotfiles, user packages
#   darwin       nix-darwin; in the vocabulary, unused in this tree
#
# Expose only the lanes this capability really answers for. There are no empty
# stand-ins: selecting a lane a dendrite does not expose is an error naming the
# dendrite, the scope and the lanes it does support. Selecting it for the system
# does NOT select it for a user, and the reverse — `dendrites.<name>.enable` on
# the host reaches `nixos`, the same line under `users.<u>` reaches
# `homeManager`, and a capability that wants both is selected in both places.
#
# This file is imported only if something selected it. Nothing here runs at
# selection time.
{
  nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.jq ];
      services.example.enable = true;
    };

  # Optional. Drop this lane entirely for a system-only capability.
  #
  # A lane that outgrows one file moves out beside this one — `home.nix` or
  # `nixos.nix` in a directory of its own — and this file becomes
  #   { nixos = ./nixos.nix; homeManager = ./home.nix; }
  # with the dendrite catalogued as the DIRECTORY. Same contract, one file each.
  homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.jq ];
      programs.example.enable = true;
    };
}
