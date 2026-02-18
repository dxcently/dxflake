{
  pkgs,
  inputs,
  ...
}: {
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    hyprland = {
      enable = true;
      withUWSM = false;
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
      permittedInsecurePackages = [
        # declare insecure packages here
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    # de stuff
    waybar
    kitty
    dunst
    bash
    wpgtk
    unrar
    unzip
    yad
    lm_sensors
    cliphist
    brightnessctl
    mpv
    gparted
    kdePackages.gwenview
    losslesscut-bin
    file-roller #thunar
    swww
    grim
    slurp
    wl-clipboard
    swappy
    # audio
    wireplumber
    pavucontrol
    # programs
    #stremio
    android-tools
    obsidian
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
    pear-desktop
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
    nixfmt
    typst
    tinymist
    nix-tree
    gptfdisk
  ];
}
