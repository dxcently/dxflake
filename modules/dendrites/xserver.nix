{
  pkgs,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dx.aggregations.desktop {
    services = {
      xserver = {
        enable = true;
        xkb.layout = "us,jp";
      };
    };
    systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
  };
}
