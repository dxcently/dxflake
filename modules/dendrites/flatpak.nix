{config, lib, ...}: {
  config = lib.mkIf config.dx.aggregations.desktop {
    services.flatpak.enable = true;
  };
}
