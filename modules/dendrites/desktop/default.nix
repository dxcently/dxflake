# modules/dendrites/desktop/default.nix — the desktop aggregate. Names its
# own files, one line each, LC_ALL=C order.
{
  imports = [
    ./composekey.nix
    ./displaymanager.nix
    ./fastfetch
    ./fcitx5.nix
    ./flatpak.nix
    ./floorp.nix
    ./foliate.nix
    ./fonts.nix
    ./gtk.nix
    ./hardware.nix
    ./kitty.nix
    ./packages.nix
    ./pipewire.nix
    ./printing.nix
    ./qt.nix
    ./thunar.nix
    ./vesktop.nix
    ./virtmanager.nix
    ./xserver.nix
  ];
  # gaming/electron want a high mmap count; shared by every desktop.
  config = {
    boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  };
}
