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
    filezilla
    firefox
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
    enable = true;
    videoDrivers = ["amdgpu"];
  };
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
  #HIP
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];
}
