{
  lib,
  config,
  ...
}: let
  cfg = config.dx.immich;
in {
  options.dx.immich = {
    enable = lib.mkEnableOption "Immich photo library (media on kaori over NFS)";

    mediaLocation = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/immich";
      description = "Mountpoint for the Immich library. Backed by NFS when nfs.enable is set.";
    };

    nfs = {
      enable = lib.mkEnableOption "mount mediaLocation from the kaori NAS over NFS" // {default = true;};

      export = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.203:/volume1/immich";
        description = ''
          NFS export backing the library. IP rather than hostname: there is no
          LAN DNS, so the literal address is the honest dependency. kaori holds
          a reserved lease at the gateway; update here if that ever moves, and
          update the DSM-side export rule (which names this host by IP) too.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Media lives on kaori; Postgres and Redis stay on sakaki's NVMe. NFS
    # cannot be trusted with Postgres' file locking, and the module already
    # defaults the DB to a local unix socket -- so DO NOT set
    # services.immich.database.host to anything remote.
    services.immich = {
      enable = true;
      host = "0.0.0.0"; # phones need to reach it off-box
      openFirewall = true;
      mediaLocation = cfg.mediaLocation;
    };

    fileSystems.${cfg.mediaLocation} = lib.mkIf cfg.nfs.enable {
      device = cfg.nfs.export;
      fsType = "nfs";
      options = [
        "nfsvers=4.1"
        "_netdev"
        "hard" # never silently fail a write mid-upload
        "noatime"
        "x-systemd.automount" # don't block boot on the NAS being up
        "x-systemd.idle-timeout=600"
      ];
    };

    # Without this, immich-server can start before the NAS is mounted and
    # populate an empty local directory under the mountpoint -- which then
    # shadows the real library and is painful to unpick once the DB has
    # recorded asset paths.
    systemd.services.immich-server = lib.mkIf cfg.nfs.enable {
      unitConfig.RequiresMountsFor = [cfg.mediaLocation];
    };
  };
}
