# Use the official release bundle until the nixpkgs pin catches up.
{
  dendrites = [ "openai" ];
  overlay = final: _prev: {
    codex = final.callPackage ../../pkgs/codex { };
  };
}
