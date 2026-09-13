# modules/default.nix — the dxflake module tree, one explicit aggregate.
# Each subdirectory names its own files and nothing else's — no file is
# ever named from outside the directory that holds it.
{
  imports = [
    ./aggregations.nix
    ./dendrites
    ./nucleus
  ];
}
