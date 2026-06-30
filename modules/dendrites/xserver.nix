{
  pkgs,
  config,
  ...
}: {
  services = {
    xserver = {
      enable = true;
      xkb.layout = "us,jp";
    };
  };
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
