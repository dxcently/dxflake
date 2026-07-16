# Kernel/firmware baseline for yomi-strix. disko.nix owns the disk layout and
# generates all fileSystems.* entries, so none live here.
# This generic module set boots a Strix Halo fine via nixos-anywhere; after
# install you can refine it with the real scan:
#     nixos-generate-config --show-hardware-config
# (or let nixos-anywhere's --generate-hardware-config write it back).
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
