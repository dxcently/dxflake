{
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [./hardware.nix];
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
  # Core Aoide (modules/dendrites/aoide.nix: binaries + aoided + the A2A
  # door + the secrets broker), joining the yomi-strix/sakaki/chiyo
  # federation mesh.
  dx.aoide.enable = true;
  # The pairing popup (Aoide task #135). Raises the typed-code dialog the
  # moment an inbound pairing request parks, instead of it waiting in a
  # terminal for someone to go looking. The unit's gate is
  # `a2a.enable && pairingPopup` — a graphical session and a dialog binary,
  # not Aoide's shell — so it fires here on the zenity path regardless of
  # the quickshell facet below.
  aoide.a2a = {
    spawnAgent = "claude";
    spawnPath = [pkgs.claude-code];
    discoveryAdvertise = true;
    pairingPopup = true;
  };

  # ── Aoide's face, laid over dxflake's own paint ───────────────────────────
  # osaka takes ONE facet, not chiyo's three. The Quickshell facet is the
  # visible surface — bar, dock, launcher, OSD, wallpaper, notification
  # herald — and it is the only facet that composes with dxflake's own
  # Hyprland + Stylix dendrites: it needs nothing but graphical-session.target
  # and a compositor that exports WAYLAND_DISPLAY/HYPRLAND_INSTANCE_SIGNATURE,
  # which dx.aggregations.hyprland already provides.
  #
  # The other two facets stay OFF here and that is load-bearing, not a
  # preference: `aoide.facets.compositor` and `aoide.facets.stylix` write the
  # same unique-merge leaves as dxflake's Hyprland/Stylix dendrites
  # (`wayland.windowManager.hyprland.systemd.variables`, `stylix.base16Scheme`),
  # and because those merge rather than conflict, nix eval stays green while
  # the session breaks at runtime — see modules/dendrites/aoide.nix's header
  # for the full reasoning. chiyo can run all three only because it turned
  # dxflake's paint off entirely (dx.aggregations.hyprland = false,
  # dx.stylix.enable = false). osaka does not, so it takes one.
  #
  # ── Reverting to the plain flake rice ────────────────────────────────────
  # Flip `aoide.facets.quickshell.enable` back to false (and with it lyra and
  # dunst below, which have no purpose without the surface). That single flag
  # is what the waybar/awww/rofi stand-down in modules/dendrites/hyprland/
  # default.nix keys on, so waybar, both awww wallpapers and SUPER+SPACE→rofi
  # all come back exactly as they were, and aoided drops back to anchoring on
  # default.target instead of graphical-session.target. Nothing else to undo.
  #
  # Consequence of that anchoring worth knowing: with the facet ON, aoided and
  # the A2A door become `partOf` graphical-session.target — the door lives and
  # dies with the desktop session rather than with the boot.
  # The song carries the livery (palette + component tiers) and nothing else —
  # host-agnostic by contract, so this one line is the whole rice swap. Its own
  # rice.nix self-gates on `aoide.song == "nocturne"`; every other song in the
  # songbook stays inert. Back to the shipped standard by naming "sonata".
  aoide.song = "nocturne";

  # ── Cover art: the venue's own ground ────────────────────────────────────
  # Both nocturne and sonata leave the cover note null on purpose ("no cover"
  # → the facet paints a deterministic solid from palette.bg), and with
  # dxflake's awww calls now stood down there is nothing else drawing a
  # desktop image — that is why the wallpaper read as broken rather than as a
  # chosen flat ground. This bakes osaka's own image as an immutable store
  # path, which is the seam that SURVIVES a rebuild: the live alternative,
  # song/stage/cover.json, is runtime state nothing re-seeds (AoideWallpaper.
  # qml's own header names "background gone after rebuild" as the bug the
  # baked path exists to fix).
  #
  # mkForce is load-bearing and it has a cost. sonata assigns this option
  # null at normal priority, so a plain assignment here would collide the
  # moment `aoide.song` goes back to "sonata" — mkForce keeps the song switch
  # working in BOTH directions. What it buys with that: a future song that
  # carries real cover art of its own will have it overridden on osaka.
  # Delete this line to hand the cover note back to whatever song is playing.
  aoide.livery.wallpaper = lib.mkForce ../../assets/wallpapers/hero.webp;

  # ── The wallpaper picker's library ───────────────────────────────────────
  # SUPER+W summons AoideWallpaperPicker, which enumerates its grid by shelling
  # `ls -1 $AOIDE_ROOT/song/covers` and, on a pick, stages the chosen path into
  # song/stage/cover.json — which AoideWallpaper watches and hot-swaps to. But
  # nothing in Aoide ever CREATES that directory (the quickshell facet deploys
  # only run/qml/), so on osaka it did not exist and the picker opened onto an
  # empty grid. Pointing it at dxflake's own wallpaper collection makes the
  # switcher useful immediately, and keeps the venue's images in the venue.
  #
  # The baked cover above stays the DEFAULT ground that survives a rebuild;
  # this is the live override seam on top of it. Path tracks `aoide.root`'s
  # default of ~/.aoide — retarget both together if that option ever moves.
  home-manager.users.${username}.home.file.".aoide/song/covers".source = ../../assets/wallpapers;
  aoide.facets.quickshell.enable = true;
  # Installs the `lyra` binary and enables shellbridge (nucleus/shellbridge.nix
  # is gated on lyra AND the facet). Defaults to following the facet; named
  # explicitly the way chiyo and yomi-strix name it.
  aoide.lyra.enable = true;
  # The notification DAEMON behind the herald surface. dxflake ships the dunst
  # PACKAGE in the hyprland dendrite but never starts a service, so there is no
  # second daemon to collide with — this is what actually puts
  # org.freedesktop.Notifications on the bus here. Every rule is skip_display;
  # dunst feeds `lyra herald push` and Quickshell draws.
  aoide.dunst.enable = true;
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
    initrd.kernelModules = ["nvme"];
    kernelParams = ["mitigations=off"];
  };
}
