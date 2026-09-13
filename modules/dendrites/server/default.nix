# modules/dendrites/server/default.nix — the server aggregate. Names its own
# files, one line each, LC_ALL=C order.
{
  imports = [
    ./jellyfin.nix
  ];
}
