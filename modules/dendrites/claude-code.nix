{ pkgs, ... }:
{
  config = {
    environment.systemPackages = [ pkgs.claude-code ]; # agentic AI coding assistant
  };
}
