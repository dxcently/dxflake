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
          # Completed downloads land inside the shared tree, so they're
          # re-shared on the next scan with no move step. Loose files here are
          # downloads by default; curated material gets sorted out into
          # _self-curated by hand.
          downloads = "/mnt/kaori-media/Music";
          # incomplete deliberately left unset -> slskd's own default under
          # --app-dir (/var/lib/slskd/incomplete), i.e. local NVMe. Chunk
          # writes during a transfer are latency-sensitive and NFS round-trips
          # each one; leaving it unset also keeps it out of ReadWritePaths, so
          # slskd creates it itself rather than needing tmpfiles to pre-make it.
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

    # openFirewall above only covers the p2p listen port (50300), and the LAN
    # has no business reaching the admin UI — so open 5030 on the tailnet
    # interface alone. Loopback works regardless, which is why it appears
    # reachable from sakaki itself even with the port closed.
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 5030 ];

    # The upstream module derives ReadOnlyPaths from shares.directories, but
    # downloads land INSIDE the share (that's the point — no move step). The
    # same path listed both read-only and read-write resolves to read-only, and
    # slskd's own preflight then refuses to start ("exists, but is not
    # writeable"). Drop the redundant read-only bind; ReadWritePaths still
    # confines the unit to just this tree.
    systemd.services.slskd.serviceConfig.ReadOnlyPaths = lib.mkForce [ ];

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
