# core — what every host carries to boot, name itself and run Nix.
#
# An aggregation body is DATA: the members it selects in the system half.
# Members are ordinary dendrites, so a host that wants one gone says
# `habit.dendrites.<name>.enable = false`, and these are the caveats:
#
# - `boot` is the bootloader. Deselected, the host has none unless it declares one.
# - `networking` is the hostName, NetworkManager, and the login account with its
#   authorized key. Deselected, the host is named "nixos" and that account is
#   not declared.
# - `system` is the time zone, locale, nix settings and substituters, the default
#   editor, dconf, and `nixpkgs.config.allowUnfree`. Deselected, all of them fall
#   back to the platform defaults. `system.stateVersion` is the host's own
#   (hosts/<name>/default.nix) whether or not `system` is selected.
{
  description = "The machine itself: bootloader, hostname and NetworkManager, the base packages, polkit and rtkit, and the Nix and locale settings.";

  system.members = [
    "boot"
    "networking"
    "packages"
    "security"
    "system"
  ];
}
