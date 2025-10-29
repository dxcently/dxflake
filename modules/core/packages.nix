{
  config,
  pkgs,
  lib,
  ...
}: {
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    hyprlock.enable = true;
    starship.enable = true;
    dconf.enable = true;
    bash.blesh.enable = true;
    nm-applet.enable = true;
    virt-manager.enable = true;
    system-config-printer.enable = true;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = pkg:
        builtins.elem (lib.getName pkg) [
          "qtwebengine"
        ];
    };
  };

  environment.systemPackages = with pkgs; [
    # de stuff
    waybar
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
    hyprpaper
    # audio
    wireplumber
    pavucontrol
    # programs
    #stremio
    ngrok
    scrcpy
    starship
    osu-lazer-bin
    librewolf
    arduino-ide
    chromium
    anki-bin
    vim
    vscodium
    neovide
    nicotine-plus
    webcamoid
    lutris
    wine
    protonup-qt
    vlc
    strawberry
    bottles
    qbittorrent
    obs-studio
    #jellyfin-media-player
    #parsec-bin
    zoom-us
    youtube-music
    jupyter
    gimp3-with-plugins
    socat
    bat
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
    ffmpegthumbnailer
    ffmpeg
    unar
    jq
    poppler
    fd
    file
    ripgrep
    spotdl
    yt-dlp
    playerctl
    gcalcli
    v4l-utils
    nixfmt-rfc-style
    typst
    tinymist
    nix-tree
  ];
}
