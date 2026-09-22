# A multi-provider fixture. Only the path values are read here; no provider
# file is imported until one is selected.
{
  providers = {
    dunst = ./dunst.nix;
    herald = ./herald.nix;
    landmine = ./landmine.nix;
    mako = ./mako.nix;
  };
}
