{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  # Desktop workstation. Dev tooling comes free from the nucleus (git, neovim,
  # lazygit, jupyter, …); the desktop/hyprland roles used to bring the GUI —
  # Aoide owns the desktop now (aoide.* flags land in P3).
  dx.bluetooth.enable = true;
  dx.claude-code.enable = true;
  dx.kimi-cli.enable = true;
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

  # Aoide flags for this box — the whole desktop, one line each, mirroring
  # Aoide's own hosts/yomi-strix/default.nix. Deliberately NOT set:
  # aoide.claude-code / kimi-code / pi-coding-agent (dx.* above owns those —
  # one provider per tool); aoide.bash/git/starship/mcfly/yazi/neovim/btop/
  # nh/cli/devtools/fastfetch (dxflake's ungated keep layer owns them);
  # aoide.mcp (house policy).
  aoide.enable = true;
  aoide.user = "khoa";
  aoide.song = "sonata";
  aoide.facets.quickshell.enable = true;
  aoide.facets.compositor.enable = true;
  aoide.facets.stylix.enable = true;
  aoide.hyprland.enable = true;
  aoide.screenshot.enable = true;
  aoide.vision.enable = true;
  aoide.clipboard.enable = true;
  aoide.dunst.enable = true;
  aoide.audio.enable = true;
  aoide.networkmanager.enable = true;
  aoide.obsidian.enable = true;
  aoide.firefox.enable = true;
  # hosts/common (the mkDefault baseline) is NOT walked by dxflake — these two
  # are implicit on an Aoide-native box and must be explicit here.
  aoide.kitty.enable = true; # SUPER+RETURN target
  aoide.fonts.enable = true; # dxflake fonts.nix was desktop-gated

  # dxflake's ungated neovim dendrite pins its own nvf theme; with the desktop
  # role off, dxflake's stylix.nix (which disabled this target) is gone, so
  # Stylix would fight it over programs.nvf.settings.vim.theme.name.
  home-manager.users.${username}.stylix.targets.nvf.enable = false;
}
