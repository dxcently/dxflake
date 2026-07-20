{
  lib,
  config,
  ...
}:
let
  cfg = config.dx.nas-mounts;
in
{
  options.dx.nas-mounts = {
    enable = lib.mkEnableOption "NFS mounts from the kaori NAS";

    server = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.203";
      description = ''
        Address of the NAS. IP rather than hostname: there is no LAN DNS, so
        the literal address is the honest dependency. kaori holds a reserved
        lease at the gateway; update here if that ever moves, and update the
        DSM-side export rules (which name each client by IP) too.
      '';
    };

    mounts = lib.mkOption {
      default = { };
      description = "Exports to mount, keyed by mountpoint.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            export = lib.mkOption {
              type = lib.types.str;
              description = "Path of the export on the NAS, e.g. /volume1/jellyfin.";
            };

            requiredBy = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                Services that must not start before this mount is up. Without
                this a consumer can start early and populate an empty local
                directory under the mountpoint, which then shadows the real
                library and is painful to unpick once paths are recorded.
              '';
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems = lib.mapAttrs (_: m: {
      device = "${cfg.server}:${m.export}";
      fsType = "nfs";
      options = [
        "nfsvers=4.1"
        "_netdev"
        "hard" # never silently fail a write mid-upload
        "noatime"
        "x-systemd.automount" # don't block boot on the NAS being up
      ]
      # An idle unmount and RequiresMountsFor contradict each other: the
      # timeout tears the mount down after 600s of no I/O, and systemd then
      # stops every unit that requires it. A long-lived consumer like
      # immich-server looks like it "dies on rebuild" when really it is
      # killed ten minutes after each start. Only expire mounts that no
      # service depends on.
      ++ lib.optional (m.requiredBy == [ ]) "x-systemd.idle-timeout=600";
    }) cfg.mounts;

    systemd.services = lib.mkMerge (
      lib.mapAttrsToList (
        mountpoint: m:
        lib.genAttrs m.requiredBy (_: {
          unitConfig.RequiresMountsFor = [ mountpoint ];
        })
      ) cfg.mounts
    );
  };
}
