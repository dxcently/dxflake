# hyprland — the parts of the desktop that only Hyprland can run.
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
# Every member is a homeManager lane, so a host selects this on its user:
#
#   users.khoa.aggregation.hyprland.enable = true;
#
# Selecting it for the system is harmless and does nothing — there is no system
# half to contribute.
{
  description = "The parts of the desktop that only Hyprland can run.";

  home.members = [
    "hyprglass"
    "hyprland-autostart"
    "hyprland-decoration"
    "hyprland-keybinds"
  ];
}
