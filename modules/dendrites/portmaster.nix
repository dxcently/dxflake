{
  lib,
  config,
  ...
}: let
  cfg = config.dx.portmaster;
in {
  options.dx.portmaster = {
    enable = lib.mkEnableOption "Portmaster application firewall";
  };

  config = lib.mkIf cfg.enable {
    services.portmaster.enable = true;
  };
}
