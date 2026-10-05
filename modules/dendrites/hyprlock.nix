{
  nixos = { username, lib, ... }: {
    # A host-selected single, not tied to the shell aggregation: chiyo wants
    # the lock binary + PAM service without hyprland (Aoide's own hyprland
    # dendrite binds SUPER+ESCAPE to hyprlock and shellbridge's powermenu Lock
    # action shells it, but Aoide ships no lockscreen anchor of its own yet),
    # while a host running the shell aggregation that wants both selects this
    # file alongside it and takes it as part of its own selection.
    #
    # `programs.hyprlock` also enables NixOS's `services.hypridle`, which ships
    # the unit but no config; the home half below writes the config, and its
    # user unit of the same name replaces the system one.
    #
    # The lock shows one dot per key, the keyboard layout, and Caps/Num Lock, so
    # a failing unlock says why. Blocks are attribute sets and colours defaults,
    # so a host whose stylix themes hyprlock merges over them.
    config = {
      programs.hyprlock.enable = true;
      security.pam.services.hyprlock = { };
      home-manager.users.${username} = {
        programs.hyprlock = {
          enable = true;
          settings = {
            general.hide_cursor = false;
            background.color = lib.mkDefault "rgba(20, 20, 30, 1.0)";
            input-field = {
              size = "400, 60";
              position = "0, 0";
              halign = "center";
              valign = "center";
              outline_thickness = 3;
              dots_size = 0.25;
              dots_spacing = 0.3;
              dots_center = true;
              fade_on_empty = false;
              placeholder_text = "password";
              fail_text = "failed ($ATTEMPTS)";
              capslock_color = lib.mkDefault "rgb(220, 120, 60)";
              numlock_color = lib.mkDefault "rgb(60, 160, 220)";
            };
            label = {
              text = "$LAYOUT";
              position = "0, -80";
              halign = "center";
              valign = "center";
              font_size = 16;
            };
          };
        };
        services.hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock";
              before_sleep_cmd = "loginctl lock-session";
              after_sleep_cmd = "hyprctl dispatch dpms on";
            };
            listener = [
              {
                timeout = 600;
                on-timeout = "loginctl lock-session";
              }
              {
                timeout = 900;
                on-timeout = "hyprctl dispatch dpms off";
                on-resume = "hyprctl dispatch dpms on";
              }
            ];
          };
        };
      };
    };
  };
}
