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
    ];

    # What `desktop` installs, plus one preference. Both are the aggregation's
    # own, deferred until the platform pass. The packages are named by their
    # `dx.packages` switches — the flat list lives once, in
    # modules/dendrites/packages.nix, and a package list answers no question a
    # host could answer differently, so it is not a dendrite.
    nixos =
      { pkgs, lib, ... }:
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

        dx.packages =
          lib.genAttrs
            [
              "kitty"
              "mission-center"
              "file-roller"
              "gparted"
              "mpv-with-scripts"
              "vlc"
              "wireplumber"
              "pavucontrol"
              "strawberry"
              "playerctl"
              "ffmpegthumbnailer"
              "obs-studio"
              "grim"
              "slurp"
              "losslesscut"
              "scrcpy"
              "zen-browser"
              "chromium"
              "qbittorrent"
              "nicotine-plus"
              "zoom"
              "obsidian"
              "anki-bin"
              "pear-desktop"
              "gimp-with-plugins"
              "webcamoid"
              "orca-slicer"
            ]
            (_: {
              enable = true;
            });
      };
  };

  home.members = [
    "cheatsheet"
    "composekey"
    "fastfetch"
    "foliate"
    "gtk"
    "qt"
    "vesktop"
    "virtmanager"
  ];
}
