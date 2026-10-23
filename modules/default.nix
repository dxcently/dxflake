# modules/default.nix — the registry.
#
# A function of one optional argument, `packages`: the package paths, defaulting
# to dendrites/packages.nix (a test passes its own list). It returns the registry,
# plain data read by the constructor before any module graph exists: one catalogue
# line per capability, the generated package entries, and the aggregations
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
{
  packages ? import ./dendrites/packages.nix,
}:
let
  file = toString ./dendrites/packages.nix;

  # `kdePackages.filelight` is catalogue entry `filelight`.
  nameOf = path: baseNameOf (builtins.replaceStrings [ "." ] [ "/" ] path);
  count = x: list: builtins.length (builtins.filter (y: y == x) list);
  unique = list: builtins.foldl' (acc: x: if builtins.elem x acc then acc else acc ++ [ x ]) [ ] list;

  paths = unique packages;
  names = unique (map nameOf paths);

  clashing = builtins.filter (n: builtins.hasAttr n handWritten) names;
  listedTwice = builtins.filter (p: count p packages > 1) paths;
  sharing = builtins.filter (n: count n (map nameOf paths) > 1) names;

  entry = path: {
    _file = "${file}#${nameOf path}";
    imports = [
      (
        { pkgs, lib, ... }:
        {
          environment.systemPackages = lib.mkOrder 1400 [
            (lib.getAttrFromPath (lib.splitString "." path) pkgs)
          ];
        }
      )
    ];
  };

  generated = builtins.listToAttrs (
    map (path: {
      name = nameOf path;
      value = entry path;
    }) paths
  );

  checked =
    if clashing != [ ] then
      throw "${file}: '${builtins.head clashing}' names both a package line and a hand-written catalogue entry; rename one, or make the package a dendrite of its own"
    else if listedTwice != [ ] then
      throw "${file}: '${builtins.head listedTwice}' is listed twice; every package line needs its own path"
    else if sharing != [ ] then
      throw "${file}: ${
        builtins.concatStringsSep " and " (builtins.filter (p: nameOf p == builtins.head sharing) paths)
      } share the catalogue name '${builtins.head sharing}'; every package needs a distinct last segment"
    else
      generated;
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
    guymager = ./dendrites/guymager.nix;
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
    librewolf = ./dendrites/librewolf;
    mcfly = ./dendrites/mcfly.nix;
    melete = ./dendrites/melete.nix;
    mneme = ./dendrites/mneme.nix;
    nas-mounts = ./dendrites/nas-mounts.nix;
    netbird = ./dendrites/netbird.nix;
    neovim = ./dendrites/neovim.nix;
    networking = ./dendrites/networking.nix;
    nh = ./dendrites/nh.nix;
    openai = ./dendrites/openai.nix;
    opencode = ./dendrites/opencode.nix;
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
    wireshark = ./dendrites/wireshark.nix;
    wlogout = ./dendrites/wlogout.nix;
    xserver = ./dendrites/xserver.nix;
    yazi = ./dendrites/yazi.nix;
  };

  # Each line of dendrites/packages.nix is a generated entry, merged beside the
  # hand-written ones; the generator throws on a clash.
  catalogue = handWritten // checked;
in
{
  inherit catalogue;

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
