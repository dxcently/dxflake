{ lib, ... }:
let
  mediaLocation = "/mnt/immich";
in
{
  config = {
    # Media lives on kaori; Postgres and Redis stay on sakaki's NVMe. NFS
    # cannot be trusted with Postgres' file locking, and the module already
    # defaults the DB to a local unix socket -- so DO NOT set
    # services.immich.database.host to anything remote.
    services.immich = {
      enable = true;
      host = "0.0.0.0"; # phones need to reach it off-box
      openFirewall = true;
      inherit mediaLocation;
    };

    # Melete's shell has no TTY, so an interactive sudo password prompt makes
    # immich unmanageable from the agent surface. Scoped to start/stop/restart
    # of the immich units only -- not a general systemctl grant.
    security.sudo.extraRules = [
      {
        users = [ "khoa" ];
        commands =
          let
            systemctl = "/run/current-system/sw/bin/systemctl";
            units = [
              "immich-server"
              "immich-machine-learning"
              "redis-immich"
            ];
            verbs = [
              "start"
              "stop"
              "restart"
              "reload"
            ];
          in
          lib.flatten (
            map (
              verb:
              map (unit: {
                command = "${systemctl} ${verb} ${unit}.service";
                options = [ "NOPASSWD" ];
              }) units
            ) verbs
          );
      }
    ];

    dx.nas-mounts.mounts.${mediaLocation} = {
      export = "/volume1/immich";
      requiredBy = [ "immich-server" ];
    };
  };
}
