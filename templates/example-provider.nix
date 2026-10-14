# example-provider.nix — one implementation of a multi-implementation capability.
#
# Copy to:  modules/dendrites/<capability>/<provider>.nix
# Then:     add `<provider> = ./<provider>.nix;` to that directory's
#           default.nix (example-default-provider-registry.nix). Nothing goes in
#           the catalogue: the catalogue names the capability, the registry
#           names its providers.
# Replace:  <provider> and both halves.
#
# A provider file has exactly the shape of a dendrite: a plain module, with
# `habit.home` for what belongs in a user's home. Providers of one capability
# may differ in which halves they carry — a home-only one simply has no system
# settings, and selecting it for the system applies an empty half.
#
# A provider is exclusive within a scope: one implementation answers for the
# host, one answers for each user. Two aggregations that want the same
# capability on the same terms merge into one selection; two that name
# different providers for it collide on `habit.dendrites.<capability>.provider`
# with both values in the error.
{
  habit.home =
    { pkgs, ... }:
    {
      services.mako = {
        enable = true;
        settings.default-timeout = 5000;
      };
      home.packages = [ pkgs.libnotify ];
    };
}
