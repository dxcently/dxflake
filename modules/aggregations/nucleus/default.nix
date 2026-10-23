# nucleus — what every host carries: the machine itself, and the command line.
#
# An aggregation body is DATA: the members it selects in each half, the
# provider choices it exposes, and any preference that rides along. It declares
# no options and carries no gate; habit's composition wraps it in one. Members
# are named by CATALOGUE NAME, so they stay where they are in
# modules/dendrites/*.nix rather than being moved under this directory.
#
# `system.members` are the system half: a host that wants one gone says
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
# - The package names are the floor every host carries: each is a catalogue
#   entry of its own (modules/dendrites/packages.nix), so one is dropped with
#   `habit.dendrites.<name>.enable = false` like any member.
#
# `home.members` are the home half, sent to every Home Manager user of a host
# that selects nucleus: the prompt, editor, fuzzy history, and file and process
# browsers.
{
  description = "The machine every host carries: bootloader, hostname and NetworkManager, the base packages, polkit and rtkit, the sops-nix secrets, and the Nix and locale settings; and the command line: prompt, editor, fuzzy history, file and process browsers.";

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

    # Dendrites the floor used to be: the Jupyter environment, ffmpeg and fastfetch.
    "python"
    "ffmpeg"
    "fastfetch"
  ];

  home.members = [
    "bash"
    "btop"
    "direnv"
    "git"
    "mcfly"
    "neovim"
    "nh"
    "starship"
    "yazi"
  ];
}
