{ lib, config, ... }:
{
  options.dx.nfs-media.enable = lib.mkEnableOption "NFS client mount of kaori's media share";

  config = lib.mkIf config.dx.nfs-media.enable {
    fileSystems."/mnt/kaori-jellyfin" = {
      device = "192.168.1.203:/volume1/jellyfin";
      fsType = "nfs";
      options = [ "vers=4.1" "x-systemd.automount" "noauto" ];
    };
  };
}
