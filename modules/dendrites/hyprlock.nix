{username, config, lib, ...}: {
  # Carved out of the hyprland aggregation like dx.stylix.enable: a host that
  # turns dx.aggregations.hyprland off but still wants the lock binary + PAM
  # service (chiyo — Aoide's own hyprland dendrite binds SUPER+ESCAPE to
  # hyprlock and shellbridge's powermenu Lock action shells it, but Aoide
  # ships no lockscreen anchor of its own yet) flips this on independently.
  # Defaulting to the aggregation keeps every existing hyprland host
  # unchanged.
  options.dx.hyprlock.enable = (lib.mkEnableOption "dxflake's own hyprlock (binary + PAM service)") // {
    default = config.dx.aggregations.hyprland;
  };

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
