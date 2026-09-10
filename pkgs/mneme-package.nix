{
  lib,
  rustPlatform,
  src,
  harnoxSrc,
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

  # mneme's Cargo.lock names harnox as a git source. importCargoLock would
  # try to fetch that URL inside the sandbox — it's a private repo, so it
  # can't. Rewrite the dep to a path pointing at the harnox-src input:
  # drop the `source = "git+…harnox…"` line from the lock (a path dep has no
  # source line) and point Cargo.toml at the store path in postPatch.
  harnoxGitSource = builtins.head (
    builtins.filter (l: lib.hasPrefix "source = \"git+https://github.com/noah427/harnox" l)
      (lib.splitString "\n" (builtins.readFile (src + "/Cargo.lock")))
  );
  patchedLock = builtins.toFile "Cargo.lock" (
    builtins.replaceStrings [ (harnoxGitSource + "\n") ] [ "" ] (builtins.readFile (src + "/Cargo.lock"))
  );
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

  cargoLock.lockFile = patchedLock;

  postPatch = ''
    cp ${patchedLock} Cargo.lock
    substituteInPlace Cargo.toml \
      --replace-fail 'harnox = { git = "https://github.com/noah427/harnox", tag = "v0.1.0", features = ["oauth-server"] }' \
                     'harnox = { path = "${harnoxSrc}", features = ["oauth-server"] }'
  '';

  doCheck = false;

  meta = {
    description = "Mneme vault MCP server, built from the local dev checkout";
    mainProgram = "mneme";
  };
}
