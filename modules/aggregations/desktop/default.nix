# desktop — a graphical session.
#
# The platform a session runs on: audio, fonts, input methods, portals, login.
# The session's own surfaces are the `shell` aggregation, which is why chiyo can
# take this one and let Aoide draw the rest.
{
  description = "A graphical session: audio, fonts, input methods, portals, login.";

  system = {
    members = [
      "desktop-hardware"
      "displaymanager"
      "fcitx5"
      "flatpak"
      "fonts"
      "kitty"
      "pipewire"
      "printing"
      "thunar"
      "xserver"

      # The desktop's apps, one catalogue entry per package.
      "mission-center"
      "file-roller"
      "gparted"
      "mpv"
      "vlc"
      "wireplumber"
      "pavucontrol"
      "strawberry"
      "playerctl"
      "ffmpegthumbnailer"
      "obs-studio"
      "grim"
      "slurp"
      "losslesscut-bin"
      "scrcpy"
      "zen-browser"
      "chromium"
      "libreoffice"
      "qbittorrent"
      "nicotine-plus"
      "zoom-us"
      "obsidian"
      "anki-bin"
      "pear-desktop"
      "gimp3-with-plugins"
      "webcamoid"
      "orca-slicer"
    ];

    # What `desktop` installs, plus one preference. Both are the aggregation's
    # own, deferred until the platform pass.
    module =
      { pkgs, ... }:
      {
        programs = {
          virt-manager.enable = true;
          nm-applet.enable = true;
        };

        # Flatpak/portal plumbing — a desktop concern, not the universal floor.
        # Hyprland adds its own portal on top when that aggregation is present.
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };

        # Gaming and electron want a high mmap count; shared by every desktop.
        boot.kernel.sysctl."vm.max_map_count" = 2147483642;
      };
  };

  home.members = [
    "cheatsheet"
    "composekey"
    "foliate"
    "gtk"
    "qt"
    "vesktop"
    "virtmanager"
  ];
}
