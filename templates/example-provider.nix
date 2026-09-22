# example-provider.nix — one implementation of a multi-implementation capability.
#
# Copy to:  modules/dendrites/<capability>/<provider>.nix
# Then:     add `<provider> = ./<provider>.nix;` to that directory's
#           default.nix (example-default-provider-registry.nix). Nothing goes in
#           the catalogue: the catalogue names the capability, the registry
#           names its providers.
# Replace:  <provider> and both lanes.
#
# A provider file has exactly the shape of a dendrite: the lanes it supports and
# no others. Providers of one capability may support DIFFERENT lanes — one that
# is home-only simply omits `nixos`, and a host that selects it for the system
# is told so by name rather than quietly getting nothing.
#
# A provider is exclusive within a scope: one implementation answers for the
# host, one answers for each user. Two aggregations that want the same
# capability on the same terms merge into one selection; two that name different
# providers for it collide on `dendrites.<capability>.provider` with both values
# in the error.
{
  homeManager =
    { pkgs, ... }:
    {
      services.mako = {
        enable = true;
        settings.default-timeout = 5000;
      };
      home.packages = [ pkgs.libnotify ];
    };
}
