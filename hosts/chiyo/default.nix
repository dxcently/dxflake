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
  ];

  #host specific packages
  environment.systemPackages = with pkgs; [
    arduino-ide
  ];

  #boot
  boot = {
    initrd.kernelModules = ["nvme"];
    kernelPackages = pkgs.linuxPackages;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };
    resumeDevice = "/dev/nvme0n1p3"; #hibernate
  };

  #services
  services = {
    #currently does not work
    /*
      fprintd = {
      enable = true;
      package = pkgs.fprintd-tod;
      tod = {
        enable = true;
        driver = pkgs.libfprint-2-tod1-elan;
      };
    };
    */
  };
  #laptop power management
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };
  networking.networkmanager.wifi.powersave = false;
  #hardware
  hardware = {
    bluetooth.enable = true;
  };
  #gpu
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [intel-vaapi-driver];
  };
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
