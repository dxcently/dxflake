{ ... }: {
  imports = [
    ./hardware.nix
    ./syncthing.nix
  ];
  dx.aggregations.server = true;
  dx.claude-code.enable = true;
  dx.pi-coding-agent.enable = true;
  dx.kimi-cli.enable = true;
  dx.syncthing.enable = true;
  dx.autologin.enable = true;
  dx.melete.enable = true;
  dx.nas-mounts = {
    enable = true;
    mounts."/mnt/kaori-media" = {
      export = "/volume1/media";
      requiredBy = [
        "jellyfin"
        "slskd"
      ];
    };
  };
  dx.mneme.enable = true;
  dx.immich.enable = true;
  dx.slskd.enable = true;

  # Public face: Cloudflare Tunnel -> Caddy on loopback :8080. Media stays on
  # the tailnet; only the lightweight web UIs are exposed for now.
  dx.cloudflared = {
    enable = true;
    tunnelId = "304afa6f-0ac6-4d0e-abf1-206cde260bd3";
    hostnames = [
      "jellyfin.necoconeco.net"
      "syncthing.necoconeco.net"
      "status.necoconeco.net"
      "melete.necoconeco.net"
    ];
  };
  dx.caddy = {
    enable = true;
    sites = {
      "jellyfin.necoconeco.net".proxy = "http://127.0.0.1:8096";
      "syncthing.necoconeco.net".proxy = "http://127.0.0.1:8384";

      # Melete's own app gateway -- native /login + session cookie, one
      # login for every app it fronts (scheduler-graph today; more of
      # Melete's built-in apps can join apps.gateway_apps later, folded
      # under /<app>/), named after the harness itself, not any one app
      # behind it. No cookie<->Bearer translation needed: unlike
      # sakaki-panel, the gateway is Rust-side and handles cookies itself,
      # so a bare proxy is enough (same shape as jellyfin/syncthing above,
      # which also front their own auth).
      "melete.necoconeco.net".proxy = "http://127.0.0.1:8090";

      # sakaki-panel now lives behind the melete gateway (folded at
      # /sakaki-panel/, same apps.gateway_apps as scheduler-graph) -- one
      # shared login for both instead of this hostname's own cookie/Bearer
      # translation. Plain path-preserving redirect keeps old bookmarks and
      # API calls working ({uri} carries /, /api/pins, etc. straight
      # through to the folded equivalent).
      "status.necoconeco.net".extraConfig = ''
        redir https://melete.necoconeco.net/sakaki-panel{uri} 302
      '';
    };
  };

}
