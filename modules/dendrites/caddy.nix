# Caddy reverse proxy behind the cloudflared tunnel.
#
# Caddy is the hostname router for public sites: the tunnel sends every
# hostname to http://127.0.0.1:8080 and Caddy picks the right site block by
# Host header. This is what makes "one domain, many distinct sites" possible —
# each future app is one `dx.caddy.sites` entry.
#
# Example:
#   dx.caddy.sites."example.com"     = { webRoot = /var/www/personal; };
#   dx.caddy.sites."git.example.com" = { proxy = "http://127.0.0.1:3000"; };
#
# Note: sites are keyed by hostname WITHOUT a scheme and get rendered as
# `http://<hostname>:8080` site addresses. The explicit http:// scheme tells
# Caddy never to attempt automatic HTTPS/cert management — Cloudflare's edge
# owns TLS for public traffic, the origin is plain HTTP on loopback.
{
  config,
  lib,
  ...
}:
let
  cfg = config.dx.caddy;
in
{
  options.dx.caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy behind the cloudflared tunnel";

    sites = lib.mkOption {
      default = { };
      description = ''
        Public sites keyed by hostname. Each is reachable through the tunnel
        once DNS + ingress are in place.
      '';
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            proxy = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Upstream to reverse-proxy to, e.g. http://127.0.0.1:8096.
                Mutually exclusive with webRoot.
              '';
            };
            webRoot = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = ''
                Static site root served with file_server. Mutually exclusive
                with proxy.
              '';
            };
            extraConfig = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Extra Caddyfile directives appended to the site block.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      # One site block per hostname, all bound to loopback :8080. Caddy merges
      # same-address listeners, so multiple vhosts share the single 127.0.0.1
      # socket cloudflared connects to.
      # Site address must carry the explicit http:// scheme and :8080 port:
      # without them Caddy would treat the hostname as an automatic-HTTPS :443
      # site and try to obtain certificates for it. With the scheme, Caddy
      # serves plain HTTP on :8080 only — Cloudflare's edge owns TLS.
      virtualHosts = lib.mapAttrs' (
        hostname: site:
        lib.nameValuePair "http://${hostname}:8080" {
          extraConfig = ''
            bind 127.0.0.1
            ${lib.optionalString (site.proxy != null) "reverse_proxy ${site.proxy}"}
            ${lib.optionalString (site.webRoot != null) "root * ${site.webRoot}\nfile_server"}
            ${site.extraConfig}
          '';
        }
      ) cfg.sites;
    };

    # No openFirewall, no networking.firewall rules: every site binds
    # 127.0.0.1 only, which is reachable regardless of the firewall and never
    # exposed on the LAN. Making a site reachable on the LAN (or via tailscale)
    # is a deliberate future decision.
    assertions = [
      {
        # Either kind of site (proxy, webRoot), or neither when the site's
        # routing is written entirely in extraConfig (e.g. sakaki-panel's
        # cookie->Bearer auth gate, where a bare `reverse_proxy` shortcut
        # would chain a second proxy onto matcher-qualified routes).
        assertion = lib.all (
          site: ((site.proxy == null) != (site.webRoot == null)) || site.extraConfig != ""
        ) (lib.attrValues cfg.sites);
        message = "dx.caddy.sites: each site must set exactly one of `proxy` or `webRoot`, or route entirely via `extraConfig`.";
      }
    ];
  };
}
