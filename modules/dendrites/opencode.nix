# opencode — the TUI coding agent (nixpkgs' `opencode`). Its system half is the
# package; its home half is the MCP wiring, which is per-user by nature.
{ pkgs, ... }:
{
  config = {
    environment.systemPackages = [ pkgs.opencode ];

    habit.home =
      { ... }:
      {
        # Nix owns this file: opencode reads it and never writes it back. The
        # OAuth tokens it earns are NOT here — they land in
        # ~/.local/share/opencode/mcp-auth.json, written by
        # `opencode mcp auth <name>`, so managing this file read-only costs
        # nothing.
        #
        # Pointing at the public hostnames rather than loopback: both servers
        # bind 127.0.0.1 on sakaki (mneme :8000, melete :8787), and
        # mcp.necoconeco.net / mneme.necoconeco.net are Caddy bare proxies in
        # front of those ports (hosts/sakaki/default.nix). Each server does its
        # own OAuth — RFC 9728 challenge plus RFC 7591 dynamic registration —
        # which is what opencode auto-detects, so no client ID is configured
        # here and `opencode mcp auth mneme` is the one-time step. This route
        # works from any host with internet; eidolon's LAN SSH forward
        # (eidolon-mcp-forward.service) only works when the host is on sakaki's
        # own network.
        #
        # `timeout` is raised from the 5 s default: the tunnel's cold path is
        # slower than a loopback call.
        home.file.".config/opencode/opencode.json".text = builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
          mcp = {
            mneme = {
              type = "remote";
              url = "https://mneme.necoconeco.net/mcp";
              enabled = true;
              timeout = 20000;
            };
            melete = {
              type = "remote";
              url = "https://mcp.necoconeco.net/mcp";
              enabled = true;
              timeout = 20000;
            };
          };
        };
      };
  };
}
