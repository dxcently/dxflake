{
  config,
  pkgs,
  ...
}: {
  #universal packages
  environment.systemPackages = with pkgs; [
    # de stuff
    swww
    waybar
    networkmanagerapplet
    kitty
    dunst
    slurp
    grim
    swappy
    bash
    wpgtk
    wl-clipboard
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
    kdePackages.gwenview
    feh
    # audio
    wireplumber
    pavucontrol
    # programs
    osu-lazer-bin
    floorp
    vscodium
    arduino-ide
    chromium
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
    (vesktop.override {electron = pkgs.electron_32;})
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
    jupyter
    gimp
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
    gcalcli
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

  nixpkgs.config.permittedInsecurePackages = ["electron-32.3.3"];
}
