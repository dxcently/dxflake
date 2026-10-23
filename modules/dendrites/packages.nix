# modules/dendrites/packages.nix — every package that needs no configuration,
# one `pkgs` attribute path per line.
#
# Not a dendrite and not a module: plain data. modules/default.nix turns each
# line into a catalogue entry named by the path's last segment, so
# `kdePackages.filelight` is `habit.dendrites.filelight`. The entry installs the
# package into system.path at order 1400, after the nucleus lists and before
# anything that pins itself last. Collisions there resolve first-wins.
#
# A package that needs configuration is a dendrite of its own, and so is a
# package a dendrite already owns (bash, git, kitty, satty ...): those lines
# are not here. Each group below names the aggregation that selects it.
[
  # ── nucleus ── the floor every host carries
  "unrar" # extract RAR archives
  "unzip" # extract ZIP archives
  "unar" # universal unarchiver
  "fd" # fast, user-friendly find alternative
  "file" # determine file type via magic bytes
  "xdg-utils" # XDG MIME and desktop integration tools
  "bat" # cat clone with syntax highlighting
  "cowsay" # configurable speaking ASCII cow
  "fzf" # command-line fuzzy finder
  "htop" # interactive process viewer
  "gptfdisk" # GPT/MBR partitioning tool
  "lshw" # detailed hardware configuration info
  "usbutils" # USB device inspection (lsusb)
  "lm_sensors" # read hardware sensors
  "v4l-utils" # Video4Linux2 utilities
  "clinfo" # enumerate OpenCL platforms
  "poppler" # PDF rendering library and CLI tools
  "socat" # bidirectional data relay
  "age" # modern, secure file encryption
  "yt-dlp" # feature-rich youtube-dl fork
  "vim" # vi-compatible modal text editor
  "neovide" # GPU-accelerated Neovim GUI
  "lazygit" # terminal UI for git
  "ripgrep" # recursive regex search (rg)
  "jq" # command-line JSON processor
  "curl" # transfer data with URLs
  "wget" # non-interactive network downloader
  "godot" # 2D/3D cross-platform game engine
  "arduino-ide" # IDE for Arduino microcontrollers
  "typst" # markup-based document typesetting
  "tinymist" # Typst language server
  "nixfmt" # formatter for Nix source code
  "nix-tree" # browse Nix derivation closures
  "ngrok" # expose local servers via secure tunnels
  "nodejs" # cross-platform JavaScript runtime

  # ── shell ── the Wayland tool belt
  "awww" # animated wallpaper daemon for Wayland
  "wl-clipboard" # copy/paste CLI for Wayland
  "cliphist" # clipboard history manager for Wayland
  "brightnessctl" # control device brightness via sysfs
  "ydotool" # generic input automation
  "yad" # display GTK dialogs from shell scripts
  "zenity" # GNOME-style GTK dialogs from shell scripts

  # ── desktop ── the graphical session's own apps
  "mission-center" # GUI resource monitor with GPU usage
  "file-roller" # GNOME archive manager (Thunar integration)
  "gparted" # graphical partition editor
  "mpv" # scriptable command-line media player
  "vlc" # cross-platform multimedia player
  "wireplumber" # PipeWire session and policy manager
  "pavucontrol" # PulseAudio/PipeWire volume control GUI
  "strawberry" # music player with audio CD and lyrics
  "playerctl" # MPRIS2 media player controller
  "ffmpegthumbnailer" # video thumbnails via libffmpeg
  "obs-studio" # screen recording and live streaming
  "grim" # Wayland screenshot capture (strx screen shot's backend)
  "slurp" # region picker for grim (strx screen shot --pick)
  "losslesscut-bin" # lossless video/audio trimmer
  "scrcpy" # display and control Android devices
  "zen-browser" # Zen, a Firefox-based web browser
  "chromium" # open source web browser from Google
  "libreoffice" # Writer, Calc, Impress, Draw, Base and Math
  "qbittorrent" # open-source BitTorrent client
  "nicotine-plus" # Soulseek peer-to-peer client
  "zoom-us" # video conferencing
  "obsidian" # markdown personal knowledge base
  "anki-bin" # spaced repetition flashcards
  "pear-desktop" # unofficial YouTube Music client
  "gimp3-with-plugins" # GNU Image Manipulation Program
  "webcamoid" # webcam capture with effects
  "orca-slicer" # G-code slicer for 3D printing

  # ── gaming ── the launchers
  "osu-lazer-bin" # osu! lazer rhythm game
  "lutris" # open gaming platform
  "wine" # run Windows applications on Linux
  "protonup-qt" # GUI manager for Proton-GE/Wine-GE
  "bottles" # manage Wine prefixes with a GTK4 UI
  "prismlauncher" # Minecraft launcher
  "r2modman" # mod manager
  "winetricks" # helper for Wine prefixes
  "protontricks" # winetricks for Proton/Steam

  # ── host-selected ── any host may take any of these
  "soundconverter" # audio format converter
  "udiskie" # automounter for removable media
  "filezilla" # FTP/SFTP client
  "remmina" # RDP/VNC/SPICE remote desktop client
  "kdePackages.filelight" # disk usage as a sunburst
  "tor-browser" # Tor Browser Bundle
  "stremio-linux-shell" # media streaming front end
  "hugo" # static site generator; builds the wiki
]
