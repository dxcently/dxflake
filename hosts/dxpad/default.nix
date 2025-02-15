{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      #permittedInsecurePackages = [ "electron-25.9.0" ];
    };
  };

  #pkgs
  environment.systemPackages = with pkgs; [
    # de stuff
    swww
    waybar
    networkmanagerapplet
    kitty
    dunst
    rofi-wayland
    slurp
    grim
    swappy
    bash
    thunderbird
    wpgtk
    wl-clipboard
    wlogout
    polkit_gnome
    libnotify
    unrar
    unzip
    yad
    lm_sensors
    cliphist
    brightnessctl
    mpv
    gparted
    gwenview
    feh
    # audio
    wireplumber
    pavucontrol
    # programs
    osu-lazer-bin
    floorp
    vscodium
    ungoogled-chromium
    firefox
    anki-bin
    obsidian
    neovide
    nicotine-plus
    webcamoid
    lutris
    wine
    protonup-qt
    vlc
    strawberry-qt6
    guvcview
    vencord
    vesktop
    bottles
    qbittorrent
    obs-studio
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    jellyfin-media-player
    parsec-bin
    zoom-us
    youtube-music
    calibre
    # cli programs
    vim
    socat
    bat
    gh # github cli
    git
    lazygit
    xdg-utils
    lshw
    lsd
    fastfetch
    cowsay
    fzf
    ripgrep
    atuin
    zoxide
    btop
    wget
    clinfo
    ydotool
    curl
    qmk
    ffmpegthumbnailer
    ffmpeg
    unar
    jq
    poppler
    fd
    file
    ripgrep
    spotdl
    playerctl
    distrobox
    # libs/frameworks
    qt6.qtwayland
    libsForQt5.qt5.qtwayland
    ninja
    python3
    meson
    pkg-config
    v4l-utils
    nixfmt-rfc-style
    typst
    tinymist
  ];

  #nix options pkgs
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    starship.enable = true;
    dconf.enable = true;
    bash.blesh.enable = true;
    nm-applet.enable = true;
    steam.enable = true;
    virt-manager.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
        thunar-media-tags-plugin
      ];
    };
    file-roller.enable = true;
  };

  #font packages
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      noto-fonts-color-emoji
      material-icons
      font-awesome
      fira-code-symbols
      symbola
      nerd-fonts.jetbrains-mono
      nerd-fonts.comic-shanns-mono
      nerd-fonts.shure-tech-mono
      (pkgs.callPackage ../../packages/azukifontB/azukifontB.nix {})
      (pkgs.callPackage ../../packages/azuki_font/azuki_font.nix {})
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["azukifontB"];
        sansSerif = ["ComicShannsMono Nerd Font"];
        monospace = ["ComicShannsMono Nerd Font"];
      };
    };
  };

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
    gc = {
      automatic = true;
      randomizedDelaySec = "14m";
      options = "--deleted-older-than 7d";
    };
  };

  #enable networking
  networking = {
    hostName = "dxflake";
    networkmanager.enable = true;
  };

  #boot
  boot = {
    #change if nvidia
    initrd.kernelModules = ["nvme"];
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
      ];
    };
  };

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
      wireplumber = {
        enable = true;
        extraConfig = {
          "10-disable-camera" = {
            "wireplumber.profiles" = {
              main."monitor.libcamera" = "disabled";
            };
          };
        };
      };
    };
    blueman.enable = true;
    devmon.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    flatpak.enable = true;
    tumbler.enable = true;
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };
    xserver = {
      displayManager.lightdm = {
        enable = true;
      };
    };
    jellyfin = {
      enable = true;
      package = pkgs.jellyfin;
    };
    syncthing = {
      enable = true;
      user = "khoa";
      dataDir = "/home/khoa/Documents/school/s2025/refile";
      configDir = "/home/khoa/.config/syncthing";
    };
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
    enable = true;
  };
  hardware.opengl = {
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
