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
      permittedInsecurePackages = [
        # declare insecure packages here
      ];
    };
    overlays = [
      (final: prev: {
        openldap = prev.openldap.overrideAttrs (_: {
          doCheck = false;
        });
      })
    ];
  };

  environment.systemPackages = with pkgs; [
    # ── Compositor & Desktop Layer ──────────────────────────────────────────────
    waybar # highly customizable Wayland status bar
    dunst # lightweight scriptable notification daemon
    awww # animated wallpaper daemon for Wayland (wlr-layer-shell)
    #wpgtk # colorscheme, wallpaper, and template manager via pywal
    wl-clipboard # copy/paste CLI tools for Wayland
    swappy # Wayland snapshot annotation and editing tool
    cliphist # clipboard history manager for Wayland
    brightnessctl # read and control device brightness via sysfs
    ydotool # generic Linux input automation (keyboard, mouse, touch)
    yad # display GTK dialogs from shell scripts
    zenity # display GTK dialogs from shell scripts (GNOME-style)

    # ── Shell & Terminal ────────────────────────────────────────────────────────
    kitty # GPU-accelerated, feature-rich terminal emulator
    bash # GNU Bourne Again shell
    starship # minimal, blazing-fast, infinitely customizable shell prompt
    bat # cat clone with syntax highlighting and git integration
    fastfetch # fast system information fetcher
    cowsay # configurable speaking ASCII cow (and other animals)
    fzf # general-purpose command-line fuzzy finder
    atuin # shell history in SQLite with search, sync, and stats
    zoxide # smarter cd using frecency (z/autojump replacement)
    htop # resource monitor with interactive process viewer
    mission-center # GUI resource monitor with GPU usage

    # ── File System & Archives ──────────────────────────────────────────────────
    file-roller # GNOME archive manager GUI (Thunar integration)
    unrar # extract files from RAR archives
    unzip # extract files from ZIP archives
    unar # universal unarchiver supporting many formats
    fd # simple, fast, user-friendly find alternative
    file # determine file type via magic bytes
    xdg-utils # XDG MIME type handling and desktop integration tools

    # ── Hardware & System Administration ───────────────────────────────────────
    gparted # graphical front-end for libparted partition editor
    gptfdisk # text-mode partitioning tool for GPT and MBR disks
    lshw # detailed hardware configuration information
    usbutils # tools for USB device inspection (lsusb)
    lm_sensors # read hardware sensors: temperatures, voltages, fans
    v4l-utils # Video4Linux2 utilities for cameras and capture devices
    clinfo # enumerate OpenCL platforms and device capabilities
    poppler # PDF rendering library with CLI tools (pdfinfo, pdfimages)
    socat # multipurpose bidirectional relay between data channels
    sops # encrypt secrets stored in YAML/JSON/ENV/INI files
    age # simple, modern, and secure file encryption tool

    # ── Multimedia ──────────────────────────────────────────────────────────────
    mpv # versatile, scriptable command-line media player
    vlc # cross-platform multimedia player and framework
    wireplumber # PipeWire session and policy manager (replaces pipewire-media-session)
    pavucontrol # PulseAudio/PipeWire volume control GUI
    strawberry # music player with audio CD, lyrics, and Last.fm support
    playerctl # MPRIS2 media player command-line controller
    ffmpeg # complete, cross-platform audio/video encoding framework
    ffmpegthumbnailer # generate video thumbnails using libffmpeg
    obs-studio # free, open source screen recording and live streaming
    losslesscut-bin # lossless video/audio trimmer — no re-encode quality loss
    kdePackages.gwenview # fast, feature-rich image viewer from KDE
    scrcpy # display and control Android devices over USB or TCP/IP
    spotdl # download Spotify playlists and tracks via YouTube
    yt-dlp # feature-rich fork of youtube-dl supporting 1000+ sites

    # ── Gaming ──────────────────────────────────────────────────────────────────
    osu-lazer-bin # osu! lazer — open-source rhythm game (official client)
    lutris # open gaming platform for managing Linux and Windows games
    wine # compatibility layer to run Windows applications on Linux
    protonup-qt # GUI manager for Proton-GE and Wine-GE version installs
    bottles # manage multiple Wine prefixes with a modern GTK4 UI

    # ── Development & Engineering ───────────────────────────────────────────────
    vim # highly configurable vi-compatible modal text editor
    neovide # GPU-accelerated Neovim GUI with smooth animations
    git # distributed version control system
    lazygit # terminal UI for git with visual diff and staging
    ripgrep # recursively search directories with regex (rg)
    jq # lightweight and flexible command-line JSON processor
    curl # transfer data with URLs supporting HTTP, FTP, and more
    wget # non-interactive command-line network downloader
    claude-code # agentic AI coding assistant that runs in the terminal
    godot # open-source 2D and 3D cross-platform game engine
    arduino-ide # official IDE for programming Arduino microcontrollers
    jupyter # interactive computational notebooks (Jupyter Lab/Notebook)
    typst # markup-based document typesetting system
    tinymist # Typst language server for editor integration
    nixfmt # opinionated formatter for Nix source code
    nix-tree # interactively browse and visualize Nix derivation closures
    nh # Nix helper: cleaner nixos-rebuild, home-manager, and cache
    ngrok # expose local servers to the internet via secure tunnels
    nodejs #cross-platform JavaScript runtime environment

    # ── Networking & Web ────────────────────────────────────────────────────────
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default # fast, customizable browser built on Firefox
    chromium # Chromium is an open source web browser from Google
    qbittorrent # feature-rich open-source BitTorrent client
    nicotine-plus # Soulseek peer-to-peer file sharing client
    zoom-us # video conferencing, webinars, and team meetings

    # ── Productivity & Knowledge ────────────────────────────────────────────────
    obsidian # markdown-based personal knowledge base and note-taking app
    anki-bin # spaced repetition flashcard app for long-term memorization
    gcalcli # command-line interface to Google Calendar
    pear-desktop # unofficial YouTube Music desktop client

    # ── Creative ────────────────────────────────────────────────────────────────
    gimp3-with-plugins # GNU Image Manipulation Program with extra plugins
    aseprite # pixel art editor and animation tool
    webcamoid # webcam capture application with effects and virtual camera
  ];
}
