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
    ../../modules/core/steam.nix
    ../../modules/core/aagl.nix
    ../../modules/core/virtualisation.nix
    ../../modules/core/services.nix
    ../../modules/core/desktop-services.nix
    ../../modules/core/syncthing.nix
    ../../modules/core/hermes.nix
    ../../modules/core/jellyfin.nix
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
    prismlauncher
    soundconverter
    winetricks
    udiskie
    r2modman
    filezilla
    openrazer-daemon
    polychromatic
    gpu-screen-recorder-gtk
    kdePackages.filelight
    tor-browser
    protontricks
    orca-slicer
  ];

  programs = {
    k3b.enable = true;
    gpu-screen-recorder.enable = true;
  };

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
    kernelParams = ["mitigations=off"];
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
    openrazer.enable = true;
  };
  #HIP
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];
}
