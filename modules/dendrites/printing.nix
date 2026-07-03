{config, lib, ...}: {
  config = lib.mkIf config.dx.aggregations.desktop {
    services.printing.enable = true;
    programs.system-config-printer.enable = true;
  };
}
