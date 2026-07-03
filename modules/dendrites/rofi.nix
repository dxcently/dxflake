{username, config, lib, ...}: {
  config = lib.mkIf config.dx.aggregations.hyprland {
    home-manager.users.${username} = {
      pkgs,
      config,
      inputs,
      ...
    }: {
      programs.rofi = {
        enable = true;
        package = pkgs.rofi;
      };
    };
  };
}
