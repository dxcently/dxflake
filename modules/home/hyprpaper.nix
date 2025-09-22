{
  pkgs,
  config,
  ...
}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "true";
      splash = false;
      preload = [" ~/dxflake/extras/wallpapers/hero.webp"];
      wallpaper = [",~/dxflake/extras/wallpapers/hero.webp"];
    };
  };
}
