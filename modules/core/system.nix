{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  environment.variables.EDITOR = "nvim";
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  nix = {
    /*
        nixPath = ["etc/nix/path"];
      registry = (lib.mapAttrs (_: flake: {inherit flake;})) (
        (lib.filterAttrs (_: lib.isType "flake")) inputs
      );
      environment = {
      etc =
        lib.mapAttrs' (name: value: {
          name = "nix/path/${name}";
          value.source = value.flake;
        })
        config.nix.registry;
    };
    */
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      substituters = [
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
  time = {
    timeZone = "America/New_York";
  };
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };
  #Don't ever change this lol
  system.stateVersion = "23.11";
}
