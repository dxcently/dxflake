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
{
  description = "The desktop shell: the compositor and the surfaces drawn on it.";

  system = {
    members = [ "hyprland-packages" ];
    providers.compositor = null;
  };

  home.members = [
    "rofi"
    "satty"
    "waybar"
    "wlogout"
  ];
}
