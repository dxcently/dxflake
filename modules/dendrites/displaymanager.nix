{
  pkgs,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dx.aggregations.desktop {
    services = {
      displayManager.ly = {
        enable = true;
        settings = {
          animation = "colormix";
          animation_timeout_sec = 300;
          clock = "%c";
          clear_password = true;
        };
      };
    };
  };
}
