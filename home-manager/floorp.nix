{
  pkgs,
  config,
  ...
}: {
  programs.floorp = {
    enable = true;
    package = pkgs.floorp.override {
      nativeMessagingHosts = [
        pkgs.tridactyl-native
      ];
    };
  };
}
