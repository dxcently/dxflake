{ config, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
  /* de stuff */
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
  wallust
  /* audio */
  wireplumber
  pavucontrol
  xfce.thunar
  xfce.thunar-volman
  /* programs */
  vesktop
  udiskie
  virt-manager
  ungoogled-chromium
  firefox-bin
  wine
  ncspot
  lutris
  bottles
  protonup-qt
  anki-bin
  obsidian
  vim
  steam
  winetricks
  gimp
  spicetify-cli
  hyprpicker
  /* cli programs */
  socat
  bat
  gh #github cli
  git
  lazygit
  xdg-utils
  lshw
  lsd
  neofetch
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
  unar
  jq
  poppler
  fd
  file
  ripgrep
  /* libs/frameworks */
  qt6.qtwayland
  libsForQt5.qt5.qtwayland
  ninja
  python3
  meson
  nodejs
  pkg-config
  v4l-utils
  nixfmt
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
    fzf.fuzzyCompletion = true;
    nm-applet.enable = true;
  };


  #fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-color-emoji
    material-icons
    liberation_ttf
    font-awesome
    fira-code
    fira-code-symbols
    hack-font
    symbola
    jetbrains-mono
    nerdfonts
  ];

}
