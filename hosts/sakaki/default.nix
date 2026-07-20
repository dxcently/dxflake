{ ... }: {
  imports = [
    ./hardware.nix
    ./syncthing.nix
  ];
  dx.aggregations.server = true;
  dx.syncthing.enable = true;
  dx.autologin.enable = true;
  dx.melete.enable = true;
  dx.nas-mounts = {
    enable = true;
    mounts."/mnt/kaori-jellyfin" = {
      export = "/volume1/jellyfin";
      requiredBy = ["jellyfin"];
    };
  };
  dx.mneme.enable = true;
  dx.immich.enable = true;
}
