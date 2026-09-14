# modules/dendrites/default.nix — the group declarations, and nothing else.
#
# This is a SELECTION module. It is imported in pass one, into both selection
# scopes, and it may never reach a capability file: every path below is a group
# directory whose `default.nix` declares a gate and names members by CATALOGUE
# NAME. Implementations are imported in pass two, only once selection resolved.
#
# That is the line between the two kinds of `default.nix` under this tree:
#
#   named by modules/default.nix's catalogue  →  an implementation
#     dendrites/desktop/fastfetch/default.nix     one capability
#     dendrites/gpu/default.nix                   a provider registry
#   imported here                             →  a selection module
#     dendrites/desktop/default.nix               the desktop group
#
# The two sets never overlap. A group directory may hold its own members
# (desktop, gaming, hyprland do); it does not have to, because membership is by
# name, not by location (base's members are files beside this one).
{
  imports = [
    ./base
    ./desktop
    ./gaming
    ./hyprland
  ];
}
