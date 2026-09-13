# modules/dendrites/gaming/default.nix — the gaming aggregate. Names its own
# files, one line each, LC_ALL=C order.
{
  imports = [
    ./aagl.nix
    ./packages.nix
    ./steam.nix
  ];
}
