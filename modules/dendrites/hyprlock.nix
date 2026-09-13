{username, config, lib, ...}: {
  # A host-selected single, not tied to the hyprland aggregate: chiyo wants
  # the lock binary + PAM service without hyprland (Aoide's own hyprland
  # dendrite binds SUPER+ESCAPE to hyprlock and shellbridge's powermenu Lock
  # action shells it, but Aoide ships no lockscreen anchor of its own yet),
  # while a hyprland host that wants both imports this file alongside the
  # aggregate and sets the flag explicitly.
  options.dx.hyprlock.enable = lib.mkEnableOption "dxflake's own hyprlock (binary + PAM service)";

  config = lib.mkIf config.dx.hyprlock.enable {
    programs.hyprlock.enable = true;
    security.pam.services.hyprlock = {};
    home-manager.users.${username} = {
      pkgs,
      config,
      inputs,
      ...
    }: {
      programs.hyprlock = {
        enable = true;
      };
    };
  };
}
