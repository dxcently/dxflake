{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.dx.claude-code.enable = lib.mkEnableOption "Claude Code agentic CLI";
  config = lib.mkIf config.dx.claude-code.enable {
    environment.systemPackages = [ pkgs.claude-code ]; # agentic AI coding assistant
  };
}
