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
      preload = ["~/dxflake/extras/wallpapers/ssr_tile.png"];
      wallpaper = [", tile:~/dxflake/extras/wallpapers/ssr_tile.png"];
    };
  };
}
