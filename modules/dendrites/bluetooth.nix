{config, lib, ...}: {
  options.dx.bluetooth.enable = lib.mkEnableOption "bluetooth";
  config = lib.mkIf config.dx.bluetooth.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
