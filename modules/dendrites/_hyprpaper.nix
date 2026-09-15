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
            preload = [ " ~/dxflake/songbook/covers/hero.webp" ];
            wallpaper = [ ",~/dxflake/songbook/covers/hero.webp" ];
          };
        };
      };
  };
}
