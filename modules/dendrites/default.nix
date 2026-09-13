# modules/dendrites/default.nix — the floor: dendrites every host carries
# unconditionally. A shared aggregate (desktop/hyprland/gaming/server) and a
# host-selected single dendrite are never named here — a host imports those
# itself. stylix rides the floor because its option TREE must exist on every
# host (Aoide's `options ? stylix` probe), even where `dx.stylix.enable`
# stays false. A `_`-prefixed file is never listed — that is what shelving
# means; the file stays on disk, parked.
{
  imports = [
    ./bash.nix
    ./btop.nix
    ./direnv.nix
    ./git.nix
    ./mcfly.nix
    ./neovim.nix
    ./nh.nix
    ./starship.nix
    ./stylix.nix
    ./yazi.nix
  ];
}
