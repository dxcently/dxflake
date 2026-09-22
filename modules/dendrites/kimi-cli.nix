{
  nixos =
    {
      pkgs,
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
      config = {
        environment.systemPackages = [ kimi-cli ];
      };
    };
}
