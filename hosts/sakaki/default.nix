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
      "auth.necoconeco.net"
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

      # Central login for every necoconeco.net site that doesn't already
      # have its own auth -- Jellyfin and Syncthing keep theirs, untouched.
      # Serves auth-login.html at / and /login, proxies /verify to a live
      # Melete app (any of them works: they all share the one
      # apps.auth_token_file secret), and clears the shared cookie on
      # /logout. See auth-login.html and apps/sakaki-panel/README.md.
      "auth.necoconeco.net".extraConfig = ''
        @verify path /verify
        reverse_proxy @verify http://127.0.0.1:8100

        @logout path /logout
        header @logout Set-Cookie "sp_session=; Domain=.necoconeco.net; Path=/; Max-Age=0; Secure; SameSite=Lax"
        redir @logout /login 302

        @page {
        	not path /verify /logout
        }
        root @page /etc/necoconeco-auth
        rewrite @page /login.html
        file_server @page
      '';

      # sakaki-panel behind the central login above (auth.necoconeco.net).
      # Melete's app gate only accepts the secret as ?__melete_token= or an
      # Authorization: Bearer header -- never a cookie -- so Caddy does the
      # translation: guests get bounced to auth.necoconeco.net/login, whose
      # JS probes the password against /verify and stores it in the
      # sp_session cookie (Domain=.necoconeco.net, so it's already present
      # here too once set). Matchers below are mutually exclusive so
      # exactly one route handles each request.
      "status.necoconeco.net".extraConfig = ''
        @logout path /logout
        redir @logout https://auth.necoconeco.net/logout 302

        @authed header Cookie *sp_session=*
        reverse_proxy @authed http://127.0.0.1:8100 {
        	header_up Authorization "Bearer {http.request.cookie.sp_session}"
        }

        @guest {
        	not path /logout
        	not header Cookie *sp_session=*
        }
        redir @guest https://auth.necoconeco.net/login?return=https://status.necoconeco.net/ 302
      '';
    };
  };

  # The central necoconeco.net login page Caddy serves at auth.necoconeco.net
  # (see dx.caddy.sites above). 0644 root is readable by the caddy unit.
  environment.etc."necoconeco-auth/login.html".source = ./auth-login.html;
}
