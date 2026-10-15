# core — what every host carries to boot, name itself and run Nix.
#
# An aggregation body is DATA: the members it selects in the system half.
# Members are ordinary dendrites, so a host that wants one gone says
# `habit.dendrites.<name>.enable = false`, and these are the caveats:
#
# - `boot` is the bootloader. Deselected, the host must declare its own, or
#   evaluation fails.
# - `networking` is the hostName, NetworkManager, the wg0 WireGuard config, the
#   firewall line, one authorized key on the login account (the account itself
#   comes from users/khoa.nix), and the network-manager-applet and
#   wireguard-tools packages. Deselected, the hostName is "nixos", NetworkManager
#   and wg0 are gone, that key is gone, and both packages are gone. The firewall
#   line goes too, but NixOS defaults the firewall on, so it stays up.
# - `system` is the time zone, the locale categories, nix settings and
#   substituters, the default editor, dconf, and `nixpkgs.config.allowUnfree`.
#   Deselected, the time zone is unset, unfree packages are refused, and the rest
#   fall back to the platform defaults. `system.stateVersion` is the host's own
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
