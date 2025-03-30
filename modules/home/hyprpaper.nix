{
  pkgs,
  config,
  ...
}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      preload = ["~/dxflake/extras/wallpapers/ssr_tile.png"];
      wallpaper = [",tile:~/dxflake/extras/wallpapers/ssr_tile.png"];
    };
  };
}
