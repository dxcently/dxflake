{ lib, config, pkgs, username, ... }:
let
  mnemePkg = pkgs.callPackage ../../pkgs/mneme-client-package.nix {
    version = "0.4.2";
    target = "mneme-x86_64-unknown-linux-musl";
    sha256 = "sha256-M6TuPhryiN739Bl/167J+ct6Yz7neJ4tYrF+musQVSU=";
  };
in
{
  options.dx.mneme.enable = lib.mkEnableOption "Mneme vault MCP server";

  config = lib.mkIf config.dx.mneme.enable {
    # Reproducible baseline, mirrors melete.nix's meleteSeed. Nix pins a
    # specific release (pkgs/mneme-client-package.nix). Unlike melete, mneme
    # has no self-update of its own, so this is the ONLY thing that ever
    # moves the binary -- between bumps it's just whatever was last seeded.
    system.activationScripts.mnemeSeed = {
      deps = [ "users" ];
      text = ''
        bindir="/home/${username}/.local/bin"
        bin="$bindir/mneme"
        stamp="$bindir/.mneme-pinned"
        want="${mnemePkg.version}"
        if [ "$(cat "$stamp" 2>/dev/null)" != "$want" ] || [ ! -e "$bin" ]; then
          install -Dm755 ${mnemePkg}/bin/mneme "$bin"
          printf '%s' "$want" > "$stamp"
          chown -R ${username}:users "$bindir"
        fi
      '';
    };

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

    # Polkit only covers D-Bus-mediated calls; a `sudo systemctl ...` from
    # Melete's TTY-less shell still prompts for a password. Same rationale as
    # immich/jellyfin: scoped to lifecycle verbs on the two mneme units only,
    # not a general systemctl grant.
    security.sudo.extraRules = [
      {
        users = [ username ];
        commands = let
          systemctl = "/run/current-system/sw/bin/systemctl";
          units = [ "mneme" "tailscaled-mneme" ];
          verbs = [ "start" "stop" "restart" "reload" ];
        in
          lib.flatten (map (verb:
            map (unit: {
              command = "${systemctl} ${verb} ${unit}.service";
              options = [ "NOPASSWD" ];
            })
            units)
          verbs);
      }
    ];

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
      # Same start-limit fix as melete.nix.
      unitConfig.StartLimitIntervalSec = 0;
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

    # Binary is now Nix-seeded (mnemeSeed above), not hand-placed -- but
    # ConditionPathExists is kept as a defensive guard regardless. Env file
    # at ~/.config/melete/mneme.env (user-managed, not in the Nix store,
    # unaffected by the seed).
    systemd.services.mneme = {
      description = "Mneme — Obsidian vault MCP server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      # Same start-limit fix as melete.nix -- don't let repeated early
      # failures permanently latch this unit into "failed".
      unitConfig.StartLimitIntervalSec = 0;
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
