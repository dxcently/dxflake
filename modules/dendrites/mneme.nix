{ lib, config, username, ... }: {
  options.dx.mneme.enable = lib.mkEnableOption "Mneme vault MCP server";

  config = lib.mkIf config.dx.mneme.enable {
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
