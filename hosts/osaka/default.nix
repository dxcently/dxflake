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
