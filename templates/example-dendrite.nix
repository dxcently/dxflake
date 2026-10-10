# example-dendrite.nix — a capability with ONE implementation.
#
# Copy to:  modules/dendrites/<capability>.nix
# Then:     add `<capability> = ./dendrites/<capability>.nix;` to the catalogue
#           in modules/default.nix, and select it from a host, a user, or an
#           aggregation's `members`.
# Replace:  <capability>, the packages, and the settings in each half.
#
# A dendrite is a plain NixOS module, written the way any module is. habit
# splits it into two halves:
#
#   the module as written   the system half — services, system packages,
#                           hardware
#   habit.home              the home half — one user's Home Manager module:
#                           dotfiles, user packages
#
# Neither half is required. A module with no `habit.home` has an empty home
# half and one with only `habit.home` has an empty system half; selecting it
# where it has nothing to say applies the empty half and fails nothing. Who
# selected it decides where the halves go: the host applies the system half and
# sends the home half to every user with `home.enable`, and a user applies the
# system half too and takes the home half alone.
#
# This file is imported only if something selected it. Nothing here runs at
# selection time.
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.jq ];
  services.example.enable = true;

  # Optional. Drop this for a system-only capability.
  #
  # A home half that outgrows one file moves beside this one — `home.nix` in a
  # directory of its own — and this file becomes
  #   { habit.home = ./home.nix; }
  # with the dendrite catalogued as the DIRECTORY. `habit.home` takes a path.
  habit.home =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.jq ];
      programs.example.enable = true;
    };
}
