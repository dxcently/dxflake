{config, lib, ...}: {
  options.dx.k3b.enable = lib.mkEnableOption "k3b";
  config = lib.mkIf config.dx.k3b.enable {
    programs.k3b.enable = true;
  };
}
