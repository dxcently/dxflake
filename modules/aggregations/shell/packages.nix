# The shell aggregation's own installation membership: the Wayland tool belt.
#
# Not a dendrite, for the same reason desktop's list is not one — a package list
# answers no question a host could answer differently, so there is nothing to
# select. Only the shell aggregation imports it.
#
# Nothing in here is Hyprland-specific despite where these tools are usually
# met: each talks Wayland protocols or nothing at all, so they stay with the
# compositor-agnostic half. The Hyprland-only packages travel with the dendrite
# that invokes them — see docs/HYPRLAND-SPLIT.md.
#
# waybar is deliberately absent: `programs.waybar.enable` in the waybar dendrite
# already installs it, and carrying it here too put two copies on every host.
{ pkgs, lib, ... }:
{
  # `mkAfter` for the same reason desktop pins its list: ordered last into
  # system.path, so this never shadows a selected capability.
  environment.systemPackages = lib.mkAfter (
    with pkgs;
    [
      dunst # lightweight notification daemon
      awww # animated wallpaper daemon for Wayland
      wl-clipboard # copy/paste CLI for Wayland
      satty # Wayland screenshot annotation tool (swappy successor)
      cliphist # clipboard history manager for Wayland
      brightnessctl # control device brightness via sysfs
      ydotool # generic input automation
      yad # display GTK dialogs from shell scripts
      zenity # GNOME-style GTK dialogs from shell scripts
    ]
  );
}
