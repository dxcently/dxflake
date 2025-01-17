{ pkgs, config, ... }:

{
  imports = [
    ./hyprland.nix
    ./kitty.nix
    ./swappy.nix
    ./waybar.nix
    ./yazi.nix
    ./bash.nix
    ./gtk-qt.nix
    ./fastfetch.nix
    ./neovim.nix
  ];
}
