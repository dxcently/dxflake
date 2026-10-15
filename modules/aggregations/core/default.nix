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
# - `sops` is sops-nix, the module behind every `sops.*` option. Deselected, it is
#   not imported, so a host that keeps tailscale, cloudflared, syncthing or slskd
#   fails evaluation with "The option `sops' does not exist".
# - The package names are the floor every host carries: each is a catalogue
#   entry of its own (modules/dendrites/packages.nix), so one is dropped with
#   `habit.dendrites.<name>.enable = false` like any member.
{
  description = "The machine itself: bootloader, hostname and NetworkManager, the base packages, polkit and rtkit, the sops-nix secrets, and the Nix and locale settings.";

  system.members = [
    "boot"
    "networking"
    "security"
    "sops"
    "system"

    # The floor, one catalogue entry per package (modules/dendrites/packages.nix).
    "unrar"
    "unzip"
    "unar"
    "fd"
    "file"
    "xdg-utils"
    "bat"
    "cowsay"
    "fzf"
    "htop"
    "gptfdisk"
    "lshw"
    "usbutils"
    "lm_sensors"
    "v4l-utils"
    "clinfo"
    "poppler"
    "socat"
    "age"
    "ffmpeg"
    "yt-dlp"
    "vim"
    "neovide"
    "lazygit"
    "ripgrep"
    "jq"
    "curl"
    "wget"
    "godot"
    "arduino-ide"
    "typst"
    "tinymist"
    "nixfmt"
    "nix-tree"
    "ngrok"
    "nodejs"

    # Dendrites the floor used to be: the Jupyter environment and fastfetch.
    "python"
    "fastfetch"
  ];
}
