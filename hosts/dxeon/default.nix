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

  nixpkgs = {
    config = {
      allowUnfree = true;
      #permittedInsecurePackages = [ "electron-25.9.0" ];
    };
  };

  #host specific packages
  environment.systemPackages = with pkgs; [
    prismlauncher
    soundconverter
    winetricks
    udiskie
    nvtop-amd
    r2modman
    kdePackages.k3b
  ];

  nix = {
    nixPath = ["/etc/nix/path"];
    registry = (lib.mapAttrs (_: flake: {inherit flake;})) (
      (lib.filterAttrs (_: lib.isType "flake")) inputs
    );
    #hyprland rebuild optimization, flakes, auto gc
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };

  #enable networking
  networking = {
    #change if changing hostname
    hostName = "dxeon";
    networkmanager.enable = true;
  };

  #boot
  boot = {
    initrd.kernelModules = [
      "nvme"
      "amdgpu"
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

  #managing users
  users.users = {
    khoa = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      extraGroups = [
        "wheel"
        "networkmanager"
        "libvirtd"
        "audio"
        "video"
        "docker"
        "cdrom"
      ];
    };
  };

  #services
  services = {
    syncthing = {
      enable = true;
      user = "khoa";
      dataDir = "/home/khoa/Documents/school/s2025/refile";
      configDir = "/home/khoa/.config/syncthing";
    };
    udisks2.enable = true;
  };
  #hardware
  hardware = {
    #tablet
    opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };
    keyboard.qmk.enable = true;
    bluetooth.enable = true;
  };
  #gpu
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
  #vm
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  #time stuff
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

  #environment (REMEMBER THE "N" in enviroNment)
  environment = {
    variables.EDITOR = "nvim";
    etc =
      lib.mapAttrs' (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;
  };

  #auth agent/security/polkit
  security = {
    polkit.enable = true;
    rtkit.enable = true;
    sudo.extraConfig = ''
      khoa ALL=(ALL) NOPASSWD: /bin/bash -c 'yy'
    '';
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
