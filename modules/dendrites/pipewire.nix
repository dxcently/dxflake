{
  pkgs,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.dx.aggregations.desktop {
    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber = {
          enable = true;
        };
      };
    };
    environment.systemPackages = with pkgs; [
      alsa-ucm-conf
    ];
  };
}
