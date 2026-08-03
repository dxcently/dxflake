{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.dx.pi-coding-agent.enable = lib.mkEnableOption "pi coding agent CLI";
  config = lib.mkIf config.dx.pi-coding-agent.enable {
    environment.systemPackages = [ pkgs.pi-coding-agent ];
  };
}
