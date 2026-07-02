{...}: {
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

    ../gtk.nix
    ../qt.nix
    ../kitty.nix
    ../librewolf.nix
    ../vesktop.nix
    ../floorp.nix
    ../virtmanager.nix
    ../composekey.nix
    ../fastfetch
  ];

  # gaming/electron want a high mmap count; shared by every desktop.
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;
}
