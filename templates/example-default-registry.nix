# example-default-registry.nix — the catalogue.
#
# Copy to:  modules/default.nix
# Then:     add one `name = ./path;` line per capability, forever. This is the
#           only place a capability file is named; a host, a user and an
#           aggregation all reach a dendrite by NAME.
# Replace:  the catalogue entries.
#
# This is NOT a module. It is plain data, read by lib/composition.nix before any
# module graph exists. Nothing walks the dendrite tree: a capability exists here
# or it cannot be selected, and a name with no line is unreachable — which is
# how a capability is shelved without deleting its file.
#
# Two shapes of value, and the difference is the file on the other end:
#   name = ./dendrites/thing.nix;   one implementation      (example-dendrite)
#   name = ./dendrites/thing;       a provider registry     (example-default-provider-registry)
#
# An unknown name fails as an option that does not exist, naming the file that
# asked for it — so a typo in a host is caught before any platform evaluation.
{
  catalogue = {
    examplebar = ./dendrites/examplebar.nix;
    exampletool = ./dendrites/exampletool.nix;
    examplewidget = ./dendrites/examplewidget.nix;

    # Directory values: a provider registry, one file per implementation.
    compositor = ./dendrites/compositor;
    notifications = ./dendrites/notifications;
  };

  # The aggregations, discovered one level deep. Names and paths only.
  aggregations = import ./aggregations;
}
