{ pkgs, ... }: {
  imports = [ ./hardware.nix ];

  # Desktop workstation. Dev tooling comes free from the nucleus (git, neovim,
  # lazygit, claude-code, jupyter, …); the desktop/hyprland roles bring the GUI.
  dx.aggregations = {
    desktop = true;
    hyprland = true;
  };

  dx.bluetooth.enable = true;
  dx.gpu-amd.enable = true; # Strix Halo RDNA 3.5 iGPU
  dx.inference.enable = true; # Ollama + Open-WebUI + llama.cpp (ROCm)

  # Strix Halo (Ryzen AI Max) is new silicon — ride the latest kernel for the
  # freshest amdgpu. gttsize/ttm bump lets the iGPU borrow a large slice of the
  # unified memory pool so big models fit in "VRAM".
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.kernelModules = [ "nvme" ];
    kernelParams = [
      "amdgpu.gttsize=65536" # MiB of system RAM the GPU may map (tune to installed RAM)
      "ttm.pages_limit=16777216"
    ];
  };
}
