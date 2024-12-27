{ pkgs, config, ... }:

{
  imports = [
    ./hyprland.nix
    ./kitty.nix
    ./neovim.nix
    ./swappy.nix
    ./spicetify.nix
    ./waybar.nix
    ./yazi.nix
    ./bash.nix
    #./xdg.nix
    ./gtk-qt.nix
    ./neofetch.nix
    ./fastfetch.nix
  ];
}
