{lib, ...}: {
  options.dx.aggregations = {
    desktop = lib.mkEnableOption "desktop role";
    hyprland = lib.mkEnableOption "hyprland role";
    gaming = lib.mkEnableOption "gaming role";
    server = lib.mkEnableOption "server role";
  };
}
