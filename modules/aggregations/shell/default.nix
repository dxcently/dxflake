# shell — the desktop shell: which compositor runs, and the surfaces drawn on
# it that work under any of them.
#
# `compositor` is a provider-bearing dendrite, so this aggregation exposes the
# choice on its own interface and a host writes it there:
#
#   aggregation.shell = {
#     enable = true;
#     compositor.provider = "hyprland";
#   };
#
# There is no default: which compositor runs is a property of the host, not of
# the aggregation, and a host that forgets is told so by name. The provider list
# itself lives once, in modules/dendrites/compositor/default.nix.
#
# ── Membership ────────────────────────────────────────────────────────────
# The compositor provider makes a session RUN and installs nothing. Everything
# this aggregation adds around it works on ANY wlroots compositor: waybar, rofi,
# satty and wlogout draw surfaces through Wayland protocols, and the Wayland
# tool belt below has nothing Hyprland-specific in it despite where those tools
# are usually met.
#
# The Hyprland-ONLY pieces — keybinds, decoration, autostart, hyprglass — are
# the `compositor` aggregation's, precisely so that answering
# `compositor.provider` with something else leaves them unselected and
# unevaluated. docs/HYPRLAND-SPLIT.md is the old-block → new-owner map.
{
  description = "Which compositor runs, and the compositor-agnostic surfaces drawn on it.";

  system = {
    providers.compositor = null;

    # The Wayland tool belt this aggregation installs, switched on by name. The
    # lines themselves live once, in modules/dendrites/packages.nix — an install
    # is not a selectable capability, so it gets no catalogue line and no file
    # of its own here.
    #
    # waybar is deliberately absent: `programs.waybar.enable` in the waybar
    # dendrite already installs it, and switching it on here too would put two
    # copies on every host.
    nixos =
      { lib, ... }:
      {
        dx.packages =
          lib.genAttrs
            [
              "dunst"
              "awww"
              "wl-clipboard"
              "satty"
              "cliphist"
              "brightnessctl"
              "ydotool"
              "yad"
              "zenity"
            ]
            (_: {
              enable = true;
            });
      };
  };

  home = {
    members = [
      "rofi"
      "satty"
      "waybar"
      "wlogout"
    ];

    # The look the surfaces wear. Unlike `compositor` this one HAS a default:
    # dxflake ships one rice, and transience is the look this desktop has always
    # had, so a host that says nothing keeps it. song/songbook/default.nix is the
    # registry; a host that wants another writes
    # `users.<u>.aggregation.shell.rice.provider`.
    providers.rice = "transience";
  };
}
