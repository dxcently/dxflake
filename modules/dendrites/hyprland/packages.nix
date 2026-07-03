{
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    waybar # highly customizable Wayland status bar
    dunst # lightweight notification daemon
    awww # animated wallpaper daemon for Wayland
    wl-clipboard # copy/paste CLI for Wayland
    satty # Wayland screenshot annotation tool (swappy successor)
    cliphist # clipboard history manager for Wayland
    brightnessctl # control device brightness via sysfs
    ydotool # generic input automation
    yad # display GTK dialogs from shell scripts
    zenity # GNOME-style GTK dialogs from shell scripts
  ];
}
