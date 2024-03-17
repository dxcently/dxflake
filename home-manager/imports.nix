{ pkgs, config, ... }:

{
  imports = [
  ./kitty.nix
  ./neovim.nix
  ./swappy.nix
  ];
}
