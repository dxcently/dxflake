{
  username,
  ...
}: {
  imports = [
    ../xserver.nix
    ../displaymanager.nix
    ../pipewire.nix
    ../fonts.nix
    ../fcitx5.nix
    ../thunar.nix
    ../flatpak.nix
    ../printing.nix
    ../stylix.nix
    ../hardware.nix
    ../syncthing.nix
    ./packages.nix
  ];

  # gaming/electron want a high mmap count; shared by every desktop.
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

  home-manager.users.${username}.imports = [
    ../../home/gtk.nix
    ../../home/qt.nix
    ../../home/stylix.nix
    ../../home/kitty.nix
    ../../home/librewolf.nix
    ../../home/vesktop.nix
    ../../home/floorp.nix
    ../../home/virtmanager.nix
    ../../home/composekey.nix
    ../../home/fastfetch/fastfetch.nix
  ];
}
