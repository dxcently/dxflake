# osaka — the workstation. Selection first, then this host's own platform
# settings; the shared user is attached, not copied.
{
  aggregation = {
    base.enable = true;
    desktop.enable = true;
    gaming.enable = true;
    shell = {
      enable = true;
      compositor.provider = "hyprland";
    };
  };

  dendrites = {
    aoide.enable = true;
    autopsy.enable = true;
    claude-code.enable = true;
    eidolon.enable = true;
    # Radeon. The intel provider is never imported on this box.
    gpu = {
      enable = true;
      provider = "amd";
    };
    gpu-screen-recorder.enable = true;
    hyprlock.enable = true;
    inference.enable = true;
    k3b.enable = true;
    kimi-cli.enable = true;
    nas-mounts.enable = true;
    # Codex + the ChatGPT desktop, from dxflake's own dendrite. This replaces
    # `aoide.openai.enable`, which made installing two applications depend on
    # an Aoide option surface.
    openai.enable = true;
    openrazer.enable = true;
    syncthing.enable = true;
    virtualisation.enable = true;
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
    dendrites.pi-coding-agent.enable = true;
  };

  nixos =
    {
      pkgs,
      lib,
      username,
      ...
    }:
    {
      imports = [ ./hardware.nix ];
      dx.stylix.enable = true;
      # The pairing popup (Aoide task #135). Raises the typed-code dialog the
      # moment an inbound pairing request parks, instead of it waiting in a
      # terminal for someone to go looking. The unit's gate is
      # `a2a.enable && pairingPopup` — a graphical session and a dialog binary,
      # not Aoide's shell — so it fires here on the zenity path regardless of
      # the quickshell facet below.
      aoide.a2a = {
        spawnAgent = "claude";
        spawnPath = [ pkgs.claude-code ];
        discoveryAdvertise = true;
        pairingPopup = true;
      };

      # ── Aoide's face, laid over dxflake's own paint ───────────────────────────
      # osaka takes ONE facet, not chiyo's three. The Quickshell facet is the
      # visible surface — bar, dock, launcher, OSD, wallpaper, notification
      # herald — and it is the only facet that composes with dxflake's own
      # Hyprland + Stylix dendrites: it needs nothing but graphical-session.target
      # and a compositor that exports WAYLAND_DISPLAY/HYPRLAND_INSTANCE_SIGNATURE,
      # which the compositor dendrite already provides.
      #
      # The compositor facet stays OFF so dxflake's Hyprland behavior stays intact.
      # Stylix ownership is delegated to the AOIDE stylix facet so colors follow
      # livery while dx.stylix keeps fonts/cursors/icons and non-style targets.
      # This is load-bearing for Osaka specifically: chiyo does not select the shell aggregation
      # (`dx.stylix.enable = false`) and can run all AOIDE facets because it no
      # longer overlaps this side of the theme stack.
      #
      # ── Reverting to the plain flake rice ────────────────────────────────────
      # Flip `aoide.facets.quickshell.enable` back to false (and with it lyra and
      # dunst below, which have no purpose without the surface). That single flag
      # is what the waybar/awww/rofi stand-down in
      # modules/dendrites/compositor/hyprland/ keys on, so waybar, both awww
      # wallpapers and SUPER+SPACE→rofi
      # all come back exactly as they were, and aoided drops back to anchoring on
      # default.target instead of graphical-session.target. Nothing else to undo.
      #
      # Consequence of that anchoring worth knowing: with the facet ON, aoided and
      # the A2A door become `partOf` graphical-session.target — the door lives and
      # dies with the desktop session rather than with the boot.
      # The song carries the livery (palette + component tiers) and nothing else —
      # host-agnostic by contract, so this one line is the whole rice swap. Its own
      # rice.nix self-gates on `aoide.song == "sonata"`; every other song in the
      # songbook stays inert. Osaka keeps the shipped standard explicit by naming
      # "sonata" here.
      aoide.song = "sonata";

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
      aoide.livery.wallpaper = lib.mkForce ../../song/covers/hero.webp;

      # Rosé Pine (song/songbook/transience/palette.nix) over sonata, host-scoped: the
      # song itself is shared with yomi-strix, so the override tier, not livery.json.
      aoide.livery.override = {
        bg = "#191724";
        fg = "#e0def4";
        accent = "#ebbcba";
        urgent = "#eb6f92";
        hot = "#31748f";
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
          base0F = "#524f67";
        };
        window.borderInactive = "#9ccfd8";
      };
      stylix.polarity = "dark";

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
      home-manager.users.${username}.home.file.".aoide/song/covers".source = ../../song/covers;
      aoide.facets.quickshell.enable = true;
      aoide.facets.stylix.enable = true;
      # Installs the `lyra` binary and enables shellbridge (nucleus/shellbridge.nix
      # is gated on lyra AND the facet). Defaults to following the facet; named
      # explicitly the way chiyo and yomi-strix name it.
      aoide.lyra.enable = true;
      # The notification DAEMON behind the herald surface. dxflake ships the dunst
      # PACKAGE from the shell aggregation but never starts a service, so there is
      # no second daemon to collide with — this is what actually puts
      # org.freedesktop.Notifications on the bus here. Every rule is skip_display;
      # dunst feeds `lyra herald push` and Quickshell draws.
      aoide.dunst.enable = true;
      dx.nas-mounts.mounts."/mnt/kaori-media".export = "/volume1/media";
      # Two upstream test suites that do not survive this nixpkgs pin. Osaka is
      # the only consumer of either package, so the overlay lives here rather
      # than the nucleus (moved from modules/nucleus/packages.nix).
      #
      # soundconverter 4.0.6 breaks under Python 3.14 (tests/test.py does
      # args[1:] on a None argv); skip the install-check.
      #
      # udiskie 2.7.0 fails TestPasswordCache::test_is_valid in the sandbox —
      # it reads the kernel keyring and gets a payload whose length is not a
      # multiple of 4 ("bytes length not a multiple of item size"). The rest of
      # the suite passes; skip the one test rather than all checking.
      nixpkgs.overlays = [
        (final: prev: {
          soundconverter = prev.soundconverter.overrideAttrs (_: {
            doInstallCheck = false;
          });
          udiskie = prev.udiskie.overridePythonAttrs (old: {
            disabledTests = (old.disabledTests or [ ]) ++ [ "test_is_valid" ];
          });
        })
      ];
      environment.systemPackages = with pkgs; [
        soundconverter
        udiskie
        filezilla
        kdePackages.filelight
        tor-browser
        stremio-linux-shell
      ];
      boot = {
        initrd.kernelModules = [ "nvme" ];
        kernelParams = [ "mitigations=off" ];
      };
    };
}
