{
  pkgs,
  config,
  lib,
  ...
}: {
  options.dx.gpu-intel.enable = lib.mkEnableOption "gpu-intel";
  config = lib.mkIf config.dx.gpu-intel.enable {
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [intel-vaapi-driver];
    };
    nixpkgs.config.packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
    };
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}
