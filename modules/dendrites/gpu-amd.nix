{
  pkgs,
  config,
  lib,
  ...
}: {
  options.dx.gpu-amd.enable = lib.mkEnableOption "gpu-amd";
  config = lib.mkIf config.dx.gpu-amd.enable {
    boot.initrd.kernelModules = ["amdgpu"];
    services.xserver.videoDrivers = ["amdgpu"];
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    # HIP
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];
  };
}
