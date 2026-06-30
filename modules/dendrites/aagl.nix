{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [inputs.aagl.nixosModules.default];
  nix.settings = inputs.aagl.nixConfig;
  programs = {
    honkers-railway-launcher.enable = true;
    anime-game-launcher.enable = false;
  };
}
