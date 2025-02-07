{
  config,
  pkgs,
  ...
}: {
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
    virtualbox
    floorp
    vscodium
    arduino-ide
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
    soundconverter
    guvcview
    vencord
    vesktop
    bottles
    qbittorrent
    obs-studio
    #jellyfin
    #jellyfin-web
    #jellyfin-ffmpeg
    #jellyfin-media-player
    #parsec-bin
    zoom-us
    youtube-music
    calibre
    # cli programs
    arduino-cli
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
    distrobox
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
      corefonts
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
      (pkgs.callPackage ./packages/azukifontB/azukifontB.nix {})
      (pkgs.callPackage ./packages/azuki_font/azuki_font.nix {})
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["azukifontB"];
        sansSerif = ["ComicShannsMono Nerd Font"];
        monospace = ["ComicShannsMono Nerd Font"];
      };
    };
  };
}
