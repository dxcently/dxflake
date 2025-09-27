{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./../../modules/core
    ./../../modules/core/default.osaka.nix
  ];

  #host specific packages
  environment.systemPackages = with pkgs; [
    prismlauncher
    soundconverter
    winetricks
    udiskie
    r2modman
    #kdePackages.k3b
    filezilla
    firefox
    #cdrtools
  ];

  programs.k3b.enable = true;

  boot = {
    initrd.kernelModules = [
      "nvme"
      "amdgpu"
    ];
    kernelPackages = pkgs.linuxPackages;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };
  };

  services.xserver = {
    videoDrivers = ["amdgpu"];
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [amdvlk];
    extraPackages32 = with pkgs; [driversi686Linux.amdvlk];
  };

  #for k3b to work
  /*
  security.wrappers = {
    cdrdao = {
      setuid = true;
      owner = "root";
      group = "cdrom";
      permissions = "u+wrx,g+x";
      source = "${pkgs.cdrdao}/bin/cdrdao";
    };
    cdrecord = {
      setuid = true;
      owner = "root";
      group = "cdrom";
      permissions = "u+wrx,g+x";
      source = "${pkgs.cdrtools}/bin/cdrecord";
    };
  };
  */
}
