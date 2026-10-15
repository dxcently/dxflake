# modules/nucleus/default.nix — every unconditional core file this tree
# ships. One line per file, LC_ALL=C order. A new nucleus file is core
# plumbing, not a toggle — it lands here the same way, plus one line.
{
  imports = [
    ../packages.nix
    ../dendrites/packages.nix
    ../dendrites/avahi.nix
    ../dendrites/boot.nix
    ../dendrites/networking.nix
    ../dendrites/openssh.nix
    ../dendrites/postgresql.nix
    ../dendrites/security.nix
    ../dendrites/system.nix
    ../dendrites/tailscale.nix
  ];
}
