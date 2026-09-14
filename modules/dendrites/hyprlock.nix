{
  nixos = { username, ... }: {
    # A host-selected single, not tied to the shell aggregation: chiyo wants
    # the lock binary + PAM service without hyprland (Aoide's own hyprland
    # dendrite binds SUPER+ESCAPE to hyprlock and shellbridge's powermenu Lock
    # action shells it, but Aoide ships no lockscreen anchor of its own yet),
    # while a host running the shell aggregation that wants both selects this
    # file alongside it and takes it as part of its own selection.
    config = {
      programs.hyprlock.enable = true;
      security.pam.services.hyprlock = { };
      home-manager.users.${username} =
        {
          pkgs,
          config,
          inputs,
          ...
        }:
        {
          programs.hyprlock = {
            enable = true;
          };
        };
    };
  };
}
