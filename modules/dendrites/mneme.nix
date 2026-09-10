{
  lib,
  config,
  pkgs,
  inputs,
  username,
  ...
}:
let
  # Built from the ~/mneme dev checkout (the `mneme-src` flake input)
  # — version and contents follow that repo. See flake.nix for how to pick up
  # a new commit or a dirty worktree.
  #
  # This no longer depends on dx.melete.enable: the release fetch used to
  # borrow melete's GitHub token wiring, so mneme could only build alongside
  # it. A source build needs no credential, so the two are independent now.
  mnemePkg = pkgs.callPackage ../../pkgs/mneme-package.nix {
    src = inputs.mneme-src;
  };
in
{
  options.dx.mneme.enable = lib.mkEnableOption "Mneme vault MCP server";

  config = lib.mkIf config.dx.mneme.enable {
    # Dev-checkout baseline, mirrors melete.nix's meleteSeed. Nix builds from
    # ~/mneme (pkgs/mneme-package.nix). Unlike melete, mneme has no
    # self-update of its own, so this is the ONLY thing that ever moves the
    # binary. The stamp holds the store path rather than the version, so a
    # source change reseeds even when Cargo.toml's version stands still.
    system.activationScripts.mnemeSeed = {
      deps = [ "users" ];
      text = ''
        bindir="/home/${username}/.local/bin"
        bin="$bindir/mneme"
        stamp="$bindir/.mneme-pinned"
        want="${mnemePkg}"
        if [ "$(cat "$stamp" 2>/dev/null)" != "$want" ] || [ ! -e "$bin" ]; then
          install -Dm755 ${mnemePkg}/bin/mneme "$bin"
          printf '%s' "$want" > "$stamp"
          chown -R ${username}:users "$bindir"
        fi
      '';
    };

    # Allow khoa to restart mneme.service without auth — so config/env
    # changes (e.g. MNEME_PUBLIC_URL) can be applied without root. Mirrors
    # melete.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") === "mneme.service" &&
            subject.user === "${username}") {
          return polkit.Result.YES;
        }
      });
    '';

    # Polkit only covers D-Bus-mediated calls; a `sudo systemctl ...` from
    # Melete's TTY-less shell still prompts for a password. Same rationale as
    # immich/jellyfin: scoped to lifecycle verbs on the mneme unit only,
    # not a general systemctl grant.
    security.sudo.extraRules = [
      {
        users = [ username ];
        commands =
          let
            systemctl = "/run/current-system/sw/bin/systemctl";
            verbs = [
              "start"
              "stop"
              "restart"
              "reload"
            ];
          in
          lib.flatten (
            map (verb: {
              command = "${systemctl} ${verb} mneme.service";
              options = [ "NOPASSWD" ];
            }) verbs
          );
      }
    ];

    # Mneme's own tailscale node was removed 2026-08-15: the claude.ai
    # connector reached it via the tailscaled-mneme :443 funnel
    # (mneme.tailc27b51.ts.net), but the Tailscale 1.102.x peerapi-ingress
    # bug (tailscale#20746) degraded that path and both MCP servers now ride
    # the Cloudflare tunnel instead (mneme.necoconeco.net). If a public MCP
    # path is ever needed again, prefer adding a hostname to
    # dx.cloudflared/dx.caddy in hosts/sakaki/default.nix.

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
