# compositor — the compositor's own session: keybinds, decoration, autostart,
# lock and idle glass. Hyprland is what runs it today.
#
# Separate from `shell` on purpose, and the separation is load-bearing rather
# than tidy. Everything `shell` groups works on any wlroots compositor: waybar,
# rofi, satty, wlogout, and the Wayland tool belt shell installs are all
# compositor-agnostic. The four members below are not — each writes
# `wayland.windowManager.hyprland.*`, and hyprglass is a PLUGIN compiled against
# one compositor commit.
#
# So a host that answers `compositor.provider` with something other than
# "hyprland" selects `shell` and simply does not select this. That is what keeps
# `pkgs.hyprglass` from being evaluated on a machine that could never load it —
# a structural answer, not a comment. tests/selection proves it against a
# fixture whose Hyprland-only member throws on import.
#
# Each of the four lives in its provider's folder,
# `modules/dendrites/compositor/hyprland/`, beside the provider entry it is
# written against. A host on another compositor never imports that folder.
#
# Every member is a homeManager lane, so a host selects this on its user:
#
#   users.khoa.aggregation.compositor.enable = true;
#
# Selecting it for the system is harmless and does nothing — there is no system
# half to contribute.
{
  description = "The compositor's own session: keybinds, decoration, autostart, lock and idle glass.";

  home.members = [
    "hyprglass"
    "hyprland-autostart"
    "hyprland-decoration"
    "hyprland-keybinds"
  ];
}
