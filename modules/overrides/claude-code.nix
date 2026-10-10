# Keep the CLI current while retaining nixpkgs' native runtime and sandbox setup.
# Aoide's overlay pins claude-code too and is applied after a record's `overlay`,
# so this pin rides `system` with mkAfter to land after it.
{
  dendrites = [ "claude-code" ];
  system =
    { lib, ... }:
    {
      nixpkgs.overlays = lib.mkAfter [
        (final: _prev: {
          claude-code = final.callPackage (final.path + "/pkgs/by-name/cl/claude-code/package.nix") {
            manifest = lib.importJSON ../../pkgs/claude-code/manifest.zst.json;
          };
        })
      ];
    };
}
