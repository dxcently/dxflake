{
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
}
