{ ... }: {
  imports = [ ./hardware.nix ];
  dx.aggregations = {
    desktop = true;
    hyprland = true;
  };
  dx.bluetooth.enable = true;
  dx.syncthing.enable = true;
  dx.laptop.enable = true;
  # consolidated to sakaki-only, 2026-07-31
  dx.melete.enable = false;
  dx.gpu-intel.enable = true;
  boot = {
    initrd.kernelModules = [ "nvme" ];
    resumeDevice = "/dev/nvme0n1p3";
  };
}
