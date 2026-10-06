# osaka — the workstation. Selection first, then this host's own platform
# settings; the shared user is attached, not copied.
{
  # The song carries the livery (palette + component tiers) and nothing else —
  # host-agnostic by contract, so this one line is the whole rice swap.
  song.declared = "sonata";

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
    # Aoide's lanes over dxflake's own paint: the Quickshell surface (bar, dock,
    # launcher, OSD, wallpaper, herald), the lyra binary with its shellbridge,
    # the dunst daemon behind the herald (the shell aggregation ships only the
    # package, so no second daemon), and Aoide's stylix lane for colours
    # (dx.stylix keeps fonts, cursors, icons). Aoide's compositor lane stays
    # unselected so dxflake's Hyprland is the only compositor writer.
    quickshell.enable = true;
    lyra.enable = true;
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
    snowglobe.enable = true;
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
      config,
      username,
      ...
    }:
    {
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
      dx.stylix.enable = true;
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

      # ── Aoide's face, laid over dxflake's own paint ───────────────────────────
      # The quickshell lane composes with dxflake's own Hyprland + Stylix
      # dendrites: it needs nothing but graphical-session.target and a compositor
      # that exports WAYLAND_DISPLAY/HYPRLAND_INSTANCE_SIGNATURE, which the
      # compositor dendrite already provides. Colours follow the livery through
      # Aoide's stylix lane while dx.stylix keeps fonts/cursors/icons.
      #
      # Deselecting the quickshell lane (and lyra and dunst, which have no purpose
      # without the surface) is the whole revert: the waybar/awww/rofi stand-down
      # in modules/dendrites/compositor/hyprland/ keys on `aoide.quickshell.enable`,
      # so waybar, both awww wallpapers and SUPER+SPACE→rofi come back, and aoided
      # anchors on default.target again.
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
        # ANSI bright black is secondary text (e.g. nom's elapsed-time labels).
        # Override the template's base02 surface shade with muted ink, after its include.
        programs.kitty.extraConfig = lib.mkAfter ''
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
      # than the nucleus (moved from modules/nucleus/packages.nix).
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
      dx.packages.soundconverter.enable = true;
      dx.packages.udiskie.enable = true;
      dx.packages.filezilla.enable = true;
      dx.packages.filelight.enable = true;
      dx.packages.tor-browser.enable = true;
      dx.packages.stremio-linux-shell.enable = true;
      boot = {
        initrd.kernelModules = [ "nvme" ];
        kernelParams = [ "mitigations=off" ];
      };
    };
}
