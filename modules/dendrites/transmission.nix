{ config, lib, pkgs, username, ... }: {
  options.dx.transmission.enable = lib.mkEnableOption "transmission-daemon (headless BitTorrent client)";

  config = lib.mkIf config.dx.transmission.enable {
    services.transmission = {
      enable = true;
      # transmission_3 was dropped from nixpkgs; must be pinned explicitly now.
      package = pkgs.transmission_4;
      # sec=sys NFS, uid-based -- same reason jellyfin/slskd run as username.
      user = username;
      group = "users";
      settings = {
        # Pre-created by hand (770/chown fails over this NFS export for a
        # non-owning uid) -- inherits 777 from the export root, so it's
        # already writable. Per-torrent savepath override still works for
        # sorting straight into Shows/Movies/etc.
        download-dir = "/mnt/kaori-media/downloads";
        # incomplete-dir left at its local default -- same NFS-latency
        # reasoning as slskd.
        rpc-bind-address = "0.0.0.0";
        peer-port-random-on-start = false;
      };
      openPeerPorts = true;
      openRPCPort = false;
    };

    # BindPaths otherwise only exposes download-dir itself inside the
    # sandbox -- extend it to the whole export so a per-torrent savepath
    # override (e.g. Shows/, Movies/) is actually reachable.
    systemd.services.transmission.serviceConfig.BindPaths = [ "/mnt/kaori-media" ];
    # RPC unauthenticated-by-config: transmission self-generates
    # rpc-username/password on first start and requires them by default.
    # Retrieve with: cat /var/lib/transmission/.config/transmission-daemon/settings.json

    # tailnet-only RPC, same posture as slskd's admin UI.
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9091 ];

    # No TTY for sudo prompts from Melete's shell -- same as jellyfin/slskd.
    security.sudo.extraRules = [
      {
        users = [ username ];
        commands =
          let
            systemctl = "/run/current-system/sw/bin/systemctl";
            verbs = [ "start" "stop" "restart" "reload" ];
          in
          map (verb: {
            command = "${systemctl} ${verb} transmission.service";
            options = [ "NOPASSWD" ];
          }) verbs;
      }
    ];
  };
}
