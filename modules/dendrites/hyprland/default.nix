{
  username,
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.dx.aggregations.hyprland {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    home-manager.users.${username} =
      {
        pkgs,
        config,
        inputs,
        lib,
        ...
      }:
      {
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
            variables = [ "--all" ];
          };
          xwayland.enable = true;

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
            "exec-once" = [
              "systemctl --user start hyprpolkitagent"
              "nm-applet --indicator"
              "systemd"
              "hypridle"
              "awww-daemon"
              "awww img -o DP-1 ~/dxflake/assets/wallpapers/hero.webp"
              "awww img -o HDMI-A-1 ~/dxflake/assets/wallpapers/yuki-standing.png"
              "waybar"
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
              "special:magic, on-created-empty:pear-desktop"
              "special:scratch, layout:scrolling"
              "2, monitor:HDMI-A-1, persistent:true"
              "special:replay, on-created-empty:gpu-screen-recorder-gtk"
              # Every workspace on the vertical monitor uses the scrolling layout.
              "m[HDMI-A-1], layout:scrolling"
            ];

            # Keybindings
            bind = [
              "SUPER, RETURN, exec, kitty"
              "SUPER, SPACE, exec, rofi -show drun"
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

            layerrule = [
              "blur on, match:namespace waybar"
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
        };
      };
  };
}
