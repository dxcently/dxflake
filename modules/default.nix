# modules/default.nix — the registry.
#
# This is NOT a module. It is plain data, read by the constructor before any
# module graph exists: one catalogue line per capability, plus the aggregations
# discovered beside it. Nothing walks the dendrite tree — a capability exists
# here or it cannot be selected, and a name with no line is unreachable, which
# is what shelving means now.
#
# A dendrite with one implementation is one file at the dendrite root: a plain
# module whose `habit.home` is its home half. A dendrite with several is a
# directory whose default.nix lists provider paths and imports none of them. A
# directory is otherwise reserved for a capability that needs more than one file
# (fastfetch and its logo), or for one provider's own folder: a
# compositor-specific dendrite lives in its provider's folder under compositor/
# — beside the provider entry it is written against — and the catalogue still
# names each one. There is no grouping exception at the root any more. Grouping
# is the aggregations' job, so the root stays flat and the catalogue name is the
# file name.
let
  # The hand-written catalogue. The package entries are generated beside it:
  # see packages-entries.nix and modules/dendrites/packages.nix.
  handWritten = {
    aagl = ./dendrites/aagl.nix;
    aoide = ./dendrites/aoide.nix;
    autologin = ./dendrites/autologin.nix;
    autopsy = ./dendrites/autopsy.nix;
    avahi = ./dendrites/avahi.nix;
    bash = ./dendrites/bash.nix;
    bluetooth = ./dendrites/bluetooth.nix;
    bonsai = ./dendrites/bonsai.nix;
    boot = ./dendrites/boot.nix;
    btop = ./dendrites/btop.nix;
    caddy = ./dendrites/caddy.nix;
    cheatsheet = ./dendrites/cheatsheet;
    claude-code = ./dendrites/claude-code.nix;
    claude-desktop = ./dendrites/claude-desktop.nix;
    cloudflared = ./dendrites/cloudflared.nix;
    composekey = ./dendrites/composekey.nix;
    compositor = ./dendrites/compositor;
    desktop-hardware = ./dendrites/desktop-hardware.nix;
    direnv = ./dendrites/direnv.nix;
    displaymanager = ./dendrites/displaymanager.nix;
    fastfetch = ./dendrites/fastfetch;
    ffmpeg = ./dendrites/ffmpeg.nix;
    fcitx5 = ./dendrites/fcitx5.nix;
    flatpak = ./dendrites/flatpak.nix;
    foliate = ./dendrites/foliate.nix;
    fonts = ./dendrites/fonts.nix;
    eidolon = ./dendrites/eidolon.nix;
    git = ./dendrites/git.nix;
    gpu = ./dendrites/gpu;
    gpu-screen-recorder = ./dendrites/gpu-screen-recorder.nix;
    gtk = ./dendrites/gtk.nix;
    hyprglass = ./dendrites/compositor/hyprland/hyprglass.nix;
    hyprland-autostart = ./dendrites/compositor/hyprland/autostart.nix;
    hyprland-decoration = ./dendrites/compositor/hyprland/decoration.nix;
    hyprland-keybinds = ./dendrites/compositor/hyprland/keybinds.nix;
    hyprlock = ./dendrites/hyprlock.nix;
    immich = ./dendrites/immich.nix;
    inference = ./dendrites/inference.nix;
    jellyfin = ./dendrites/jellyfin.nix;
    k3b = ./dendrites/k3b.nix;
    kimi-cli = ./dendrites/kimi-cli.nix;
    kitty = ./dendrites/kitty.nix;
    laptop = ./dendrites/laptop.nix;
    mcfly = ./dendrites/mcfly.nix;
    melete = ./dendrites/melete.nix;
    mneme = ./dendrites/mneme.nix;
    nas-mounts = ./dendrites/nas-mounts.nix;
    neovim = ./dendrites/neovim.nix;
    networking = ./dendrites/networking.nix;
    nh = ./dendrites/nh.nix;
    openai = ./dendrites/openai.nix;
    openrazer = ./dendrites/openrazer.nix;
    openssh = ./dendrites/openssh.nix;
    pi-coding-agent = ./dendrites/pi-coding-agent.nix;
    pipewire = ./dendrites/pipewire.nix;
    portmaster = ./dendrites/portmaster.nix;
    postgresql = ./dendrites/postgresql.nix;
    printing = ./dendrites/printing.nix;
    python = ./dendrites/python.nix;
    qt = ./dendrites/qt.nix;
    rice = ../song/songbook;
    rofi = ./dendrites/rofi.nix;
    ros = ./dendrites/ros.nix;
    satty = ./dendrites/satty.nix;
    security = ./dendrites/security.nix;
    slskd = ./dendrites/slskd.nix;
    snowglobe = ./dendrites/snowglobe.nix;
    sops = ./dendrites/sops.nix;
    starship = ./dendrites/starship.nix;
    steam = ./dendrites/steam.nix;
    stylix = ./dendrites/stylix.nix;
    syncthing = ./dendrites/syncthing.nix;
    system = ./dendrites/system.nix;
    tailscale = ./dendrites/tailscale.nix;
    thunar = ./dendrites/thunar.nix;
    transmission = ./dendrites/transmission.nix;
    vesktop = ./dendrites/vesktop.nix;
    virtmanager = ./dendrites/virtmanager.nix;
    virtualisation = ./dendrites/virtualisation.nix;
    waybar = ./dendrites/waybar.nix;
    wlogout = ./dendrites/wlogout.nix;
    xserver = ./dendrites/xserver.nix;
    yazi = ./dendrites/yazi.nix;
  };
in
{
  # Each line of dendrites/packages.nix is a generated entry, merged beside the
  # hand-written ones; the generator throws on a clash.
  catalogue = import ./packages-entries.nix {
    inherit handWritten;
    packages = import ./dendrites/packages.nix;
    file = toString ./dendrites/packages.nix;
  };

  # The override records, discovered beside the aggregations: capability-scoped
  # fixes, matched against what a host resolved. Names and paths only here; the
  # constructor imports each record to read its targets. See
  # modules/overrides/default.nix.
  overrides = import ./overrides;

  # The aggregations, discovered one level deep. Names and paths only: no body
  # is imported here, and the constructor imports only the ones this host or one
  # of its users selected. See modules/aggregations/default.nix.
  aggregations = import ./aggregations;
}
