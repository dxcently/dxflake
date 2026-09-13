{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.aagl.nixosModules.default];
  config = {
    nix.settings = inputs.aagl.nixConfig;
    programs = {
      honkers-railway-launcher.enable = true;
      anime-game-launcher.enable = false;
    };
  };
}
