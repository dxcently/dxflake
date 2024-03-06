{ inputs, lib, config, pkgs, ... }: 

{
  imports = [
    ./hardware.nix
    ./pkgs.nix
  ];

  nixpkgs = {
    overlays = [
     (self: super: (let
      patched_pkgs = import inputs.nixpkgs_patched {
      inherit (self) system;
      config.allowUnfree = true;
    };
    in {
      linuxPackages = patched_pkgs.linuxPackages;
     }))
    ];
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ "electron-25.9.0" ];
    };

  };

  nix = {
   nixPath = ["/etc/nix/path"];
   registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);
   #hyprland rebuild optimization, flakes, auto gc
   settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];  
    };
    gc = {
     automatic = true;
     randomizedDelaySec = "14m";
     options = "--deleted-older-than 7d";
     };
   };

  #enable networking
  networking = {
   hostName = "nixos";
   networkmanager.enable = true;
   };

  #boot
  boot = {
   initrd.kernelModules = [ "nvme" ];
   kernelPackages = pkgs.linuxPackages;
   loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    };
   kernel.sysctl = { "vm.max_map_count" = 2147483642; }; 
  };

  #managing users
  users.users = {
    khoa = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
    };
  };

   /*services.openssh = {
    enable = true;
    settings = {
      # Forbid root login through SSH.
      PermitRootLogin = "no";
      # Use keys only. Remove if you want to SSH using password (not recommended)
      PasswordAuthentication = true;
    };
  };*/
  
  #services
  services = {
   openssh = {
     enable = true;
     settings = {
       # Forbid root login through SSH.
       PermitRootLogin = "no";
       # Use keys only. Remove if you want to SSH using password (not recommended)
       PasswordAuthentication = true;
    };
  };
  pipewire = {
   enable = true;
   alsa.enable = true;
   alsa.support32Bit = true;
   pulse.enable = true;
   jack.enable = true;
  };  
  devmon.enable = true;
  gvfs.enable = true;
  udisks2.enable = true;
  flatpak.enable = true;
  };

  #hardware - nvidia settings
  services.xserver.videoDrivers = ["nvidia"];
  hardware = {
   opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
     rocm-opencl-icd
     rocm-opencl-runtime
     ];
  };
   nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      offload = {
        enable = true;
        enableOffloadCmd = true;
	};
    };
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
     lib.mapAttrs'
     (name: value: {
       name = "nix/path/${name}";
       value.source = value.flake;
     })
    config.nix.registry;
  };
  
  #auth agent/security/polkit
  security = {
   polkit.enable = true;
   rtkit.enable = true;
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
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
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
