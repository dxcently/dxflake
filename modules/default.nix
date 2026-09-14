# modules/default.nix — the catalogue and the selection schema.
#
# This is NOT a NixOS module. It is evaluated in the constructor's first pass,
# by ordinary lib.evalModules, before any platform module graph exists. It
# names one path per capability and declares the enable/provider options those
# names generate; there is no registry file beside it and nothing walks the
# directory. A capability exists here or it cannot be selected, and a name with
# no line is unreachable — which is what shelving means now.
#
# A dendrite with one implementation is one file exposing the lanes it
# supports. A dendrite with several is a directory whose default.nix lists
# provider paths and imports none of them.
{ lib, ... }:
let
  composition = import ../lib/composition.nix { inherit lib; };

  catalogue = {
    aagl = ./dendrites/gaming/aagl.nix;
    aoide = ./dendrites/aoide.nix;
    autologin = ./dendrites/autologin.nix;
    autopsy = ./dendrites/autopsy.nix;
    bash = ./dendrites/bash.nix;
    bluetooth = ./dendrites/bluetooth.nix;
    btop = ./dendrites/btop.nix;
    caddy = ./dendrites/caddy.nix;
    claude-code = ./dendrites/claude-code.nix;
    cloudflared = ./dendrites/cloudflared.nix;
    composekey = ./dendrites/desktop/composekey.nix;
    desktop-hardware = ./dendrites/desktop/hardware.nix;
    desktop-packages = ./dendrites/desktop/packages.nix;
    direnv = ./dendrites/direnv.nix;
    displaymanager = ./dendrites/desktop/displaymanager.nix;
    fastfetch = ./dendrites/desktop/fastfetch;
    fcitx5 = ./dendrites/desktop/fcitx5.nix;
    flatpak = ./dendrites/desktop/flatpak.nix;
    floorp = ./dendrites/desktop/floorp.nix;
    foliate = ./dendrites/desktop/foliate.nix;
    fonts = ./dendrites/desktop/fonts.nix;
    gaming-packages = ./dendrites/gaming/packages.nix;
    git = ./dendrites/git.nix;
    gpu = ./dendrites/gpu;
    gpu-screen-recorder = ./dendrites/gpu-screen-recorder.nix;
    gtk = ./dendrites/desktop/gtk.nix;
    hyprland = ./dendrites/hyprland/compositor.nix;
    hyprland-packages = ./dendrites/hyprland/packages.nix;
    hyprlock = ./dendrites/hyprlock.nix;
    immich = ./dendrites/immich.nix;
    inference = ./dendrites/inference.nix;
    jellyfin = ./dendrites/server/jellyfin.nix;
    k3b = ./dendrites/k3b.nix;
    kimi-cli = ./dendrites/kimi-cli.nix;
    kitty = ./dendrites/desktop/kitty.nix;
    laptop = ./dendrites/laptop.nix;
    mcfly = ./dendrites/mcfly.nix;
    melete = ./dendrites/melete.nix;
    mneme = ./dendrites/mneme.nix;
    nas-mounts = ./dendrites/nas-mounts.nix;
    neovim = ./dendrites/neovim.nix;
    nh = ./dendrites/nh.nix;
    openai = ./dendrites/openai.nix;
    openrazer = ./dendrites/openrazer.nix;
    pi-coding-agent = ./dendrites/pi-coding-agent.nix;
    pipewire = ./dendrites/desktop/pipewire.nix;
    portmaster = ./dendrites/portmaster.nix;
    printing = ./dendrites/desktop/printing.nix;
    qt = ./dendrites/desktop/qt.nix;
    rofi = ./dendrites/hyprland/rofi.nix;
    satty = ./dendrites/hyprland/satty.nix;
    slskd = ./dendrites/slskd.nix;
    starship = ./dendrites/starship.nix;
    steam = ./dendrites/gaming/steam.nix;
    stylix = ./dendrites/stylix.nix;
    syncthing = ./dendrites/syncthing.nix;
    thunar = ./dendrites/desktop/thunar.nix;
    transmission = ./dendrites/transmission.nix;
    vesktop = ./dendrites/desktop/vesktop.nix;
    virtmanager = ./dendrites/desktop/virtmanager.nix;
    virtualisation = ./dendrites/virtualisation.nix;
    waybar = ./dendrites/hyprland/waybar.nix;
    wlogout = ./dendrites/hyprland/wlogout.nix;
    xserver = ./dendrites/desktop/xserver.nix;
    yazi = ./dendrites/yazi.nix;
  };

  # The group declarations. One import, evaluated in BOTH selection scopes —
  # the host scope and every user's — because a group owns both halves of its
  # membership. Each group tells the two apart by the `scope` argument the
  # constructor supplies. See modules/dendrites/default.nix.
  groups = ./dendrites;
in
{
  imports = [
    (composition.mkSchema {
      inherit catalogue;
      userModules = [ groups ];
    })
    groups
  ];
}
