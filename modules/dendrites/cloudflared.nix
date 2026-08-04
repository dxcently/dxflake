# Cloudflare Tunnel (cloudflared), locally managed.
#
# Outbound-only: cloudflared connects to Cloudflare's edge and serves public
# hostnames from behind NAT with no open firewall ports. All ingress traffic is
# sent to Caddy on 127.0.0.1:8080, which routes by Host header — so this module
# and dx.caddy are a pair.
#
# Getting started (once only, before flipping dx.cloudflared.enable):
#   1. Buy a domain and move its DNS to Cloudflare (nameservers).
#   2. On any machine with a browser:
#        cloudflared tunnel login            # browser auth -> cert.pem
#        cloudflared tunnel create sakaki    # prints UUID, writes ~/.cloudflared/<uuid>.json
#   3. Store the credentials JSON in sops (the .sops.yaml wildcard rule
#      already covers secrets/):
#        sops secrets/cloudflared.yaml       # key `credentials:` = the <uuid>.json content verbatim
#   4. In hosts/sakaki/default.nix:
#        dx.cloudflared = {
#          enable = true;
#          tunnelId = "<uuid>";                              # from step 2
#          hostnames = [ "example.com" "www.example.com" ];  # keep in sync with dx.caddy.sites
#        };
#        dx.caddy = {
#          enable = true;
#          sites."example.com".webRoot = /var/www/personal;
#        };
#   5. In Cloudflare DNS: CNAME `*` (or per-hostname) -> <tunnelId>.cfargotunnel.com (proxied).
#   6. sudo nixos-rebuild switch --flake .#sakaki
#
# Known limitation: the free Cloudflare proxy caps uploads at 100 MB per
# request, so media-heavy apps (Immich video uploads, large file transfers)
# belong on the tailnet, not behind this tunnel.
{
  config,
  lib,
  username,
  ...
}:
let
  cfg = config.dx.cloudflared;
in
{
  options.dx.cloudflared = {
    enable = lib.mkEnableOption "cloudflared Cloudflare Tunnel (locally managed, ingress in Nix)";

    tunnelId = lib.mkOption {
      type = lib.types.str;
      description = ''
        Tunnel UUID from `cloudflared tunnel create`. Also the DNS target:
        <tunnelId>.cfargotunnel.com. No default — set per the getting-started
        steps at the top of this file.
      '';
    };

    hostnames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Public hostnames routed through the tunnel. All are sent to Caddy on
        127.0.0.1:8080; Caddy routes by Host header. Should match the keys of
        dx.caddy.sites.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."cloudflared/credentials" = {
      sopsFile = ../../secrets/cloudflared.yaml;
    };

    # The upstream unit LoadCredentials the file into credentials.json and
    # cloudflared parses it as raw JSON. A sops YAML secret would decrypt to
    # YAML (unquoted keys) and break that parser, so render the decrypted
    # value through a template — the repo's documented pattern for exact
    # string output (AGENTS.md "Secrets"). Default root:0400 template is fine:
    # systemd reads the file at unit start, before the DynamicUser drop.
    sops.templates."cloudflared-credentials.json" = {
      content = config.sops.placeholder."cloudflared/credentials";
    };

    services.cloudflared = {
      enable = true;
      tunnels.${cfg.tunnelId} = {
        credentialsFile = config.sops.templates."cloudflared-credentials.json".path;
        # Mandatory catch-all (rendered last by the module); unknown hostnames
        # 404 instead of leaking to some other service.
        default = "http_status:404";
        # Exact hostnames only — no wildcards. Everything lands on Caddy's
        # loopback :8080 and Caddy does the hostname routing.
        ingress = lib.genAttrs cfg.hostnames (_: "http://127.0.0.1:8080");
      };
    };

    # No networking.firewall changes: cloudflared only makes outbound
    # connections to the edge. No listen port, no openFirewall, works behind
    # NAT/CGNAT.

    # Same rationale as jellyfin/immich/slskd: Melete's shell has no TTY, so an
    # interactive sudo prompt makes the tunnel unmanageable from the agent
    # surface. Scoped to lifecycle verbs on the tunnel unit only — not a
    # systemctl grant.
    security.sudo.extraRules = [
      {
        users = [ username ];
        commands =
          let
            systemctl = "/run/current-system/sw/bin/systemctl";
            unit = "cloudflared-tunnel-${cfg.tunnelId}.service";
            verbs = [
              "start"
              "stop"
              "restart"
              "reload"
            ];
          in
          map (verb: {
            command = "${systemctl} ${verb} ${unit}";
            options = [ "NOPASSWD" ];
          }) verbs;
      }
    ];
  };
}
