{
  pkgs,
  config,
  lib,
  ...
}: {
  options.dx.virtualisation.enable = lib.mkEnableOption "virtualisation";
  config = lib.mkIf config.dx.virtualisation.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
      };
      spiceUSBRedirection.enable = true;
      docker.enable = true;
      podman = {
        enable = true;
        dockerCompat = false;
      };
    };
  };
}
