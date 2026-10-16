# shell — the desktop shell: which compositor runs, and the surfaces drawn on
# it that work under any of them.
#
# `compositor` is a provider-bearing dendrite, so this aggregation exposes the
# choice on its own interface and a host writes it there:
#
#   habit.aggregation.shell = {
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
# the `hyprland` aggregation's, precisely so that answering
# `compositor.provider` with something else leaves them unselected and
# unevaluated. docs/HYPRLAND-SPLIT.md is the old-block → new-owner map.
{
  description = "Which compositor runs, and the compositor-agnostic surfaces drawn on it.";

  system = {
    providers.compositor = null;

    # The Wayland tool belt this aggregation installs, one catalogue entry per
    # package (modules/dendrites/packages.nix). satty is not here: it is the
    # satty dendrite's, selected by the home member below.
    #
    # waybar is deliberately absent: `programs.waybar.enable` in the waybar
    # dendrite already installs it, and switching it on here too would put two
    # copies on every host.
    members = [
      "awww"
      "wl-clipboard"
      "cliphist"
      "brightnessctl"
      "ydotool"
      "yad"
      "zenity"
    ];

    # dunst is not a catalogue entry: the Aoide `dunst` lane owns that name, so
    # the package is installed here, under the same order the entries use.
    module =
      { pkgs, lib, ... }:
      {
        environment.systemPackages = lib.mkOrder 1400 [ pkgs.dunst ];
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
    # `habit.users.<u>.aggregation.shell.rice.provider`.
    providers.rice = "transience";
  };
}
