# example-default-provider-registry.nix — a capability with SEVERAL
# implementations.
#
# Copy to:  modules/dendrites/<capability>/default.nix
# Then:     add `<capability> = ./dendrites/<capability>;` to the catalogue in
#           modules/default.nix — the catalogue names the DIRECTORY, not a lane
#           file — and write one file per provider (example-provider.nix).
# Replace:  <capability> and the provider names.
#
# This file names paths and imports NONE of them. The chosen provider is the
# only file ever read, so an implementation the host did not pick costs nothing
# and cannot break its evaluation. That is enforced, not hoped for:
# tests/selection keeps a provider that throws on import and proves it stays
# unread.
#
# A capability with one implementation needs no registry and no provider option
# at all — use example-dendrite.nix instead. Add the second file, and the
# `provider` option appears on its own.
#
# Which provider answers is chosen by whatever selected the capability:
#   aggregation.<group>.<capability>.provider = "mako";   # under the group
#   dendrites.<capability>.provider = "mako";             # direct, outranks it
{
  providers = {
    mako = ./mako.nix;
    dunst = ./dunst.nix;
  };
}
