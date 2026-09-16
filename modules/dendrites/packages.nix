# modules/dendrites/packages.nix — the flat list of packages that need no
# configuration, one line each, every line a switch of its own.
#
# NOT a dendrite: there is no lane attrset here and no catalogue line, because
# nothing about this file is selectable as a whole. It is one ordinary NixOS
# module, imported unconditionally by the nucleus, that declares
# `dx.packages.<name>.enable` for every line below — all of them off — and
# installs the ones something switched on. An aggregation switches its own
# membership on by name; a host adds one with a single line.
#
# `mkOrder 1400` pins where these land in system.path: after the nucleus floor
# (a plain definition, order 1000) and before an aggregation that still says its
# own list inline (`mkAfter`, 1500). Collisions there resolve first-wins, so a
# shared convenience package never shadows the floor, and an aggregation's
# deliberate inline list still outranks this one.
{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  # One line per package. Order is the order they land in system.path.
  packages = [
    # ── shell ── the Wayland tool belt (aggregation `shell`)
    pkgs.dunst # lightweight notification daemon
    pkgs.awww # animated wallpaper daemon for Wayland
    pkgs.wl-clipboard # copy/paste CLI for Wayland
    pkgs.satty # Wayland screenshot annotation tool (swappy successor)
    pkgs.cliphist # clipboard history manager for Wayland
    pkgs.brightnessctl # control device brightness via sysfs
    pkgs.ydotool # generic input automation
    pkgs.yad # display GTK dialogs from shell scripts
    pkgs.zenity # GNOME-style GTK dialogs from shell scripts

    # ── desktop ── the graphical session's own apps (aggregation `desktop`)
    pkgs.kitty # GPU-accelerated terminal emulator
    pkgs.mission-center # GUI resource monitor with GPU usage
    pkgs.file-roller # GNOME archive manager (Thunar integration)
    pkgs.gparted # graphical partition editor
    pkgs.mpv # scriptable command-line media player
    pkgs.vlc # cross-platform multimedia player
    pkgs.wireplumber # PipeWire session and policy manager
    pkgs.pavucontrol # PulseAudio/PipeWire volume control GUI
    pkgs.strawberry # music player with audio CD and lyrics
    pkgs.playerctl # MPRIS2 media player controller
    pkgs.ffmpegthumbnailer # video thumbnails via libffmpeg
    pkgs.obs-studio # screen recording and live streaming
    pkgs.grim # Wayland screenshot capture (lyra screen shot's backend)
    pkgs.slurp # region picker for grim (lyra screen shot --pick)
    pkgs.losslesscut-bin # lossless video/audio trimmer
    pkgs.scrcpy # display and control Android devices
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.chromium # open source web browser from Google
    pkgs.qbittorrent # open-source BitTorrent client
    pkgs.nicotine-plus # Soulseek peer-to-peer client
    pkgs.zoom-us # video conferencing
    pkgs.obsidian # markdown personal knowledge base
    pkgs.anki-bin # spaced repetition flashcards
    pkgs.pear-desktop # unofficial YouTube Music client
    pkgs.gimp3-with-plugins # GNU Image Manipulation Program
    pkgs.webcamoid # webcam capture with effects
    pkgs.orca-slicer # G-code slicer for 3D printing
  ];

  # The switch is named by the package's own `lib.getName`, not by the
  # attribute it is written with: `pkgs.mpv` is `mpv-with-scripts`, so its
  # switch is `dx.packages.mpv-with-scripts`. Writing the switch any other way
  # would mean a hand-maintained second name for every line.
  nameOf = lib.getName;
  names = map nameOf packages;
  byName = lib.listToAttrs (map (p: lib.nameValuePair (nameOf p) p) packages);

  # `lib.listToAttrs` keeps the LAST of two equal names and says nothing about
  # it, so a duplicate line would silently lose a package and look exactly like
  # one switched off. Refuse it, naming the whole list, rather than drop one.
  distinct = lib.assertMsg (builtins.length packages == builtins.length (lib.attrNames byName)) (
    "modules/dendrites/packages.nix: two entries share a lib.getName, so listToAttrs "
    + "would silently drop one of them; every line needs a distinct name. The list is: "
    + lib.concatStringsSep ", " names
  );
in
{
  options.dx.packages = lib.mapAttrs (n: _: {
    enable = lib.mkEnableOption "install ${n}";
  }) byName;

  # The assert sits inside the value, not at the top of the module: forcing it
  # at the attribute-set level would demand `pkgs` before the module system has
  # settled its arguments, which is an infinite recursion rather than an error.
  config.environment.systemPackages =
    assert distinct;
    lib.mkOrder 1400 (builtins.filter (p: config.dx.packages.${nameOf p}.enable) packages);
}
