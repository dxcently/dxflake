# example-host-headless.nix — a machine with no graphical session and no home lane.
#
# Copy to:  hosts/<host>/default.nix
# Then:     add "<host>" to the host list in flake.nix.
# Replace:  as example-host.nix.
#
# The same interface, answered differently. Read it beside example-host.nix:
# one group is shared, the graphical group is simply not selected, the same
# capability is answered with the other implementation, and the user gets an
# account with no Home Manager module behind it. Two machines, one vocabulary,
# no `if hostname ==` anywhere.
{
  aggregation.base.enable = true;

  dendrites = {
    exampletool.enable = true;

    # The same capability the other host reaches through its group, answered
    # here with the other implementation and selected directly — the escape
    # hatch a host always has. The file the other host uses is never imported.
    compositor = {
      enable = true;
      provider = "niri";
    };
  };

  # An account and nothing more: no home lane is evaluated, no Home Manager
  # module is imported by this host at all.
  users.exampleuser = {
    definition = ../../users/exampleuser.nix;
    homeManager.enable = false;
  };

  nixos = {
    imports = [ ./hardware.nix ];
    networking.hostName = "exampleserver";
  };
}
