{
  username,
  config,
  lib,
  ...
}: let
  # Aoide's Quickshell facet is a SURFACE owner: once it is on it draws the bar,
  # the wallpaper, the launcher, the OSD and the notification herald itself
  # (its `aoide.surfaces` registry claims exactly those). dxflake's own waybar +
  # awww + rofi draw the same three surfaces, so on a host that flips the facet
  # they must stand down or both stacks paint at once — two bars layered, two
  # wallpapers racing the same output.
  #
  # This is the ONLY seam where that stand-down happens, and it is keyed on the
  # facet flag rather than on a host name: `aoide.facets.quickshell.enable =
  # false` (or simply never set, which is the default on every other host)
  # restores waybar/awww/rofi byte-identically — verified by diffing this
  # dendrite's evaluated hyprland.conf across the change with the facet off.
  # That one flag in the host file is the whole toggle back to the flake rice.
  #
  # Read through the OUTER `config`: the home-manager submodule below takes its
  # own `config` argument, which shadows this one.
  #
  # NOTE the deliberately narrow scope — only the three surfaces the facet
  # actually claims move. Clipboard (cliphist/wl-clipboard) and screenshots
  # (hyprshot/satty) stay dxflake's on every host: Aoide ships equivalents
  # behind `aoide.clipboard.enable`/`aoide.screenshot.enable`, but those are
  # NOT enabled beside this dendrite, so their keybinds below are untouched.
  aoideFace = config.aoide.facets.quickshell.enable;
in {
  config = lib.mkIf config.dx.aggregations.hyprland {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    home-manager.users.${username} = {
      pkgs,
      config,
      inputs,
      lib,
      ...
    }: {
      home = {
        packages = with pkgs; [
          hyprpolkitagent
          hyprpicker
          hyprshot
        ];
        sessionVariables.NIXOS_OZONE_WL = "1";
      };

      wayland.windowManager.hyprland = {
        enable = true;
        systemd = {
          enable = true;
          enableXdgAutostart = true;
          variables = ["--all"];
        };
        xwayland.enable = true;

        # ── hyprglass — the gloss on top of the glass ────────────────────────
        # A Hyprland decoration plugin (pkgs/hyprglass in the Aoide input,
        # reaching us through the packages-walker overlay flake.nix installs):
        # refraction, fresnel and adaptive brightness layered OVER Hyprland's
        # own gaussian blur. It only ever paints TRANSLUCENT content, so it is
        # inert on an opaque desktop — which is why it rides `aoideFace` rather
        # than the aggregation: the surfaces it is aimed at (aoide-dock,
        # -launcher, -powermenu) exist only when the Quickshell facet does.
        #
        # ABI: a Hyprland plugin is locked to the compositor commit it was
        # compiled against, and hyprglass's own pin table (hyprpm.toml) vets
        # v0.7.0 against hyprland 0.56.0 — while this flake is on 0.56.2. That
        # gap was CHECKED, not assumed: the plugin builds clean against the
        # 0.56.2 in our nixpkgs, and because the same nixpkgs provides both the
        # plugin's build input and `programs.hyprland.package`, the running
        # compositor and the .so can never drift apart in a rebuild.
        plugins = lib.optionals aoideFace [pkgs.hyprglass];

        settings = {
          # Monitors
          #
          # osaka runs a sideways-T: the horizontal AOC meets the middle of the
          # rotated Samsung. The Samsung is 1080x1920 after transform 3 and stays
          # anchored at 1920x0, so the AOC (1080 tall) is dropped by
          # (1920-1080)/2 = 420 to center its full right edge inside the tall
          # panel — otherwise only the top ~half of the shared edge is crossable.
          # Panels are pinned by description so geometry survives a DP/HDMI port
          # swap. The scrolling rule below still keys off the HDMI-A-1 connector
          # (m[] selectors can't hold a spaced description).
          monitor = [
            ", preferred, auto, 1"
            "eDP-1, 1920x1080@60, auto, 1.25"
            "desc:AOC 24G1WG4 0x000391EC, 1920x1080@144, 0x420, 1"
            "desc:Samsung Electric Company C24F390 HCNN907588, 1920x1080@60, 1920x0, 1, transform, 3"
          ];

          # Environment Variables
          env = [
            "XCURSOR_SIZE, 40"
            "QT_QPA_PLATFORMTHEME, qt5ct"
            "WLR_NO_HARDWARE_CURSORS, 1"
            "HYPRLAND_NO_START_WRAPPERS, 1"
          ];

          # Startup Programs
          #
          # The wallpaper + bar block is spliced in place (not appended) so that
          # with `aoideFace` off the list is character-for-character what it was
          # before the facet seam existed — order included. awww-daemon leaves
          # with its two `img` calls: nothing else drives it, and a daemon with
          # no image to hold is just a process sitting on the Quickshell
          # wallpaper surface's output.
          "exec-once" =
            [
              "systemctl --user start hyprpolkitagent"
              "nm-applet --indicator"
              "systemd"
              "hypridle"
            ]
            ++ lib.optionals (!aoideFace) [
              "awww-daemon"
              "awww img -o DP-1 ~/dxflake/assets/wallpapers/hero.webp"
              "awww img -o HDMI-A-1 ~/dxflake/assets/wallpapers/yuki-standing.png"
              "waybar"
            ]
            ++ [
              "wl-paste --type text --watch cliphist store"
              "wl-paste --type image --watch cliphist store"
              "fcitx5"
              "[workspace 1 silent] zen"
            ];

          extraConfig = "
          windowrule {
            name = windowrule-1
            opacity = 0.8 override 0.8 override
            match:title = ^(FL Studio)$
          }



                # Workspace Assignments

                # Using the preferred 'class' and 'title' matching

          windowrule {
            name = windowrule-2
            workspace = 2
            match:class = ^([Vv]esktop)$
          }


          windowrule {
            name = windowrule-3
            workspace = special:scratch
            match:class = ^([Ss]team)$
          }


          windowrule {
            name = windowrule-4
            workspace = special:magic
            match:class = ^([Ss]trawberry)$
          }


          windowrule {
            name = windowrule-5
            workspace = special:magic
            match:title = ^(YT Music)$
          }


          windowrule {
            name = windowrule-6
            workspace = special:scratch
            match:class = ^([Oo]bsidian)$
          }

          ";
          # Workspace Assignments
          workspace = [
            "n, monitor:HDMI-A-1, default:true"
            "special:discord, monitor:HDMI-A-1, on-created-empty:vesktop"
            "special:scratch, on-created-empty:obsidian"
            "special:magic, on-created-empty:pear-desktop"
            "special:scratch, layout:scrolling"
            "2, monitor:HDMI-A-1, persistent:true"
            "special:replay, on-created-empty:gpu-screen-recorder-gtk"
            # Every workspace on the vertical monitor uses the scrolling layout.
            "m[HDMI-A-1], layout:scrolling"
          ];

          # Keybindings
          #
          # Aoide's summoned surfaces (launcher, dock, wallpaper picker) have no
          # CLI entry point at all — each registers an appid under hyprland-
          # global-shortcuts-v1 from inside the running Quickshell process, so
          # `global, aoide:<name>` is the ONLY way to reach them (the old
          # `aoide shell launcher`/`dock` commands are unimplemented stubs).
          # Without these three binds the facet would draw a bar and nothing the
          # keyboard could summon.
          #
          # SUPER+SPACE is the swap: it is Aoide's own launcher key (see the
          # Aoide hyprland dendrite) and it is rofi's here, so the facet takes
          # it over and hands it straight back when switched off. SUPER+G and
          # SUPER+W are additive — both are unbound in this dendrite otherwise.
          # SUPER+C is NOT swapped to `aoide:clipboard`: that chapter is fed by
          # the facet's own cliphist provider, but dxflake's rofi picker below
          # already works and stays the clipboard seam on these hosts.
          bind =
            [
              "SUPER, RETURN, exec, kitty"
            ]
            ++ (
              if aoideFace
              then [
                "SUPER, SPACE, global, aoide:launcher"
                "SUPER, G, global, aoide:dock"
                "SUPER, W, global, aoide:wallpaper"
              ]
              else ["SUPER, SPACE, exec, rofi -show drun"]
            )
            ++ [
              "SUPER, T, exec, [float] thunar"
              "SUPER, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
              "SUPER, S, exec, pkill hyprpicker; hyprshot -z --raw -m region | satty --filename -"
              "SUPER SHIFT, S, exec, pkill hyprpicker; hyprshot -z --raw -m output | satty --filename -"
              "SUPER, Tab, exec, rofi -show"
              "SUPER, B, exec, bash /home/khoa/dxflake/scripts/keybinds.bash"
              "SUPER, D, exec, [workspace 3; monitor hdmi-a-1] vesktop"
              "SUPER, Q, killactive"
              "SUPER, V, togglefloating"
              "SUPER, F, fullscreen"
              "SUPER, H, movefocus, l"
              "SUPER, J, movefocus, d"
              "SUPER, K, movefocus, u"
              "SUPER, L, movefocus, r"
              "SUPER SHIFT, H, movewindow, l"
              "SUPER SHIFT, J, movewindow, d"
              "SUPER SHIFT, K, movewindow, u"
              "SUPER SHIFT, L, movewindow, r"
              "SUPER ALT, H, resizeactive, -20 0"
              "SUPER ALT, J, resizeactive, 0 40"
              "SUPER ALT, K, resizeactive, 0 -40"
              "SUPER ALT, L, resizeactive, 20 0"
              # Scrolling layout (HDMI-A-1). No-ops on dwindle workspaces.
              "SUPER, p, layoutmsg, promote"
              "SUPER, comma, layoutmsg, fit visible"
              "SUPER, period, layoutmsg, fit active"

              "ALT, Tab, workspace, previous"
              "SUPER, 1, workspace, 1"
              "SUPER, 2, workspace, 2"
              "SUPER, 3, workspace, 3"
              "SUPER, 4, workspace, 4"
              "SUPER, 5, workspace, 5"
              "SUPER, 6, workspace, 6"
              "SUPER, 7, workspace, 7"
              "SUPER, 8, workspace, 8"
              "SUPER, 9, workspace, 9"
              "SUPER, 0, workspace, 10"
              "SUPER SHIFT, 1, movetoworkspace, 1"
              "SUPER SHIFT, 2, movetoworkspace, 2"
              "SUPER SHIFT, 3, movetoworkspace, 3"
              "SUPER SHIFT, 4, movetoworkspace, 4"
              "SUPER SHIFT, 5, movetoworkspace, 5"
              "SUPER SHIFT, 6, movetoworkspace, 6"
              "SUPER SHIFT, 7, movetoworkspace, 7"
              "SUPER SHIFT, 8, movetoworkspace, 8"
              "SUPER SHIFT, 9, movetoworkspace, 9"
              "SUPER SHIFT, 0, movetoworkspace, 10"
              "SUPER, X, togglespecialworkspace, magic"
              "SUPER, Z, togglespecialworkspace, scratch"
              "SUPER, D, togglespecialworkspace, discord"
              "SUPER SHIFT, X, movetoworkspace, special:magic"
              "SUPER SHIFT, Z, movetoworkspace, special:scratch"
              "SUPER SHIFT, D, movetoworkspace, special:discord"
              "SUPER, R, togglespecialworkspace, replay"
              ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 4%-"
              ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 4%+"
              ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
              ", XF86MonBrightnessDown, exec, brightnessctl s 5%-"
              ", XF86MonBrightnessUp, exec, brightnessctl s 5%+"
            ];

          bindm = [
            "SUPER, mouse:272, movewindow"
            "SUPER, mouse:273, resizewindow"
          ];

          input = {
            kb_layout = "us";
            kb_options = "compose:caps";
            follow_mouse = 1;
            sensitivity = 0.8;
            accel_profile = "flat";
            force_no_accel = true;
            touchpad = {
              natural_scroll = true;
              middle_button_emulation = true;
              clickfinger_behavior = true;
            };
          };

          general = {
            gaps_in = 2;
            gaps_out = 4;
            border_size = 1;
            "col.active_border" = lib.mkForce "rgba(ffffff99)";
            "col.inactive_border" = lib.mkForce "rgba(000000cc)";
            layout = "dwindle";
            allow_tearing = true;
          };

          decoration = {
            rounding = 0;
            blur = {
              enabled = true;
              size = 2;
              passes = 2;
              xray = true;
              vibrancy_darkness = 1.0;
              ignore_opacity = true;
              new_optimizations = true;
            };
            shadow = {
              enabled = false;
              range = 4;
              render_power = 3;
              scale = 1.0;
            };
          };

          # hyprglass glosses; it does not blur. Hyprland's own `layerrule =
          # blur on` is what these surfaces sit on, and the plugin refracts
          # over the result — without this pair the plugin loads and shows
          # nothing, which is the usual "hyprglass isn't working" report.
          # Ported verbatim from Aoide's compositor facet, including its two
          # deliberate exclusions: aoide-bar takes `blur_popups` only (the
          # strip's popouts frost, the strip itself is the song's own ground),
          # and aoide-calendar is pinned blur OFF so its cut-out day grid shows
          # the desktop crisply. The waybar rule stays for the facet-off case.
          layerrule =
            [
              "blur on, match:namespace waybar"
            ]
            ++ lib.optionals aoideFace [
              "blur on, match:namespace aoide-dock"
              "blur on, match:namespace aoide-launcher"
              "blur on, match:namespace aoide-powermenu"
              "ignore_alpha 0.05, match:namespace aoide-dock"
              "ignore_alpha 0.05, match:namespace aoide-launcher"
              "ignore_alpha 0.05, match:namespace aoide-powermenu"
              "blur_popups on, match:namespace aoide-bar"
              "blur off, match:namespace aoide-calendar"
            ];

          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };

          dwindle = {
            preserve_split = true;
          };

          master = {
            new_status = "master";
          };

          # HDMI-A-1 is a vertical monitor (transform 3). Its workspaces use the
          # scrolling layout below; the tape grows downward so windows stack
          # top-to-bottom and you scroll through them instead of shrink-to-fit.
          scrolling = {
            direction = "down";
          };

          misc = {
            force_default_wallpaper = -1;
          };

          ecosystem = {
            no_update_news = true;
            no_donation_nag = true;
          };
        };

        # ── hyprglass config ────────────────────────────────────────────────
        # Written through the top-level `extraConfig` (a sibling of `settings`,
        # emitted at the END of hyprland.conf) rather than through `settings`:
        # `plugin:hyprglass { … }` is a plugin keyword block, and hyprlang wants
        # it verbatim.
        #
        # Ported from Aoide's compositor facet with ONE deliberate deviation.
        # Aoide overrides the `light` theme block, and says why: sonata is a
        # light marble song and the glass wanted brightening under it. osaka
        # performs nocturne — #0a0e27 navy — so the light override would be
        # tuning the wrong half of the plugin. The `dark` block gets the same
        # value instead, and `default_theme` pins which half is live (the
        # plugin validates it: "Invalid default_theme" is its own error string).
        # Retune this alongside `aoide.song` if osaka ever performs a light one.
        #
        # manage_window_blur is a GLOBAL toggle in v0.7.0 — there is no
        # per-class targeting (confirmed against the built plugin's key table).
        # It stays on because the shader only paints visible translucent
        # fragments: the frosted kitty gains refraction, opaque windows are
        # untouched.
        #
        # The namespace list is the three surfaces Aoide glasses. It is static
        # here on purpose: Aoide's facet appends song-declared widget surfaces
        # too, but only `kind = "surface"` widgets ever get a layer surface of
        # their own, and nocturne's sole widget (`vigil`) is `kind = "dock"` —
        # it mounts as an Item inside aoide-dock and is already covered by the
        # dock's own entry. A song declaring a real surface widget would want
        # its namespace added here by hand.
        extraConfig = lib.optionalString aoideFace ''
          plugin:hyprglass {
              manage_window_blur = 1
              default_theme = dark
              dark {
                  glass_opacity = 0.82
              }
              layers {
                  enabled = 1
                  namespaces = aoide-dock, aoide-launcher, aoide-powermenu
                  preset = glass
              }
          }

          # ── Aero-glass terminal (pairs with the kitty dendrite) ────────────
          # kitty's background_opacity makes the CELL background translucent;
          # these rules do the WINDOW. Active stays fully crisp at 1.0, and an
          # unfocused terminal fades to 0.80 so it visibly recedes behind the
          # focused one. Terminals only, deliberately — this is not a global
          # inactive_opacity, because media and browser windows carry arbitrary
          # content that must never be faded.
          #
          # 0.80 is Aoide's documented legibility FLOOR-plus: it keeps unfocused
          # terminal text near 3.7:1, and their note marks 0.75 as the hard
          # floor with 0.70 breaking readability outright. Raise toward 0.85 if
          # it reads badly against nocturne's navy — never drop below 0.75.
          #
          # One-line `windowrule =` form, matching Aoide's own. The `settings`
          # block above uses hyprland 0.56's other spelling (`windowrule { … }`)
          # — both are current; this file now carries both because each was
          # copied from where it was proven.
          windowrule = opacity 1.0 0.80, match:class kitty
          # Global decoration rounding is already 0; this pins kitty to match so
          # nothing rounds only the terminal.
          windowrule = rounding 0, match:class kitty
        '';
      };
    };
  };
}
