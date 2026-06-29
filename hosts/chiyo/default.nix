{
  inputs,
  lib,
  config,
  pkgs,
  username,
  ...
}: {
  imports = [
    ./hardware.nix
    ../../modules/core/system.nix
    ../../modules/core/networking.nix
    ../../modules/core/security.nix
    ../../modules/core/packages.nix
    ../../modules/core/user.nix
    ../../modules/core/displaymanager.nix
    ../../modules/core/fonts.nix
    ../../modules/core/hardware.nix
    ../../modules/core/pipewire.nix
    ../../modules/core/fcitx5.nix
    ../../modules/core/stylix.nix
    ../../modules/core/xserver.nix
    ../../modules/core/thunar.nix
    ../../modules/core/services.nix
    ../../modules/core/desktop-services.nix
    ../../modules/core/syncthing.nix
    ../../modules/core/hermes.nix
  ];

  home-manager.users.${username}.imports = [
    ../../modules/home/bash.nix
    ../../modules/home/git.nix
    ../../modules/home/neovim.nix
    ../../modules/home/yazi.nix
    ../../modules/home/btop.nix
    ../../modules/home/nh.nix
    ../../modules/home/composekey.nix
    ../../modules/home/hyprland.nix
    ../../modules/home/waybar.nix
    ../../modules/home/kitty.nix
    ../../modules/home/rofi.nix
    ../../modules/home/stylix.nix
    ../../modules/home/gtk.nix
    ../../modules/home/qt.nix
    ../../modules/home/hyprlock.nix
    ../../modules/home/hyprpaper.nix
    ../../modules/home/wlogout.nix
    ../../modules/home/librewolf.nix
    ../../modules/home/vesktop.nix
    ../../modules/home/floorp.nix
    ../../modules/home/swappy.nix
    ../../modules/home/virtmanager.nix
    ../../modules/home/fastfetch/fastfetch.nix
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
