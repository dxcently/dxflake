# Keep the CLI current while retaining nixpkgs' native runtime and sandbox setup.
{
  dendrites = [ "claude-code" ];
  overlay = _final: prev: {
    claude-code = prev.claude-code.override {
      manifest = builtins.fromJSON (builtins.readFile ../../pkgs/claude-code/manifest.zst.json);
    };
  };
}
