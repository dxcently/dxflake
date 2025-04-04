{
  pkgs,
  config,
  ...
}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = [" ~/dxflake/extras/wallpapers/azumanga_tile.png"];
      wallpaper = [",tile:~/dxflake/extras/wallpapers/azumanga_tile.png"];
    };
  };
}
