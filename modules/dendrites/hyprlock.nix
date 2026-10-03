{
  nixos = { username, ... }: {
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
    config = {
      programs.hyprlock.enable = true;
      security.pam.services.hyprlock = { };
      home-manager.users.${username} = {
        programs.hyprlock.enable = true;
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
