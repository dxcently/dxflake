{ ... }: {
  imports = [ ./hardware.nix ];
  dx.aggregations = {
    desktop = true;
    hyprland = true;
  };
  dx.bluetooth.enable = true;
  dx.laptop.enable = true;
  dx.gpu-intel.enable = true;
  dx.askSudo.enable = true;
  boot = {
    initrd.kernelModules = [ "nvme" ];
    resumeDevice = "/dev/nvme0n1p3";
  };
}
