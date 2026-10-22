# osaka — the workstation. Selection first, then this host's own platform
# settings; the shared user is attached, not copied.
{
  pkgs,
  lib,
  config,
  username,
  ...
}:
{
  # The rice carries the theme (palette + component tiers) and nothing else —
  # host-agnostic by contract, so this one line is the whole rice swap.
  habit.rice.declared = "barcarolle";
  # Built in, not performed. Each switch refreshes these rices' copies in the
  # runtime rices (`strx rice refresh`: repo changes reach the files the
  # machine never edited); staging one is a row in the bar's RICE menu or
  # `strx rice mode stage <rice>`.
  habit.rice.available = [
    "cadenza"
    "etude"
    "fugue"
    "nocturne"
    "quodlibet"
    "sonata"
  ];

  habit.aggregation = {
    nucleus.enable = true;
    aoide.enable = true;
    network.enable = true;
    desktop.enable = true;
    gaming.enable = true;
    shell = {
      enable = true;
      compositor.provider = "hyprland";
    };
  };

  habit.dendrites = {
    aoide.enable = true;
    stylix.enable = true;
    # Aoide's lanes over dxflake's own paint: the Quickshell surface (bar, dock,
    # launcher, OSD, wallpaper, notifications), the strillix runtime with its
    # shellbridge, the dunst daemon behind the notifications (the shell aggregation ships only the
    # package, so no second daemon), and Aoide's stylix lane for colours
    # (the stylix dendrite keeps fonts, cursors, icons). Aoide's compositor lane stays
    # unselected so dxflake's Hyprland is the only compositor writer.
    quickshell.enable = true;
    strillix.enable = true;
    dunst.enable = true;
    aoide-stylix.enable = true;
    autopsy.enable = true;
    bonsai.enable = true;
    claude-code.enable = true;
    claude-desktop.enable = true;
    eidolon.enable = true;
    # Radeon. The intel provider is never imported on this box.
    gpu = {
      enable = true;
      provider = "amd";
    };
    gpu-screen-recorder.enable = true;
    lock = {
      enable = true;
      provider = "hyprlock";
    };
    inference.enable = true;
    k3b.enable = true;
    kimi-cli.enable = true;
    nas-mounts.enable = true;
    # Codex + the ChatGPT desktop, from dxflake's own dendrite. This replaces
    # `aoide.openai.enable`, which made installing two applications depend on
    # an Aoide option surface.
    openai.enable = true;
    openrazer.enable = true;
    # ROS 2 on the workstation too (chiyo carries the same dendrite): the CLI
    # tools, the ros.cachix.org substituter and the DDS port range, no service.
    ros.enable = true;
    syncthing.enable = true;
    snowglobe.enable = true;
    virtualisation.enable = true;
    postgresql.enable = true;
  };

  habit.users.khoa = {
    definition = ../../users/khoa.nix;
    home.enable = true;
    # The person, not the machine: these groups contribute home halves.
    aggregation = {
      desktop.enable = true;
      # The Hyprland-only half of the desktop (keybinds, decoration, autostart,
      # hyprglass). Separate from `shell` so a host on another compositor never
      # evaluates it — see modules/aggregations/hyprland/default.nix.
      hyprland.enable = true;
      shell.enable = true;
    };
    dendrites.pi-coding-agent.enable = true;
  };

  imports = [ ./hardware.nix ];
  # Build machine for chiyo (its nix.buildMachines). chiyo's nix-daemon
  # signs in with chiyo's own SSH host key, so no new secret exists.
  users.users.nixremote = {
    isSystemUser = true;
    group = "nixremote";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+D5ugzZE3y6ex8tMVNWvGcBruvb619tbNnwyIp/FSJ chiyo"
    ];
  };
  users.groups.nixremote = { };
  nix.settings.trusted-users = [ "nixremote" ];
  # The pairing popup (Aoide task #135). Raises the typed-code dialog the
  # moment an inbound pairing request parks, instead of it waiting in a
  # terminal for someone to go looking. The unit's gate is
  # `a2a.enable && pairingPopup` — a graphical session and a dialog binary,
  # not Aoide's shell — so it fires here on the zenity path regardless of
  # the quickshell lane.
  aoide.a2a = {
    spawnAgent = "claude";
    spawnPath = [ pkgs.claude-code ];
    discoveryAdvertise = true;
    pairingPopup = true;
  };
  # Secrets broker (Aoide workstream #58; the aoide dendrite enables it):
  # own uid behind a socket-only door, TOTP-gated. The operator joins the
  # access group; enrollment is a separate, User-initiated act — never part
  # of the switch.
  aoide.secrets.members = [ "khoa" ];

  # The dev checkout is ~/aoide here; the option's default is ~/Aoide, which
  # does not exist on this box. It becomes AOIDE_FLAKE_ROOT on aoided and the
  # shellbridge, and `strx preview` and `strx rice declare` refuse a missing one.
  aoide.checkout = "/home/${username}/aoide";
  # The file `strx rice declare --host` and the Declare button rewrite.
  strillix.hostConfig = "/home/${username}/dxflake/hosts/osaka/default.nix";

  # ── Aoide's face, laid over dxflake's own paint ───────────────────────────
  # The quickshell lane composes with dxflake's own Hyprland + Stylix
  # dendrites: it needs nothing but graphical-session.target and a compositor
  # that exports WAYLAND_DISPLAY/HYPRLAND_INSTANCE_SIGNATURE, which the
  # compositor dendrite already provides. Colours follow the theme through
  # Aoide's stylix lane while the stylix dendrite keeps fonts/cursors/icons.
  #
  # Deselecting the quickshell lane turns off the waybar/awww/rofi stand-down in
  # modules/dendrites/compositor/hyprland/, which keys on `strillix.quickshell.enable`,
  # so those come back, and aoided anchors on default.target again. It does not
  # give back the bar, launcher and powermenu slots: the declared rice (barcarolle)
  # pins them to strillix, so a revert needs a rice that does not pin them.
  #
  # With the lane on, aoided and the A2A door are `partOf`
  # graphical-session.target — the door lives and dies with the desktop
  # session rather than with the boot.

  # ── Cover art: the venue's own ground ────────────────────────────────────
  # Both nocturne and sonata leave the cover note null on purpose ("no cover"
  # → the lane paints a deterministic solid from palette.bg), and with
  # dxflake's awww calls now stood down there is nothing else drawing a
  # desktop image — that is why the wallpaper read as broken rather than as a
  # chosen flat ground. This bakes osaka's own image as an immutable store
  # path, which is the seam that SURVIVES a rebuild: the live alternative,
  # song/stage/cover.json, is runtime state nothing re-seeds (AoideWallpaper.
  # qml's own header names "background gone after rebuild" as the bug the
  # baked path exists to fix).
  #
  # mkForce is load-bearing: sonata assigns this option null at normal
  # priority, so a plain assignment would collide. Scoped to sonata, so a rice
  # with cover art of its own (barcarolle) keeps it.
  strillix.theme.wallpaper = lib.mkIf (config.strillix.rice == "sonata") (
    lib.mkForce ../../song/covers/hero.webp
  );

  # Rosé Pine (modules/aggregations/shell/transience/palette.nix) over sonata,
  # host-scoped: the rice itself is shared with yomi-strix, so the override tier.
  # Any other rice keeps its own palette.
  strillix.theme.override = lib.mkIf (config.strillix.rice == "sonata") {
    bg = "#191724";
    fg = "#e0def4";
    accent = "#ebbcba";
    urgent = "#eb6f92";
    # Bright enough for status text on the dark background; also recolours base0B.
    hot = "#6eafc7";
    base16 = {
      base01 = "#1f1d2e";
      base02 = "#26233a";
      base03 = "#6e6a86";
      base04 = "#908caa";
      base06 = "#e0def4";
      base07 = "#524f67";
      base09 = "#f6c177";
      base0C = "#9ccfd8";
      base0D = "#c4a7e7";
      base0E = "#f6c177";
      # Workspace 1 and other base0F text need an accent, not a surface shade.
      base0F = "#b6a3cf";
    };
    window.borderInactive = "#9ccfd8";
  };
  # sonata is opaque here. It has no terminalOpacity opinion, and Aoide
  # answers "no opinion" with its own 0.86 on every `rice stage`, so the venue
  # states one. Scoped to sonata: a rice with an opinion of its own (cadenza's
  # 0.7) owns it, and this then defines nothing for it to collide with.
  # Aoide's seed publishes the value as song/declared/terminal-opacity.conf,
  # which covers a box that has never staged. A re-stage of sonata reads the
  # declared twin (song/declared/theme.json), which carries no geometry yet,
  # so it honours this only once Aoide carries geometry into that twin. Until
  # then a re-stage of sonata writes Aoide's 0.86.
  strillix.theme.geometry.terminalOpacity = lib.mkIf (config.strillix.rice == "sonata") 1.0;
  stylix.polarity = "dark";
  # Keep the serif look, with a fixed-width face for terminals and code.
  stylix.fonts = {
    monospace = lib.mkForce {
      package = pkgs.cm_unicode;
      name = "CMU Typewriter Text";
    };
    serif = lib.mkForce {
      package = pkgs.libertine;
      name = "Linux Libertine O";
    };
    sansSerif = lib.mkForce {
      package = pkgs.libertine;
      name = "Linux Libertine O";
    };
  };

  # ── The wallpaper picker's library ───────────────────────────────────────
  # SUPER+W summons AoideWallpaperPicker, which enumerates its grid by shelling
  # `ls -1 $AOIDE_ROOT/song/covers` and, on a pick, stages the chosen path into
  # song/stage/cover.json — which AoideWallpaper watches and hot-swaps to. But
  # nothing in Aoide ever CREATES that directory (the quickshell lane deploys
  # only run/qml/), so on osaka it did not exist and the picker opened onto an
  # empty grid. Pointing it at dxflake's own wallpaper collection makes the
  # switcher useful immediately, and keeps the venue's images in the venue.
  #
  # The baked cover above stays the DEFAULT ground that survives a rebuild;
  # this is the live override seam on top of it. Path tracks `aoide.root`'s
  # default of ~/.aoide — retarget both together if that option ever moves.
  home-manager.users.${username} = {
    home.file.".aoide/song/covers".source = ../../song/covers;
    # SUPER+D sends vesktop to workspace 3 on the vertical HDMI-A-1 panel, which
    # only osaka has.
    wayland.windowManager.hyprland.settings = {
      # osaka runs a sideways-T: the horizontal AOC meets the middle of the rotated
      # Samsung. The Samsung is 1080x1920 after transform 3 and stays anchored at
      # 1920x0, so the AOC (1080 tall) is dropped by (1920-1080)/2 = 420 to center
      # its full right edge inside the tall panel; otherwise only the top ~half of
      # the shared edge is crossable. Panels are pinned by description so geometry
      # survives a DP/HDMI port swap.
      monitor = lib.mkAfter [
        "desc:AOC 24G1WG4 0x000391EC, 1920x1080@144, 0x420, 1"
        "desc:Samsung Electric Company C24F390 HCNN907588, 1920x1080@60, 1920x0, 1, transform, 3"
      ];
      workspace = lib.mkAfter [
        "n, monitor:HDMI-A-1, default:true"
        "special:discord, monitor:HDMI-A-1, on-created-empty:vesktop"
        "2, monitor:HDMI-A-1, persistent:true"
        # Every workspace on the vertical monitor uses the scrolling layout. The
        # rule keys off the HDMI-A-1 connector because m[] selectors cannot hold a
        # spaced description.
        "m[HDMI-A-1], layout:scrolling"
      ];
      bind = [
        "SUPER, D, exec, [workspace 3; monitor hdmi-a-1] vesktop"
      ];
    };
    # ANSI bright black is secondary text (e.g. nom's elapsed-time labels).
    # Override the template's base02 surface shade with muted ink. Ordered
    # after the kitty dendrite's include block, whose staged file carries that
    # same base02 line. That holds for a NEW kitty instance only: a live stage
    # pushes the staged colours to the windows already open and resets slot 8
    # there.
    programs.kitty.extraConfig = lib.mkOrder 1600 ''
      color8 #${config.lib.stylix.colors.base04}
    '';
    # snowglobe on the local disk for now; storage.mode = "partition" plus
    # snowglobe.host.storage.device once the WD partition exists.
    snowglobe = {
      enable = true;
      budget.mem = 40960;
    };
  };
  dx.nas-mounts.mounts."/mnt/kaori-media".export = "/volume1/media";
  # Two upstream package fixes for this nixpkgs pin. Osaka is
  # the only consumer of either package, so the overlay lives here rather
  # than in nucleus.
  #
  # soundconverter 4.0.6 breaks under Python 3.14 (tests/test.py does
  # args[1:] on a None argv); skip the install-check.
  #
  # udiskie 2.7.0 reads binary kernel-keyring payloads through
  # ctypes' NUL-terminated `buffer.value`, which truncates key IDs at an
  # embedded NUL and makes the array parser fail intermittently. Keep the
  # full test suite and return exactly the bytes reported by keyctl.
  nixpkgs.overlays = [
    (final: prev: {
      soundconverter = prev.soundconverter.overrideAttrs (_: {
        doInstallCheck = false;
      });
      udiskie = prev.udiskie.overridePythonAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace udiskie/keyutils.py \
            --replace-fail 'return buffer.value' 'return buffer.raw[:ret]'
        '';
      });
    })
  ];
  # This host's own additions to the shared list. The overlay above fixes
  # two of them; both fixes are host-local, so they stay here.
  habit.dendrites.soundconverter.enable = true;
  habit.dendrites.udiskie.enable = true;
  habit.dendrites.filezilla.enable = true;
  habit.dendrites.filelight.enable = true;
  habit.dendrites.tor-browser.enable = true;
  habit.dendrites.librewolf.enable = true;
  habit.dendrites.stremio-linux-shell.enable = true;
  boot = {
    initrd.kernelModules = [ "nvme" ];
    kernelParams = [ "mitigations=off" ];
  };

  # Pins stateful-data formats from the first install; do not change it.
  system.stateVersion = "23.11";

}
