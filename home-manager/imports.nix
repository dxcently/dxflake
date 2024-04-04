{ pkgs, config, ... }:

{
  imports = [
  ./kitty.nix
  ./neovim.nix
  ./swappy.nix
  ./spicetify.nix
  ./waybar.nix
  ./yazi.nix
  #./bash.nix
  ];
}
