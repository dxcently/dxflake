{username, config, lib, ...}: {
  config = lib.mkIf config.dx.aggregations.hyprland {
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
