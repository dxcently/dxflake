{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  config = lib.mkIf config.dx.aggregations.desktop {
    hardware = {
      opentabletdriver = {
        enable = true;
        daemon.enable = true;
      };
      keyboard.qmk.enable = true;
    };
  };
}
