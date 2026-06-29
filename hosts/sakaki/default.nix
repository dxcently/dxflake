{ inputs, lib, config, pkgs, username, ... }: {
  imports = [
    ./hardware.nix
    ../../modules/core/system.nix
    ../../modules/core/networking.nix
    ../../modules/core/packages.nix
    ../../modules/core/user.nix
    ../../modules/core/services.nix
    ../../modules/core/jellyfin.nix
  ];

  home-manager.users.${username}.imports = [
    ../../modules/home/bash.nix
    ../../modules/home/git.nix
    ../../modules/home/neovim.nix
    ../../modules/home/yazi.nix
    ../../modules/home/btop.nix
    ../../modules/home/nh.nix
  ];

  networking.hostName = "sakaki";

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };
}
