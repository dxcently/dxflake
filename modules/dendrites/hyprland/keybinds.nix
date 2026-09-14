# hyprland-keybinds — how the desktop is driven.
#
# Binds, mouse binds, input, workspace assignment and the per-window placement
# rules. Split out because this is the layer with a real competitor: chiyo sets
# `aoide.hyprland.enable` and takes AoideOS's behaviour dendrite instead, and
# the two must never both be selected — they bind the same keys.
#
# Deliberately NOT in scope, unchanged from before the split: media and
# brightness XF86 keys. Those are the desktop aggregation's and the laptop
# dendrite's respectively, because which of them exists is a property of the
# hardware, not of the compositor.
{
  homeManager =
    {
      pkgs,
      osConfig,
      lib,
      ...
    }:
    let
      aoideFace = osConfig.aoide.facets.quickshell.enable;
    in
    {
      # Its own dependencies, not free-floating membership: the screenshot and
      # colour-picker binds below are the only callers either package has.
      home.packages = with pkgs; [
        hyprshot
        hyprpicker
      ];

      wayland.windowManager.hyprland = {
        settings = {
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
          bind = [
            "SUPER, RETURN, exec, kitty"
          ]
          ++ (
            if aoideFace then
              [
                "SUPER, SPACE, global, aoide:launcher"
                "SUPER, G, global, aoide:dock"
                "SUPER, W, global, aoide:wallpaper"
              ]
            else
              [ "SUPER, SPACE, exec, rofi -show drun" ]
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
        };

        # ── Window placement ────────────────────────────────────────────────
        # These are hyprland 0.56's named-block spelling of `windowrule`, which
        # hyprlang wants verbatim — so they go through the TOP-LEVEL extraConfig
        # (`types.lines`, emitted raw at the end of hyprland.conf).
        #
        # They used to sit in `settings.extraConfig`, and `settings` renders
        # `key=value`: every generated hyprland.conf carried a literal, bogus
        # `extraConfig=` keyword line ahead of them. The rules themselves are
        # unchanged; only the stray keyword is gone.
        extraConfig = ''
          # Using the preferred 'class' and 'title' matching.
          windowrule {
            name = windowrule-1
            opacity = 0.8 override 0.8 override
            match:title = ^(FL Studio)$
          }

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
        '';
      };
    };
}
