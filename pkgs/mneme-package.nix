{
  lib,
  rustPlatform,
  src,
}:

# Mneme, built from the dev checkout wired in as the `mneme-src` flake input
# (~/mneme) — same move as pkgs/melete-package.nix, which carries the
# fuller notes on why the release-asset fetch is gone.
#
# Note the repo has a flake.nix of its own, but its outputs are the same
# hash-pinned fetch-a-published-artifact helpers we're replacing (lib.mkMneme)
# plus a NixOS module modelling a differently-shaped unit than this flake's
# modules/dendrites/mneme.nix. So the input takes `flake = false` and this
# builds the crate directly; nothing there builds from source.
#
# Unlike melete, mneme has no self-update, so this store path is the only
# thing that ever moves its binary.
let
  cargoToml = lib.importTOML (src + "/Cargo.toml");
in
rustPlatform.buildRustPackage {
  pname = "mneme";
  version = cargoToml.package.version;

  src = lib.cleanSourceWith {
    inherit src;
    filter =
      path: _type:
      let
        base = baseNameOf (toString path);
      in
      base != ".git" && base != "target";
  };

  cargoLock = {
    lockFile = src + "/Cargo.lock";
    # Git dependencies (harnox, eidolon) live in PRIVATE noah427 repos. A
    # sandboxed fixed-output fetch has no credentials and can never reach
    # them, so let importCargoLock use builtins.fetchGit instead: it runs in
    # the evaluator, as the user running the rebuild, with that user's git
    # credential helper (gh). Pinned by exact rev from Cargo.lock, so still
    # reproducible. Consequence: rebuild as khoa (`nh os switch`), not via
    # a bare `sudo nixos-rebuild` — root has no GitHub credentials.
    allowBuiltinFetchGit = true;
  };

  doCheck = false;

  meta = {
    description = "Mneme vault MCP server, built from the local dev checkout";
    mainProgram = "mneme";
  };
}
