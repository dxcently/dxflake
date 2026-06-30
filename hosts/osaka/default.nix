{
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ../../modules/nucleus
    ../../modules/dendrites/desktop
    ../../modules/dendrites/hyprland
    ../../modules/dendrites/gaming
    ../../modules/dendrites/server
    ../../modules/dendrites/virtualisation.nix
    ../../modules/dendrites/openrazer.nix
    ../../modules/dendrites/gpu-amd.nix
    ../../modules/dendrites/gpu-screen-recorder.nix
    ../../modules/dendrites/k3b.nix
  ];

  # host-specific packages
  environment.systemPackages = with pkgs; [
    soundconverter
    udiskie
    filezilla
    kdePackages.filelight
    tor-browser
  ];

  boot = {
    initrd.kernelModules = ["nvme"];
    kernelParams = ["mitigations=off"];
  };
}
