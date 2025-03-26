{
  pkgs,
  config,
  inputs,
  home-manager,
  ...
}: {
  imports = [
    ./hyprland.nix #window manager
    ./waybar.nix #bar
    ./kitty.nix #terminal
    ./bash.nix #shell
    ./neovim.nix #text editor
    ./rofi.nix #application launcher
    ./nh.nix #nix helper
    ./swappy.nix #screenshot
    ./yazi.nix #tui file manager
    ./gtk-qt.nix #set themes and colors
    ./fastfetch/fastfetch.nix #fetch
    ./floorp.nix #browser
    ./composekey.nix #special keys
    ./audacious.nix #music player
    ./hyprlock.nix #lock
    ./hyprpaper.nix #wallpaper setter
    ./wlogout.nix #power menu
  ];
}
