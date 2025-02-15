{
  pkgs,
  config,
  inputs,
  home-manager,
  ...
}: {
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
    ./floorp.nix
    ./composekey.nix
    ./nh.nix
  ];
}
