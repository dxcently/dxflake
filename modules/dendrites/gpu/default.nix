# Graphics, as one capability with two implementations.
#
# A host has the silicon it has: amd and intel are mutually exclusive here, and
# that exclusivity is now the type rather than a convention two host files were
# each trusted to respect. Neither file is imported until a host names it, so
# the intel stack is never evaluated on an AMD box.
{
  providers = {
    amd = ./amd.nix;
    intel = ./intel.nix;
  };
}
