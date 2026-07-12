{ lib, config, pkgs, username, ... }: {
  options.dx.mneme.enable = lib.mkEnableOption "Mneme vault MCP server";

  config = lib.mkIf config.dx.mneme.enable {
    # Allow khoa to restart mneme.service / tailscaled-mneme.service without
    # auth — so config/env changes (e.g. MNEME_PUBLIC_URL) can be applied
    # without root. Mirrors melete.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.systemd1.manage-units" &&
            (action.lookup("unit") === "mneme.service" ||
             action.lookup("unit") === "tailscaled-mneme.service") &&
            subject.user === "${username}") {
          return polkit.Result.YES;
        }
      });
    '';

    # Second, userspace Tailscale node dedicated to Mneme. Claude.ai connectors
    # only reach standard :443, and the host node (sakaki) already spends its
    # :443 funnel on Melete — so Mneme gets its OWN node/hostname
    # (mneme.tailc27b51.ts.net) and thus its own :443. Runs unprivileged in
    # userspace-networking mode with an isolated socket/state, so it never
    # touches the primary tailscaled. Auth + funnel config persist in statedir,
    # so it reconnects and re-serves :443 -> mneme on restart with no re-login.
    systemd.services.tailscaled-mneme = {
      description = "Tailscale node for Mneme (userspace, own :443 funnel)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = username;
        Environment = [ "HOME=/home/${username}" ];
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.tailscale}/bin/tailscaled"
          "--tun=userspace-networking"
          "--socket=/home/${username}/.local/state/tailscaled-mneme/tailscaled.sock"
          "--statedir=/home/${username}/.local/state/tailscaled-mneme"
          "--port=0"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # Binary deployed out-of-band; env file at ~/.config/melete/mneme.env
    # (user-managed, not in the Nix store). ConditionPathExists guards
    # against crash-looping until all three prerequisites exist.
    systemd.services.mneme = {
      description = "Mneme — Obsidian vault MCP server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = [
        "/home/${username}/.local/bin/mneme"
        "/home/${username}/Magi"
        "/home/${username}/.config/melete/mneme.env"
      ];
      serviceConfig = {
        Type = "simple";
        User = username;
        Environment = [
          "HOME=/home/${username}"
          "PATH=/home/${username}/.local/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin"
        ];
        EnvironmentFile = "/home/${username}/.config/melete/mneme.env";
        WorkingDirectory = "/home/${username}/Magi";
        ExecStart = "/home/${username}/.local/bin/mneme";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
