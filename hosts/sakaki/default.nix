{ ... }: {
  imports = [
    ./hardware.nix
    ./syncthing.nix
  ];
  dx.aggregations.server = true;
  dx.syncthing.enable = true;
  dx.askSudo.enable = true;
  dx.autologin.enable = true;
  dx.melete.enable = true;
}
