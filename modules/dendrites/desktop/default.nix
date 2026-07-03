{config, lib, ...}: {
  # gaming/electron want a high mmap count; shared by every desktop.
  config = lib.mkIf config.dx.aggregations.desktop {
    boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  };
}
