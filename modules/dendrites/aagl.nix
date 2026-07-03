{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  imports = [inputs.aagl.nixosModules.default];
  config = lib.mkIf config.dx.aggregations.gaming {
    nix.settings = inputs.aagl.nixConfig;
    programs = {
      honkers-railway-launcher.enable = true;
      anime-game-launcher.enable = false;
    };
  };
}
