{pkgs, ...}: {
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
    # Đồng (dxcently/dong): direct photo uploads only. Photos already in
    # Immich are referenced in place on /mnt/immich and never copied here.
    # No requiredBy: the app starts without it and autofs mounts on first
    # write, so a missing export cannot take melete down with it.
    mounts."/mnt/dong".export = "/volume1/dong";
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
      # Đồng (dxcently/dong), shared with a few people under ONE shared
      # password of its own, so it cannot sit behind the gateway's single
      # login. Same shape as weedaq: an ungated loopback bind (:8111, the
      # dong-public user unit) fronted by Caddy; the app's own /login is the
      # door. The daemon-hosted copy on :8107 stays token-gated as the agent
      # door (run_app_tool) and is also folded at melete.necoconeco.net/dong/.
      "dong.necoconeco.net"

      # FAU Cyber Security Club wiki (Hugo + relearn), test hostname. Static
      # build output only: `hugo server` is a development server -- livereload
      # websocket, in-memory render, no cache headers -- and never faces the
      # tunnel. The repo lives at ~/projects/fau-cyber-security-club-wiki and
      # `hugo` writes public/, which is copied to the /var/www root below.
      "fau-cyber-wiki-test.necoconeco.net"
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

      # Đồng, public with its own login. Port 8111 is the ungated loopback
      # bind (dong-public user unit, ~/.config/systemd/user), the same trick
      # as weedaq's 8110. Unlike weedaq there is no method guard: writes are
      # the point, and the app refuses every page and every /api/* route
      # without its session cookie. Caddy forwards X-Forwarded-Proto so the
      # app marks its cookie Secure.
      #
      # Three paths go to the photo server (dong-photos user unit, 8203)
      # instead of the app, because Melete's app host cannot serve image
      # bytes: it has no filesystem capability and every reply is one 200
      # text/html body. Every photograph now lives in Immich (the worker
      # moves uploads there and drops the SQLite copy), so without this
      # block every card is a grey box -- the app answers those paths with an
      # HTML session shim that an <img> cannot render. The share paths are
      # the worker's for a different reason: the host hands an app its body
      # as from_utf8_lossy, which destroys a multipart JPEG before the app
      # sees it. `handle` (not handle_path) for those: the worker matches the
      # full path. NOT /api/share/* -- /api/share/token is the app's own.
      #
      # sw.js: a service worker may only claim a scope at or below its own
      # directory, and this one lives under /static/ but needs the app root;
      # the host cannot send the header that allows it, so Caddy does.
      #
      # Caddy evaluates handle/handle_path before a bare reverse_proxy
      # regardless of textual order, so `proxy` stays the catch-all.
      # See deploy/dong-workers.md §5 in dxcently/dong.
      "dong.necoconeco.net" = {
        proxy = "http://127.0.0.1:8111";
        extraConfig = ''
          handle_path /immich-photos/* {
            reverse_proxy 127.0.0.1:8203
          }
          handle /api/share/upload    { reverse_proxy 127.0.0.1:8203 }
          handle /api/share/parked/*  { reverse_proxy 127.0.0.1:8203 }
          handle /static/sw.js {
            header Service-Worker-Allowed "/"
            reverse_proxy 127.0.0.1:8111
          }
        '';
      };

      # file_server, not a proxy: 90 prerendered pages, no runtime behind
      # them. webRoot is a quoted STRING rather than a path literal -- a
      # literal is copied into the nix store at eval, which would put 7.6M of
      # build output in a store path and turn every content edit into a full
      # nixos-rebuild. Served out of /var/www because /home/khoa is 0700 and
      # caddy (uid 239) cannot traverse it.
      "fau-cyber-wiki-test.necoconeco.net" = {
        webRoot = "/var/www/fau-cyber-wiki-test";
        # HTML went out with no Cache-Control, so browsers heuristically cached
        # it and a redeploy showed up late -- a stale sidebar/title lingered on
        # pages visited before the change. no-cache keeps ETag revalidation but
        # forces a conditional request every load: cheap 304s, edits visible on
        # the next navigation. Assets carry a content hash in their URL, so they
        # are left to cache normally and only HTML is matched.
        extraConfig = ''
          # Compress text at the origin. Cloudflare compresses at its edge for
          # visitors, but Caddy was sending raw bytes to it and to anything that
          # reaches the box directly; ~4x on CSS/JS/HTML either way.
          encode zstd gzip

          @html path_regexp (\.html$|/$)
          header @html Cache-Control "no-cache"

          # Every CSS/JS link carries a build stamp in its query string that
          # changes whenever the file does, so a cached copy can never go stale
          # (a changed file is a new URL). Mark them immutable for a year. Fonts
          # and images are not busted and keep the default.
          @static path *.css *.js
          header @static Cache-Control "public, max-age=31536000, immutable"
        '';
      };
    };
  };

  # The wiki's served root: owned by khoa so `hugo` output copies in without
  # sudo, 0755 so caddy can read it.
  systemd.tmpfiles.rules = [
    "d /var/www                     0755 root root - -"
    "d /var/www/fau-cyber-wiki-test 0755 khoa users - -"
    "d /var/lib/fau-cyber-wiki      0755 khoa users - -"
  ];

  # Continuous deployment for the wiki. sakaki is outbound-only behind
  # cloudflared, so GitHub cannot push in -- the box polls instead. A cycle
  # that finds the hash unchanged exits before doing any work, so the
  # steady-state cost is one fetch every five minutes.
  #
  # The deploy checkout is NOT ~/projects/fau-cyber-security-club-wiki. That
  # is khoa's working copy and gets edited by hand; a deploy sharing it would
  # either publish half-finished local work or wedge on a dirty tree. This
  # one is `reset --hard` to origin/main every cycle, which is only safe
  # because nothing ever edits it.
  systemd.services.fau-cyber-wiki-deploy = {
    description = "Build and publish the FAU Cyber Security Club wiki from origin/main";
    path = [pkgs.git pkgs.hugo pkgs.rsync];
    serviceConfig = {
      Type = "oneshot";
      User = "khoa";
      Group = "users";
      WorkingDirectory = "/var/lib/fau-cyber-wiki";
    };
    script = ''
      set -euo pipefail
      # First cycle after a rebuild finds the tmpfiles dir empty and seeds it,
      # then falls through and publishes. Every later cycle takes the else arm.
      if [ ! -d .git ]; then
        git clone --quiet --recurse-submodules \
          https://github.com/dxcently/fau-cyber-security-club-wiki.git .
      else
        git fetch --quiet --prune origin main
        if [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ]; then
          exit 0
        fi
        git reset --hard --quiet origin/main
        # relearn is a submodule: without this hugo builds a layout-less site
        # rather than failing, which would publish a broken wiki silently.
        git submodule update --init --recursive --depth 1
      fi
      # baseURL is passed here, never committed -- hugo.toml keeps its
      # placeholder so the repo is not pinned to one deployment hostname.
      hugo --quiet --baseURL https://fau-cyber-wiki-test.necoconeco.net/
      rsync -a --delete public/ /var/www/fau-cyber-wiki-test/
    '';
  };

  systemd.timers.fau-cyber-wiki-deploy = {
    description = "Poll origin/main for FAU Cyber Security Club wiki changes";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
    };
  };

  # hugo builds the wiki. Nothing else on this box uses it, so it stays
  # host-local instead of joining the fleet-wide package set.
  environment.systemPackages = [pkgs.hugo];

  # Aoide, headless: the CLI + aoided runtime and the A2A door, for
  # federation/doors testing against yomi-strix. No facets, no rice —
  # nothing paints on this box. The core baseline (aoide.enable, the A2A
  # door, the secrets broker) comes from the shared dendrite
  # (modules/dendrites/aoide.nix), chiyo and osaka's same one; everything
  # below is what varies on THIS box. The door binds loopback:8710; a remote
  # peer reaches it over an ssh tunnel or the tailnet, never a raw
  # interface. Set aoide.a2a.tokenFile at rebuild time to require a
  # bearer token (which also stops loopback being an implicit trust
  # signal); spawnAgent is claude, with spawnPath carrying its package
  # onto the unit's PATH so the door can actually exec it.
  dx.aoide.enable = true;
  aoide.a2a = {
    spawnAgent = "claude";
    spawnPath = [pkgs.claude-code];
    discoveryAdvertise = true;
  };
  # Secrets broker (Aoide workstream #58, deployed P-V4): own uid behind a
  # socket-only door, TOTP-gated. The operator joins the access group;
  # enrollment is a separate, User-initiated act — never part of the switch.
  aoide.secrets.members = ["khoa"];
}
