{ ... }: {
  imports = [
    ./hardware.nix
    ./syncthing.nix
  ];
  dx.aggregations.server = true;
  dx.syncthing.enable = true;
  dx.autologin.enable = true;
  dx.melete.enable = true;
  dx.nfs-media.enable = true;
  dx.mneme.enable = true;
}
