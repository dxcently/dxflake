{
  pkgs,
  config,
  lib,
  ...
}: {
  options.dx.openrazer.enable = lib.mkEnableOption "openrazer";
  config = lib.mkIf config.dx.openrazer.enable {
    hardware.openrazer.enable = true;
    environment.systemPackages = with pkgs; [
      openrazer-daemon
      polychromatic
    ];
  };
}
