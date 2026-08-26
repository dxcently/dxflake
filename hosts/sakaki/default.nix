{...}: {
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
        "transmission"
      ];
    };
  };
  dx.mneme.enable = true;
  dx.immich.enable = true;
  dx.slskd.enable = true;
  dx.transmission.enable = true;

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
      # weedaq, read-only to the public, on its own registered domain rather
      # than a fold under the melete gateway: the gateway is all-or-nothing
      # (one apps/gate_token for every app it fronts; app.toml has no per-app
      # auth field), and this is the one app meant to be readable without a
      # login. The gated admin copy still lives at
      # melete.necoconeco.net/weedaq/ via apps.gateway_apps.
      "weedaq.com"
      "www.weedaq.com"
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

      # weedaq, public READ ONLY.
      #
      # Port 8110, not the daemon's 8105: melete decides app auth by BIND
      # ADDRESS, not by config -- a 127.0.0.1 bind serves without auth
      # ("loopback dev bind"), while the daemon-hosted copy on 8105 stays
      # gated behind apps/gate_token (that gated copy is the admin site,
      # folded at melete.necoconeco.net/weedaq/). 8110 is the ungated
      # loopback bind this hostname proxies.
      #
      # Which makes Caddy the ONLY thing between the open internet and
      # /api/snapshot + /api/tiers, both of which WRITE. The method guard
      # below is therefore load-bearing, not defence in depth: anything that
      # is not GET/HEAD is refused at the edge before it reaches Rune. The
      # scraper is unaffected -- it POSTs to 127.0.0.1:8110 on the box, where
      # Caddy never sees the request.
      "weedaq.com".extraConfig = ''
        @writes not method GET HEAD
        respond @writes "weedaq is read-only over the public hostname" 405

        reverse_proxy http://127.0.0.1:8110
      '';

      "www.weedaq.com".extraConfig = ''
        redir https://weedaq.com{uri} 301
      '';
    };
  };

  # Aoide, headless: the CLI + aoided runtime and the A2A door, for
  # federation/doors testing against yomi-strix. No facets, no rice —
  # nothing paints on this box. The door binds loopback:8710; a remote
  # peer reaches it over an ssh tunnel or the tailnet, never a raw
  # interface. Set aoide.a2a.tokenFile at rebuild time to require a
  # bearer token (which also stops loopback being an implicit trust
  # signal); spawnAgent stays empty so message/send cannot spawn.
  aoide = {
    enable = true;
    a2a = {
      enable = true;
      spawnAgent = "claude";
      discoveryAvertise = true;
    };
    # Secrets broker (Aoide workstream #58, deployed P-V4): own uid behind a
    # socket-only door, TOTP-gated. The operator joins the access group;
    # enrollment is a separate, User-initiated act — never part of the switch.
    secrets = {
      enable = true;
      members = ["khoa"];
    };
  };
}
