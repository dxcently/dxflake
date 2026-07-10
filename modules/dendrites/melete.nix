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
