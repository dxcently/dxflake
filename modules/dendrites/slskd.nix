{ config, lib, username, ... }: {
  options.dx.slskd.enable = lib.mkEnableOption "slskd (headless Soulseek daemon)";

  config = lib.mkIf config.dx.slskd.enable {
    sops.secrets."slskd/username" = {
      sopsFile = ../../secrets/slskd.yaml;
      owner = username;
    };
    sops.secrets."slskd/password" = {
      sopsFile = ../../secrets/slskd.yaml;
      owner = username;
    };
    sops.secrets."slskd/web-username" = {
      sopsFile = ../../secrets/slskd.yaml;
      owner = username;
    };
    sops.secrets."slskd/web-password" = {
      sopsFile = ../../secrets/slskd.yaml;
      owner = username;
    };

    # Renders /run/secrets/slskd-env at activation; never hits the Nix store.
    sops.templates."slskd-env" = {
      content = ''
        SLSKD_SLSK_USERNAME=${config.sops.placeholder."slskd/username"}
        SLSKD_SLSK_PASSWORD=${config.sops.placeholder."slskd/password"}
        SLSKD_USERNAME=${config.sops.placeholder."slskd/web-username"}
        SLSKD_PASSWORD=${config.sops.placeholder."slskd/web-password"}
      '';
      path = "/run/secrets/slskd-env";
      owner = username;
      mode = "0400";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/slskd/downloads 0750 ${username} users -"
      "d /var/lib/slskd/incomplete 0750 ${username} users -"
    ];

    services.slskd = {
      enable = true;
      # Run as the human user, not the module's default `slskd` system user.
      # kaori's NFS export is sec=sys and Music/ is owned by uid 1024, so a
      # 990 system uid simply cannot write there. Same reason jellyfin does it.
      user = username;
      group = "users";
      environmentFile = "/run/secrets/slskd-env";
      settings = {
        shares = {
          directories = [ "/mnt/kaori-media/Music" ];
          # OS/indexer cruft only. Cover art (jpg/png) is deliberately NOT
          # filtered — it belongs with the album.
          filters = [
            "\\.ini$"
            "Thumbs\\.db$"
            "\\.DS_Store$"
            "desktop\\.ini$"
            "@eaDir"
          ];
        };
        directories = {
          downloads = "/var/lib/slskd/downloads";
          incomplete = "/var/lib/slskd/incomplete";
        };
        web.port = 5030;
        # Reachable over tailnet only — no domain/nginx vhost, no public firewall hole.
        global.upload = {
          slots = 5;
          speed_limit = 1250; # KB/s (~10Mbps)
        };
      };
      # Soulseek p2p listen port stays closed; tailnet already gates access.
      openFirewall = false;
    };

    # Same rationale as immich/jellyfin: Melete's shell has no TTY, so an
    # interactive sudo prompt makes slskd unmanageable from the agent surface.
    # Scoped to lifecycle verbs on the slskd unit only -- not a systemctl grant.
    security.sudo.extraRules = [
      {
        users = [ username ];
        commands =
          let
            systemctl = "/run/current-system/sw/bin/systemctl";
            verbs = [ "start" "stop" "restart" "reload" ];
          in
          map (verb: {
            command = "${systemctl} ${verb} slskd.service";
            options = [ "NOPASSWD" ];
          }) verbs;
      }
    ];
  };
}
