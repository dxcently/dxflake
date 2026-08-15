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
      # MCP endpoint for the claude.ai connector. The tailscale funnel
      # (sakaki.tailc27b51.ts.net -> 127.0.0.1:8787) is degraded by the
      # Tailscale 1.102.x peerapi-ingress bug (tailscale#20746), so the
      # connector rides the Cloudflare tunnel instead. Cloudflare owns TLS;
      # melete's MCP server does its own OAuth (RFC 9728 challenge).
      "mcp.necoconeco.net"
      # Same for mneme's MCP server: its own tailscale funnel
      # (mneme.tailc27b51.ts.net -> 127.0.0.1:8000) is on the same buggy
      # tailscale path, so give it a Cloudflare route too.
      "mneme.necoconeco.net"
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
      # Melete's MCP server (OAuth + RFC 9728 challenge handled by melete
      # itself, so a bare proxy is enough). The claude.ai connector points
      # here because the tailscale funnel it used to ride is degraded by
      # tailscale#20746 (peerapi ingress drops).
      "mcp.necoconeco.net".proxy = "http://127.0.0.1:8787";

      # Mneme's MCP server — same reasoning, same bare-proxy shape (mneme
      # also does its own OAuth, issuer derived from the request host).
      "mneme.necoconeco.net".proxy = "http://127.0.0.1:8000";

      "status.necoconeco.net".extraConfig = ''
        redir https://melete.necoconeco.net/sakaki-panel{uri} 302
      '';
    };
  };

}
