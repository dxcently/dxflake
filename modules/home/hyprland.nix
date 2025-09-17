{
  pkgs,
  config,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    plugins = [
      pkgs.hyprlandPlugins.hyprbars
      pkgs.hyprlandPlugins.borders-plus-plus
    ];
    extraConfig = ''

      #monitors
      monitor=, preferred, auto, 1.5
      monitor= eDP-1, 1920x1080@60, auto, 1
      monitor= DP-1, 1920x1080@144, 0x0, 1
      monitor= HDMI-A-1, 1920x1080@60, 1920x0, 1

      #env variables
      env = XCURSOR_SIZE,24
      env = QT_QPA_PLATFORMTHEME,qt5ct # change to qt6ct if you have that
      env = WLR_NO_HARDWARE_CURSORS,1

      #start programs
      exec-once = systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = dbus-update-activation-environment --systemd --all
      exec-once = systemd
      exec-once = nm-applet --indicator
      exec-once = hyprpaper
      exec-once = waybar
      exec-once = wl-paste --type text --watch cliphist store & wl-paste --type image --watch cliphist store & wl-paste --watch cliphist store
      exec-once = [workspace 1 silent] librewolf
      exec-once = [workspace 5 silent] vesktop

      windowrule = opacity 0.8, title:^(FL Studio)$
      #workspaces window rules
      #windowrule = workspace special:discord, class:^([Vv]esktop)$, title:^([Vv]esktop)$
      windowrule = workspace 5, class:^([Vv]esktop)$, title:^([Vv]esktop)$
      windowrule = workspace special:scratch, class:^([Ss]team)$, title:^([Ss]team)$
      windowrule = workspace special:magic, class:^([Ss]trawberry)$,title:^([Ss]trawberry)$
      windowrule = workspace special:magic, title:^(YouTube Music)$
      windowrule = noborder, class:^(Audacious)$
      windowrule = plugin:hyprbars:nobar, class:^(Audacious)$

      layerrule = blur, waybar

      #workspace = special:discord, monitor:HDMI-A-1, on-created-empty:vesktop
      workspace = special:magic, on-created-empty:youtube-music
      workspace = 5, monitor:HDMI-A-1, persistent:true

      #keybindings
      bind = SUPER, RETURN, exec, kitty #terminal
      bind = SUPER, SPACE, exec, rofi -show drun #launcher
      bind = SUPER, T, exec, [float] thunar #file manager
      bind = SUPER, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy #clipboard
      bind = SUPER, S, exec, grim -g "$(slurp -d)" - |swappy -f - #screenshot
      bind = SUPER, Tab, exec, rofi -show #show windows
      bind = SUPER, D, exec, [workspace 5; monitor hdmi-a-1] vesktop

      bind = SUPER, Q, killactive
      bind = SUPER, V, togglefloating
      bind = SUPER, F, fullscreen
      bind = SUPER, P, pseudo

      bind = SUPER, H, movefocus, l
      bind = SUPER, J, movefocus, d
      bind = SUPER, K, movefocus, u
      bind = SUPER, L, movefocus, r
      bind = SUPER SHIFT, H, movewindow, l
      bind = SUPER SHIFT, J, movewindow, d
      bind = SUPER SHIFT, K, movewindow, u
      bind = SUPER SHIFT, L, movewindow, r
      bind = SUPER ALT, H, resizeactive, -20 0
      bind = SUPER ALT, J, resizeactive, 0 20
      bind = SUPER ALT, K, resizeactive, 0 -20
      bind = SUPER ALT, L, resizeactive, 20 0
      bind = ALT, Tab, cyclenext
      bind = ALT, Tab, bringactivetotop

      bind = SUPER, 1, workspace, 1
      bind = SUPER, 2, workspace, 2
      bind = SUPER, 3, workspace, 3
      bind = SUPER, 4, workspace, 4
      bind = SUPER, 5, workspace, 5
      bind = SUPER, 6, workspace, 6
      bind = SUPER, 7, workspace, 7
      bind = SUPER, 8, workspace, 8
      bind = SUPER, 9, workspace, 9
      bind = SUPER, 0, workspace, 10
      bind = SUPER SHIFT, 1, movetoworkspace, 1
      bind = SUPER SHIFT, 2, movetoworkspace, 2
      bind = SUPER SHIFT, 3, movetoworkspace, 3
      bind = SUPER SHIFT, 4, movetoworkspace, 4
      bind = SUPER SHIFT, 5, movetoworkspace, 5
      bind = SUPER SHIFT, 6, movetoworkspace, 6
      bind = SUPER SHIFT, 7, movetoworkspace, 7
      bind = SUPER SHIFT, 8, movetoworkspace, 8
      bind = SUPER SHIFT, 9, movetoworkspace, 9
      bind = SUPER SHIFT, 0, movetoworkspace, 10

      bind = SUPER, X, togglespecialworkspace, magic
      bind = SUPER, Z, togglespecialworkspace, scratch
      #bind = SUPER, D, togglespecialworkspace, discord
      bind = SUPER SHIFT, X, movetoworkspace, special:magic
      bind = SUPER SHIFT, Z, movetoworkspace, special:scratch
      #bind = SUPER SHIFT, D, movetoworkspace, special:discord
      bind = SUPER SHIFT, D, movetoworkspace, 5

      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow

      bind = ,XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 4%-
      bind = ,XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 4%+
      bind = ,XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind = ,XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      bind = ,XF86MonBrightnessDown, exec,  brightnessctl s 5%-
      bind = ,XF86MonBrightnessUp, exec, brightnessctl s 5%+

      #looksmaxxing
      plugin {
        hyprbars {
            bar_color = rgba(00000000)
            col.text = rgba(0, 0, 0, 1)
            bar_text_align = left
            bar_text_size = 10
            bar_precedence_over_border = true
            bar_part_of_window = false
            bar_height = 20
            bar_blur = true
            xray = true
            hyprbars-button = rgba(ffffff00), 16, 󰖭, hyprctl dispatch killactive, rgb(A66B7B)
            hyprbars-button = rgba(ffffff00), 12, 🗖,hyprctl dispatch fullscreen, rgba(0, 0, 0, 1)
            hyprbars-button = rgba(ffffff00), 12, 🗕, hyprctl dispatch togglefloating, rgba(0, 0, 0, 1)
        }
        borders-plus-plus {
            add_borders = 1
            natural_rounding = false
            col.border_1 = rgb(000000)
            border_size_1 = 1
        }
      }

      input {
        kb_layout = us
        kb_options = compose:caps #changes capslock to composekey button

        follow_mouse = 1
        sensitivity = 0.8
        accel_profile = flat
        force_no_accel = true

        touchpad {
          natural_scroll = true
          middle_button_emulation = true
          clickfinger_behavior = true
        }
      }

      #gestures {
      #  workspace_swipe = true
      #  workspace_swipe_fingers = 3
      #}

      general {
        gaps_in = 4
        gaps_out = 6
        border_size = 4
        col.active_border = rgba(ffffff00)
        col.inactive_border = rgba(ffffff00)
        layout = dwindle
        allow_tearing = true
      }

      decoration {
        rounding = 2
        blur {
          enabled = true
          size = 2
          passes = 2
          xray = true
          vibrancy_darkness = 1.0
          ignore_opacity = true
          new_optimizations = true
        }
        blurls = waybar
        shadow {
          enabled = false;
          range = 4
          render_power = 3
          scale = 1.0
        }
      }


      animations {
        enabled = true
        bezier = myBezier, 0.05, 0.9, 0.1, 1.05
        animation = windows, 1, 7, myBezier
        animation = windowsOut, 1, 7, default, popin 80%
        animation = border, 1, 10, default
        animation = borderangle, 1, 8, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 6, default
      }

      dwindle {
        pseudotile = true
        preserve_split = true
      }

      master {
        new_status = master
      }

      misc {
        force_default_wallpaper = -1
      }

    '';
  };
  #command to remove symlink to edit
  #cp --remove-destination `readlink hyprland.conf` hyprland.conf
}
