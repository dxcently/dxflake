{ pkgs, ... }: {
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

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
  # freshest amdgpu. gttsize/ttm let the iGPU borrow a large slice of the unified
  # memory pool so big models fit in "VRAM". THIS UNIT HAS 32 GB RAM, so the GPU
  # gets up to 24 GiB and ~8 GiB is left for CPU/OS. (Both values must stay below
  # physical RAM; scale them up if this box is ever swapped for a 64/128 GB one.)
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.kernelModules = [ "nvme" ];
    kernelParams = [
      "amdgpu.gttsize=24576" # MiB (24 GiB) of system RAM the GPU may map
      "ttm.pages_limit=6291456" # 24 GiB in 4 KiB pages, matches gttsize
    ];
  };

  # 32 GB is modest for loading models while the iGPU also eats RAM — zram gives
  # a compressed in-RAM swap cushion (no disk partition, no hibernate baggage).
  zramSwap.enable = true;
}
