{pkgs, ...}: {
  imports = [./hardware.nix];
  dx.aggregations = { desktop = true; hyprland = true; gaming = true; server = true; };
  dx.virtualisation.enable = true;
  dx.openrazer.enable = true;
  dx.gpu-amd.enable = true;
  dx.gpu-screen-recorder.enable = true;
  dx.k3b.enable = true;
  environment.systemPackages = with pkgs; [ soundconverter udiskie filezilla kdePackages.filelight tor-browser ];
  boot = { initrd.kernelModules = ["nvme"]; kernelParams = ["mitigations=off"]; };
}
