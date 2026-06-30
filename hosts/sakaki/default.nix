{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nucleus
    ../../modules/dendrites/server
  ];
}
