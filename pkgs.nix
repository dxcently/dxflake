{ config, pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    # de stuff
    swww
    eww
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
    udiskie
    ungoogled-chromium
    firefox
    anki-bin
    obsidian
    gimp
    spicetify-cli
    hyprpicker
    neovide
    soulseekqt
    nicotine-plus
    webcamoid
    lutris
    wine
    winetricks
    protonup-qt
    xfce.xfburn
    vlc
    strawberry-qt6
    soundconverter
    prismlauncher
    guvcview
    vencord
    vesktop
    bottles
    qbittorrent
    obs-studio
    # cli programs
    vim
    ncspot
    socat
    bat
    gh # github cli
    git
    lazygit
    xdg-utils
    lshw
    lsd
    fastfetch
    nitch
    cowsay
    fzf
    ripgrep
    atuin
    zoxide
    btop
    nh
    wget
    clinfo
    ydotool
    curl
    starship
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
    # libs/frameworks
    qt6.qtwayland
    libsForQt5.qt5.qtwayland
    ninja
    python3
    meson
    nodejs
    pkg-config
    v4l-utils
    nixfmt-rfc-style
    #vm
    qemu
  ];

  #nix options pkgs
  programs = {
    neovim.enable = true;
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
    k3b.enable = true;
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
      noto-fonts-color-emoji
      material-icons
      font-awesome
      symbola
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      (nerdfonts.override { fonts = [ "ComicShannsMono" ]; })
      (nerdfonts.override { fonts = [ "ShareTechMono" ]; })
      (pkgs.callPackage ./packages/azukifontB/azukifontB.nix { })
      (pkgs.callPackage ./packages/azuki_font/azuki_font.nix { })
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "azukifontB" ];
        sansSerif = [ "ComicShannsMono Nerd Font" ];
        monospace = [ "ComicShannsMono Nerd Font" ];
      };
    };
  };
}
