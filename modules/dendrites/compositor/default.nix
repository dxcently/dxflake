# The compositor, as one capability with one implementation today.
#
# A provider registry: it names paths and imports none of them, so the chosen
# compositor is the only provider entry ever read. Hyprland is the
# implementation dxflake ships; adding niri is a folder beside `hyprland/` and a
# line below, and the hosts that want it say so on their own interface
# (`aggregation.shell.compositor.provider`).
#
# One folder per provider, and the folder holds the provider's own entry file
# PLUS everything written against that compositor — a plugin compiled against
# it, a config in its own language. A host that answers with another provider
# never imports the folder, so none of it is evaluated. The grouping is the
# capability's, not the dendrite root's: what a host gets is still decided by
# the aggregation that names a dendrite, never by where it sits.
{
  providers = {
    hyprland = ./hyprland/hyprland.nix;
  };
}
