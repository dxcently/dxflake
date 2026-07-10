{ lib, config, username, ... }: {
  options.dx.melete.enable = lib.mkEnableOption "Melete AI harness service";

  config = lib.mkIf config.dx.melete.enable {
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

    # MCP server env — only rendered on osaka (URL is host-specific).
    # On other hosts the EnvironmentFile is absent; melete starts without MCP.
    sops.secrets."melete/auth-password" = lib.mkIf (config.networking.hostName == "osaka") {
      sopsFile = ../../secrets/melete-password.yaml;
      key = "melete-auth-password";
      owner = username;
      mode = "0400";
    };

    sops.templates."melete-env" = lib.mkIf (config.networking.hostName == "osaka") {
      content = ''
        MELETE_PUBLIC_URL=https://osaka.tailc27b51.ts.net
        MELETE_AUTH_PASSWORD=${config.sops.placeholder."melete/auth-password"}
        MELETE_AUTH_STATE_FILE=/home/${username}/.local/state/melete/auth-state.json
      '';
      path = "/run/secrets/melete-env";
      owner = username;
      mode = "0400";
    };

    # Binary and config are deployed out-of-band. The Condition guards against
    # crash-looping on a host where deployment hasn't happened yet.
    systemd.services.melete = {
      description = "Melete — Mneme's companion AI harness";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = [
        "/home/${username}/.local/bin/melete"
        "/etc/melete/config.toml"
      ];
      serviceConfig = {
        Type = "simple";
        User = username;
        Environment = [
          "HOME=/home/${username}"
          "PATH=/home/${username}/.local/bin:/home/${username}/.cargo/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin"
        ];
        EnvironmentFile = "-/run/secrets/melete-env";
        WorkingDirectory = "/home/${username}/melete";
        ExecStart = "/home/${username}/.local/bin/melete --config /etc/melete/config.toml serve";
        Restart = "on-failure";
        RestartSec = 10;
        CPUWeight = 200;
        OOMScoreAdjust = -500;
        TimeoutStopSec = "16min";
      };
    };
  };
}
