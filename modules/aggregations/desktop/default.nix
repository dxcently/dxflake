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
      "desktop-packages"
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

    # Gaming and electron want a high mmap count; shared by every desktop. A
    # preference of the aggregation, deferred to the platform pass.
    nixos = {
      boot.kernel.sysctl."vm.max_map_count" = 2147483642;
    };
  };

  home.members = [
    "composekey"
    "fastfetch"
    "floorp"
    "foliate"
    "gtk"
    "qt"
    "vesktop"
    "virtmanager"
  ];
}
