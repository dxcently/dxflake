# The compositor, as one capability with one implementation today.
#
# A provider registry: it names paths and imports none of them, so the chosen
# compositor is the only file ever read. Hyprland is the implementation dxflake
# ships; adding niri is a file beside this one and a line below, and the hosts
# that want it say so on their own interface
# (`aggregation.shell.compositor.provider`).
{
  providers = {
    hyprland = ./hyprland.nix;
  };
}
