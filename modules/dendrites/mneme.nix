{ lib, config, username, ... }: {
  options.dx.mneme.enable = lib.mkEnableOption "Mneme vault MCP server";

  config = lib.mkIf config.dx.mneme.enable {
    sops.secrets."mneme/auth-password" = {
      sopsFile = ../../secrets/mneme-password.yaml;
      key = "mneme-auth-password";
      owner = username;
      mode = "0400";
      path = "/run/secrets/mneme/auth-password";
    };

    # Env file rendered from the sops passphrase — never hits the Nix store.
    sops.templates."mneme-env" = {
      content = ''
        MNEME_PUBLIC_URL=http://localhost:8000
        MNEME_AUTH_PASSWORD=${config.sops.placeholder."mneme/auth-password"}
        MNEME_VAULT_DIR=/home/${username}/Mneme
        MNEME_BIND_ADDR=127.0.0.1:8000
        MNEME_TRASH_DIR=/home/${username}/Mneme-trash
        MNEME_VERSIONS_DIR=/home/${username}/Mneme-versions
        MNEME_AUTH_STATE_FILE=/home/${username}/.local/state/mneme/auth-state.json
      '';
      path = "/run/secrets/mneme-env";
      owner = username;
      mode = "0400";
    };

    # Binary deployed out-of-band; Condition guards against crash-looping.
    systemd.services.mneme = {
      description = "Mneme — Obsidian vault MCP server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = [
        "/home/${username}/.local/bin/mneme"
        "/home/${username}/Mneme"
      ];
      serviceConfig = {
        Type = "simple";
        User = username;
        Environment = [
          "HOME=/home/${username}"
          "PATH=/home/${username}/.local/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin"
        ];
        EnvironmentFile = "/run/secrets/mneme-env";
        WorkingDirectory = "/home/${username}/Mneme";
        ExecStart = "/home/${username}/.local/bin/mneme";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
