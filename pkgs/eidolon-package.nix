{
  lib,
  rustPlatform,
  src,
}:

# Eidolon, built from the `eidolon-src` flake input — github.com/noah427/eidolon
# master, re-locked by `nix flake update eidolon-src` (flake.nix carries the
# why). Same move as pkgs/melete-package.nix, which carries the fuller notes.
#
# The workspace is virtual, so its version lives under [workspace.package].
# The binary is the `eidolon` target of crates/cli, and buildRustPackage
# installs every target it builds, so nothing selects it here.
#
# Its one git dependency, harnox, is a tagged git source in Cargo.lock. It is
# fetched by builtins.fetchGit in the evaluator, as the user running the
# rebuild, with that user's git credential helper (gh). A sandboxed
# fixed-output fetch has no credentials for the private noah427 repo.
# Consequence: evaluate as khoa (`nh os switch`), never via sudo.
let
  cargoToml = lib.importTOML (src + "/Cargo.toml");
in
rustPlatform.buildRustPackage {
  pname = "eidolon";
  version = cargoToml.workspace.package.version;

  src = lib.cleanSourceWith {
    inherit src;
    filter =
      path: _type:
      let
        base = baseNameOf (toString path);
      in
      base != ".git" && base != "target" && base != ".cargo";
  };

  cargoLock = {
    lockFile = src + "/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  doCheck = false;

  meta = {
    description = "Eidolon — interactive coding harness, built from upstream master";
    mainProgram = "eidolon";
  };
}
