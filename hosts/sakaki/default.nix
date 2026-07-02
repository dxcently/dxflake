{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nucleus
    ../../modules/dendrites/server
    ../../modules/dendrites/syncthing.nix
    ./syncthing.nix
  ];
}
