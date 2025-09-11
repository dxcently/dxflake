{
  pkgs,
  config,
  inputs,
  home-manager,
  ...
}: {
  imports = [
    ./packages #system packages
    ./git.nix #git
    ./hyprland.nix #window manager
    ./waybar.nix #bar
    ./kitty.nix #terminal
    ./bash.nix #shell
    ./neovim.nix #text editor
    ./rofi.nix #application launcher
    ./virtmanager.nix
    ./nh.nix #nix helper
    ./swappy.nix #screenshot
    ./yazi.nix #tui file manager
    ./stylix.nix #theming handler
    ./gtk.nix #set gtk theme
    ./qt.nix #set qt theme
    ./fastfetch/fastfetch.nix #fetch
    ./floorp.nix #browser
    ./composekey.nix #special keys
    ./audacious.nix #music player
    ./hyprlock.nix #lock
    ./hyprpaper.nix #wallpaper setter
    ./wlogout.nix #power menu
  ];
}
