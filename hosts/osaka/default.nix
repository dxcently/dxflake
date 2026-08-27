{ pkgs, ... }: {
  imports = [ ./hardware.nix ];
  dx.aggregations = {
    desktop = true;
    hyprland = true;
    gaming = true;
  };
  dx.claude-code.enable = true;
  dx.pi-coding-agent.enable = true;
  dx.kimi-cli.enable = true;
  dx.syncthing.enable = true;
  dx.virtualisation.enable = true;
  dx.openrazer.enable = true;
  dx.gpu-amd.enable = true;
  dx.gpu-screen-recorder.enable = true;
  dx.k3b.enable = true;
  # consolidated to sakaki-only, 2026-07-31
  dx.melete.enable = false;
  # Core Aoide only (modules/dendrites/aoide.nix: binaries + aoided + the
  # A2A door + the secrets broker), joining the yomi-strix/sakaki/chiyo
  # federation mesh. No facets: the dx desktop keeps painting; with the
  # quickshell facet off, aoided anchors to default.target and the door
  # rides it (loopback :8710, tunnel to reach).
  dx.aoide.enable = true;
  dx.nas-mounts = {
    enable = true;
    mounts."/mnt/kaori-media".export = "/volume1/media";
  };
  environment.systemPackages = with pkgs; [
    soundconverter
    udiskie
    filezilla
    kdePackages.filelight
    tor-browser
    stremio-linux-shell
  ];
  boot = {
    initrd.kernelModules = [ "nvme" ];
    kernelParams = [ "mitigations=off" ];
  };
}
