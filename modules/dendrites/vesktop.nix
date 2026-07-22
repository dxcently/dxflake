{username, config, lib, ...}: {
  # SLATED 2026-07-22 - vesktop/discord disabled fleet-wide.
  # Restore by reverting this guard to `config.dx.aggregations.desktop`.
  config = lib.mkIf false {
    home-manager.users.${username} = {
      pkgs,
      config,
      ...
    }: {
      programs.vesktop = {
        enable = true;
        package = pkgs.vesktop;
        vencord = {
          settings = {
            AlwaysTrust = true;
            autoUpdateNotification = false;
            notifyAboutUpdates = false;
            disableMinSize = true;
            plugins = {
              FakeNitro.enabled = true;
              BiggerStreamPreview = true;
              CallTimer = true;
              CrashHandler = true;
              oneko = true;
              SilentTyping = true;
              VoiceMessages = true;
              Viewicons = true;
            };
          };
        };
      };
    };
  };
}
