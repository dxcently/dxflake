# shell — the desktop shell: the compositor and the surfaces drawn on it.
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
# satty and wlogout draw surfaces through Wayland protocols, and ./packages.nix
# is a tool belt with nothing Hyprland-specific in it despite where those tools
# are usually met.
#
# The Hyprland-ONLY pieces — keybinds, decoration, autostart, hyprglass — are
# the `hyprland` aggregation's, precisely so that answering
# `compositor.provider` with something else leaves them unselected and
# unevaluated. docs/HYPRLAND-SPLIT.md is the old-block → new-owner map.
{
  description = "The desktop shell: the compositor and the surfaces drawn on it.";

  system = {
    providers.compositor = null;

    # The Wayland tool belt this aggregation installs. Its own membership, not a
    # selectable capability — see ./packages.nix.
    nixos.imports = [ ./packages.nix ];
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
    # had, so a host that says nothing keeps it. songbook/default.nix is the
    # registry; a host that wants another writes
    # `users.<u>.aggregation.shell.rice.provider`.
    providers.rice = "transience";
  };
}
