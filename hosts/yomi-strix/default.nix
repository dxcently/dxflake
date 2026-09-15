# yomi-strix — Strix Halo desktop. It drives its own Aoide from a separate
# flake at ~/Aoide, so it selects no aoide dendrite here.
{
  aggregation = {
    base.enable = true;
    # Dev tooling comes free from base and the nucleus (git, neovim, …);
    # desktop and shell bring the GUI.
    desktop.enable = true;
    shell = {
      enable = true;
      compositor.provider = "hyprland";
    };
  };

  dendrites = {
    bluetooth.enable = true;
    claude-code.enable = true;
    eidolon.enable = true;
    gpu = {
      enable = true;
      provider = "amd";
    };
    hyprlock.enable = true;
    inference.enable = true;
    kimi-cli.enable = true;
    # Codex + the ChatGPT desktop, dxflake's own dendrite rather than
    # `aoide.openai.enable` — this host sets no upstream Aoide flag at all now.
    openai.enable = true;
  };

  users.khoa = {
    definition = ../../users/khoa.nix;
    homeManager.enable = true;
    # The person, not the machine: these groups contribute home lanes.
    aggregation = {
      base.enable = true;
      desktop.enable = true;
      # The Hyprland-only half of the desktop (keybinds, decoration, autostart,
      # hyprglass). Separate from `shell` so a host on another compositor never
      # evaluates it — see modules/aggregations/compositor/default.nix.
      compositor.enable = true;
      shell.enable = true;
    };
  };

  nixos =
    { pkgs, ... }:
    {
      imports = [
        ./hardware.nix
        ./disko.nix
      ];

      dx.stylix.enable = true;
      dx.inference.igpu = true; # Strix Halo — unified memory, not a discrete card

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
    };
}
