# modules/nucleus/default.nix — every unconditional core file this tree
# ships. One line per file, LC_ALL=C order. A new nucleus file is core
# plumbing, not a toggle — it lands here the same way, plus one line.
{
  imports = [
    ./avahi.nix
    ./boot.nix
    ./networking.nix
    ./openssh.nix
    ./packages.nix
    ./postgresql.nix
    ./security.nix
    ./sops.nix
    ./system.nix
    ./tailscale.nix
    ./user.nix
  ];
}
