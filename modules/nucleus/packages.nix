# modules/nucleus/packages.nix — the floor: packages every host carries,
# unconditionally.
#
# Packages and nothing else. The `programs` and `nixpkgs` settings that used to
# sit beside this list live in modules/nucleus/system.nix with the rest of the
# unconditional system configuration.
#
# Not a dendrite list and not switched: an unbootable shell prompt or a missing
# archive tool is not something a host should be able to answer differently. What
# IS switchable lives in modules/dendrites/packages.nix.
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # ── Shell & Terminal ──
    bash # GNU Bourne Again shell
    starship # minimal, fast, customizable shell prompt
    bat # cat clone with syntax highlighting
    fastfetch # fast system information fetcher
    cowsay # configurable speaking ASCII cow
    fzf # command-line fuzzy finder
    htop # interactive process viewer

    # ── File System & Archives ──
    unrar # extract RAR archives
    unzip # extract ZIP archives
    unar # universal unarchiver
    fd # fast, user-friendly find alternative
    file # determine file type via magic bytes
    xdg-utils # XDG MIME and desktop integration tools

    # ── Hardware & System Administration ──
    gptfdisk # GPT/MBR partitioning tool
    lshw # detailed hardware configuration info
    usbutils # USB device inspection (lsusb)
    lm_sensors # read hardware sensors
    v4l-utils # Video4Linux2 utilities
    clinfo # enumerate OpenCL platforms
    poppler # PDF rendering library and CLI tools
    socat # bidirectional data relay
    sops # encrypt secrets in YAML/JSON/ENV/INI
    age # modern, secure file encryption

    # ── Media CLI ──
    ffmpeg # audio/video encoding framework
    yt-dlp # feature-rich youtube-dl fork

    # ── Development & Engineering ──
    vim # vi-compatible modal text editor
    neovide # GPU-accelerated Neovim GUI
    git # distributed version control
    lazygit # terminal UI for git
    ripgrep # recursive regex search (rg)
    jq # command-line JSON processor
    curl # transfer data with URLs
    wget # non-interactive network downloader
    godot # 2D/3D cross-platform game engine
    arduino-ide # IDE for Arduino microcontrollers
    jupyter # interactive computational notebooks
    typst # markup-based document typesetting
    tinymist # Typst language server
    nixfmt # formatter for Nix source code
    nix-tree # browse Nix derivation closures
    nh # Nix helper for rebuilds and cleanup
    ngrok # expose local servers via secure tunnels
    nodejs # cross-platform JavaScript runtime
  ];
}
