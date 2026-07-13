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

    # The authenticated fixed-output fetch runs under nix-daemon, so the token
    # must live in the daemon's environment (not the invoking shell). sops
    # decrypts it into an EnvironmentFile line; restart nix-daemon after the
    # first deploy so it picks the token up before building meletePkg.
    sops.secrets."melete/read-token".sopsFile = ../../secrets/melete-token.yaml;
    sops.templates."melete-read-token.env".content = "NIX_MELETE_READ_TOKEN=${
      config.sops.placeholder."melete/read-token"
    }";
    systemd.services.nix-daemon.serviceConfig.EnvironmentFile =
      config.sops.templates."melete-read-token.env".path;

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
