# Cloudflare Tunnel (cloudflared), locally managed.
#
# Outbound-only: cloudflared connects to Cloudflare's edge and serves public
# hostnames from behind NAT with no open firewall ports — the one mechanism
# that survives networks which kill WireGuard/tailscale (public/corporate
# wifi), because it never opens a listening port; it only dials out over
# https. Each `hostnames` entry is sent to Caddy on 127.0.0.1:8080, which
# routes by Host header — so those entries and dx.caddy are a pair. Each
# `sshHostnames` entry instead lands on the box's own sshd (ssh://localhost:22)
# with no Caddy involved, for hosts that want tunnel-borne ssh reachability
# and nothing else (a laptop with no web service to expose).
#
# One tunnel per host: tunnelId is a per-machine identity, not shared, so two
# hosts enabling this module each get their own `cloudflared tunnel create`
# and their own credentials secret (credentialsSopsFile below) — never the
# same tunnelId or the same credentials file entry for two boxes.
#
# Getting started (once per host, before flipping dx.cloudflared.enable):
#   1. Buy a domain and move its DNS to Cloudflare (nameservers) — once, for
#      the whole zone, not per host.
#   2. On any machine with a browser:
#        cloudflared tunnel login             # browser auth -> cert.pem
#        cloudflared tunnel create <hostname> # prints UUID, writes ~/.cloudflared/<uuid>.json
#   3. Store the credentials JSON in its own sops file (the .sops.yaml
#      wildcard rule already covers secrets/ for every host's age key):
#        sops secrets/cloudflared-<hostname>.yaml   # key `credentials:` = the <uuid>.json content verbatim
#      (sakaki, the first host wired here, kept the unsuffixed
#      secrets/cloudflared.yaml — its credentialsSopsFile default.)
#   4. In hosts/<hostname>/default.nix:
#        dx.cloudflared = {
#          enable = true;
#          tunnelId = "<uuid>";                                # from step 2
#          credentialsSopsFile = ../../secrets/cloudflared-<hostname>.yaml; # from step 3, omit for sakaki
#          hostnames = [ "example.com" "www.example.com" ];     # http, keep in sync with dx.caddy.sites
#          sshHostnames = [ "<hostname>-ssh.example.com" ];     # ssh, no Caddy needed
#        };
#        dx.caddy = {                        # only if `hostnames` is non-empty
#          enable = true;
#          sites."example.com".webRoot = /var/www/personal;
#        };
#   5. In Cloudflare DNS: CNAME each hostname (both lists) -> <tunnelId>.cfargotunnel.com (proxied).
#   6. sudo nixos-rebuild switch --flake .#<hostname>
#   7. To reach an sshHostnames entry from another box:
#        cloudflared access ssh --hostname <hostname>-ssh.example.com --url localhost:2222 &
#        ssh -p 2222 khoa@localhost
#      or fold that into ~/.ssh/config as a ProxyCommand (see the runbook —
#      dxflake does not manage ssh client config, so this stays a per-client step).
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

    sshHostnames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Public hostnames routed straight to this host's own sshd
        (ssh://localhost:22) instead of Caddy. Lets a box with no Caddy/web
        service (a laptop, say) still expose ssh over the tunnel. Reached
        client-side with `cloudflared access ssh --hostname <name> --url
        localhost:<local-port>` as an ssh ProxyCommand — see the getting-started
        comment above.
      '';
    };

    credentialsSopsFile = lib.mkOption {
      type = lib.types.path;
      default = ../../secrets/cloudflared.yaml;
      description = ''
        sops file holding this host's tunnel credentials JSON under the
        `cloudflared/credentials` key. Defaults to the shared
        secrets/cloudflared.yaml (sakaki's tunnel, the first wired here).
        Every other host enabling this module runs its own
        `cloudflared tunnel create` and points this at its own file
        (e.g. secrets/cloudflared-<hostname>.yaml) — a tunnel credential is
        per-machine, never shared across two hosts.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."cloudflared/credentials" = {
      sopsFile = cfg.credentialsSopsFile;
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
        # Exact hostnames only — no wildcards. `hostnames` lands on Caddy's
        # loopback :8080 and Caddy does the hostname routing; `sshHostnames`
        # goes straight to this host's own sshd, bypassing Caddy entirely.
        ingress =
          lib.genAttrs cfg.hostnames (_: "http://127.0.0.1:8080")
          // lib.genAttrs cfg.sshHostnames (_: "ssh://localhost:22");
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
