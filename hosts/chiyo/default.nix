{...}: {
  imports = [
    ./hardware.nix
    ../../modules/nucleus
    ../../modules/dendrites/desktop
    ../../modules/dendrites/hyprland
    ../../modules/dendrites/bluetooth.nix
    ../../modules/dendrites/laptop.nix
    ../../modules/dendrites/gpu-intel.nix
  ];

  boot = {
    initrd.kernelModules = ["nvme"];
    resumeDevice = "/dev/nvme0n1p3"; # hibernate
  };
}
