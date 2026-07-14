{
  lib,
  config,
  pkgs,
  username,
  ...
}:
let
  meletePkg = pkgs.callPackage ../../pkgs/melete { };
in
{
  options.dx.melete.enable = lib.mkEnableOption "Melete AI harness service";

  config = lib.mkIf config.dx.melete.enable {
    # --- Reproducible baseline, self-update floats above it ------------------
    # Nix pins a specific canary (pkgs/melete). We seed ~/.local/bin/melete
    # from that store binary ONLY when the pinned version changes (tracked by a
    # stamp file). Between bumps the running binary is left untouched, so
    # melete's self-update owns it and survives reboots. Bump version+sha256 in
    # pkgs/melete to deterministically reset every host to a known binary.
    system.activationScripts.meleteSeed = {
      deps = [ "users" ];
      text = ''
        bindir="/home/${username}/.local/bin"
        bin="$bindir/melete"
        stamp="$bindir/.melete-pinned"
        want="${meletePkg.version}"
        if [ "$(cat "$stamp" 2>/dev/null)" != "$want" ] || [ ! -e "$bin" ]; then
          install -Dm755 ${meletePkg}/bin/melete "$bin"
          printf '%s' "$want" > "$stamp"
          chown -R ${username}:users "$bindir"
        fi
      '';
    };

    # The authenticated fixed-output fetch runs under nix-daemon. On Nix 2.34+,
    # __impureEnvVars no longer reads ANY process environment — not the invoking
    # shell, not the daemon's own env, not an EnvironmentFile / set-environment
    # (verified empirically: a FOD listing TZDIR in __impureEnvVars sees it empty
    # even though nix-daemon has TZDIR in its Environment=). The only channel
    # that reaches a FOD builder now is the trusted `impure-env` setting, gated
    # behind the `configurable-impure-env` experimental feature and honored only
    # from trusted config (nix.conf), never from an untrusted client.
    #
    # sops renders `impure-env = NIX_MELETE_READ_TOKEN=<token>` into a root-only
    # (0400) file that nix.conf `!include`s, so the token never lands in
    # world-readable /etc/nix/nix.conf. COLD-HOST NOTE: this config only exists
    # after a successful activation, but building meletePkg needs the token
    # first — so a host that has never activated melete must break the catch-22
    # once by hand (see project_melete_token_bootstrap memory):
    #   sudo nixos-rebuild switch --flake .#<host> \
    #     --option extra-experimental-features configurable-impure-env \
    #     --option impure-env "NIX_MELETE_READ_TOKEN=<token>"
    # After that first activation, canary bumps build automatically.
    sops.secrets."melete/read-token".sopsFile = ../../secrets/melete-token.yaml;
    sops.templates."melete-impure-env.conf".content = "impure-env = NIX_MELETE_READ_TOKEN=${
      config.sops.placeholder."melete/read-token"
    }";
    nix.settings.experimental-features = [ "configurable-impure-env" ];
    nix.extraOptions = ''
      !include ${config.sops.templates."melete-impure-env.conf".path}
    '';

    # ~/.local/bin is only in ~/.profile (login shells); add it to bashrc so
    # Hyprland terminal emulators (non-login) pick it up too.
    home-manager.users.${username}.programs.bash.bashrcExtra = ''
      export PATH="$HOME/.local/bin:$PATH"
    '';

    # Allow khoa to restart melete.service without auth — needed for the
    # self-update swap (renames new binary into place, then restarts itself).
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") === "melete.service" &&
            subject.user === "${username}") {
          return polkit.Result.YES;
        }
      });
    '';

    # Binary and config are deployed out-of-band to ~/.config/melete/.
    # The Condition guards against crash-looping on a host where deployment
    # hasn't happened yet.
    systemd.services.melete = {
      description = "Melete — Mneme's companion AI harness";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = [
        "/home/${username}/.local/bin/melete"
        "/home/${username}/.config/melete/config.toml"
      ];
      serviceConfig = {
        Type = "simple";
        User = username;
        Environment = [
          "HOME=/home/${username}"
          "PATH=/home/${username}/.local/bin:/home/${username}/.cargo/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin"
        ];
        EnvironmentFile = "-/home/${username}/.config/melete/melete.env";
        WorkingDirectory = "/home/${username}/Melete";
        ExecStart = "/home/${username}/.local/bin/melete --config /home/${username}/.config/melete/config.toml serve";
        Restart = "on-failure";
        RestartSec = 10;
        CPUWeight = 200;
        OOMScoreAdjust = -500;
        TimeoutStopSec = "16min";
      };
    };
  };
}
