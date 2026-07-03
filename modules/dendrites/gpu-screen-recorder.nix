{
  pkgs,
  config,
  lib,
  ...
}: {
  options.dx.gpu-screen-recorder.enable = lib.mkEnableOption "gpu-screen-recorder";
  config = lib.mkIf config.dx.gpu-screen-recorder.enable {
    programs.gpu-screen-recorder.enable = true;
    environment.systemPackages = [pkgs.gpu-screen-recorder-gtk];
  };
}
