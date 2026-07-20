{pkgs, ...}: {
  imports = [./hardware.nix];
  dx.aggregations = {
    desktop = true;
    hyprland = true;
    gaming = true;
  };
  dx.syncthing.enable = true;
  dx.virtualisation.enable = true;
  dx.openrazer.enable = true;
  dx.gpu-amd.enable = true;
  dx.gpu-screen-recorder.enable = true;
  dx.k3b.enable = true;
  dx.melete.enable = true;
  dx.nfs-media.enable = true;
  environment.systemPackages = with pkgs; [
    soundconverter
    udiskie
    filezilla
    kdePackages.filelight
    tor-browser
    stremio-linux-shell
  ];
  boot = {
    initrd.kernelModules = ["nvme"];
    kernelParams = ["mitigations=off"];
  };
}
