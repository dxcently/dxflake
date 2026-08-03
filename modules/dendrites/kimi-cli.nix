{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  # Not in nixpkgs — built from its own uv.lock via the uv2nix stack (flake
  # inputs). See pkgs/kimi-cli for the builder and bump instructions.
  kimi-cli = pkgs.callPackage ../../pkgs/kimi-cli {
    inherit (inputs) pyproject-nix uv2nix pyproject-build-systems;
  };
in
{
  options.dx.kimi-cli.enable = lib.mkEnableOption "kimi-cli (Moonshot's Kimi coding agent)";
  config = lib.mkIf config.dx.kimi-cli.enable {
    environment.systemPackages = [ kimi-cli ];
  };
}
