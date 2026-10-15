# example-host-headless.nix — a machine with no graphical session and no home.
#
# Copy to:  hosts/<host>/default.nix
# Then:     add "<host>" to the host list in flake.nix.
# Replace:  as example-host.nix.
#
# Every host selects `core` and `network`, the floor it carries; a copy keeps
# both.
#
# The same interface, answered differently. Read it beside example-host.nix:
# one group is shared, the graphical group is simply not selected, the same
# capability is answered with the other implementation, and the user gets an
# account with no Home Manager module behind it. Two machines, one vocabulary,
# no `if hostname ==` anywhere.
{
  habit.aggregation.core.enable = true;
  habit.aggregation.network.enable = true;
  habit.aggregation.base.enable = true;

  habit.dendrites = {
    exampletool.enable = true;

    # The same capability the other host reaches through its group, answered
    # here with the other implementation and selected directly — the escape
    # hatch a host always has. The file the other host uses is never imported.
    compositor = {
      enable = true;
      provider = "niri";
    };
  };

  # An account and nothing more: no home is evaluated, no Home Manager module
  # is imported by this host at all.
  habit.users.exampleuser = {
    definition = ../../users/exampleuser.nix;
    home.enable = false;
  };

  imports = [ ./hardware.nix ];
  networking.hostName = "exampleserver";

  # Pins stateful-data formats from the first install; do not change it.
  system.stateVersion = "25.11";
}
