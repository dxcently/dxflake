{ lib, config, username, ... }: {
  options.dx.melete.enable = lib.mkEnableOption "Melete AI harness service";

  config = lib.mkIf config.dx.melete.enable {
    # Shared Mneme operator passphrase — one sops value, readable by the
    # melete service user so mcp_password_file can point straight at it.
    sops.secrets."mneme/auth-password" = {
      sopsFile = ../../secrets/mneme-password.yaml;
      key = "mneme-auth-password";
      owner = username;
      mode = "0400";
      path = "/run/secrets/mneme/auth-password";
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
        EnvironmentFile = "-/etc/melete/melete.env";
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
