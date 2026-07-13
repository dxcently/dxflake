{
  username,
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.dx.aggregations.hyprland {
    home-manager.users.${username} =
      {
        pkgs,
        config,
        ...
      }:
      {
        services.hyprpaper = {
          enable = false;
          settings = {
            ipc = "true";
            splash = false;
            preload = [ " ~/dxflake/assets/wallpapers/hero.webp" ];
            wallpaper = [ ",~/dxflake/assets/wallpapers/hero.webp" ];
          };
        };
      };
  };
}
