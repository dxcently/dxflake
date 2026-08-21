{
  lib,
  rustPlatform,
  src,
}:

# Melete, built from the dev checkout wired in as the `melete-src` flake input
# (~/melete). That repo is the source of truth now; this replaces the
# release-asset fetch that used to live in pkgs/melete-client-package.nix,
# along with the whole NIX_GITHUB_RELEASE_TOKEN / impure-env apparatus it
# needed to reach a private repo's assets (git history has both, if a
# fetch-the-release build is ever wanted again).
#
# Version comes from the checkout's own Cargo.toml, so it tracks the dev repo
# rather than a number pinned here that has to be bumped in lockstep.
#
# MELETE_RELEASE is deliberately NOT stamped: that env var is a *release*
# identity (src/self_update/mod.rs), and a dev build is not a release. Unset,
# CURRENT_RELEASE falls back to CARGO_PKG_VERSION, which reads as up to date
# against a channel pointing at the matching v-tag (the comparison strips a
# leading `v`). The moment the dev tree's Cargo version runs ahead of the
# released tag, though, a self-updating instance would see a difference and
# swap this build out for the release binary. sakaki is already safe from that
# — ~/.config/melete/config.toml carries
#   [self_update]
#   managed_externally = true
#   enabled = false
# (out-of-band, not Nix-managed), so updates are reported and never applied.
# Keep that posture on any host that runs a build from here.
let
  cargoToml = lib.importTOML (src + "/Cargo.toml");
in
rustPlatform.buildRustPackage {
  pname = "melete";
  version = cargoToml.package.version;

  # `git+file:` already delivers a clean tree; the filter is what makes the
  # `path:` override (uncommitted edits — see flake.nix) usable, since that
  # fetcher copies the directory verbatim and .git/ churn alone would
  # otherwise force a full rebuild.
  src = lib.cleanSourceWith {
    inherit src;
    filter =
      path: _type:
      let
        base = baseNameOf (toString path);
      in
      base != ".git" && base != "target";
  };

  cargoLock.lockFile = src + "/Cargo.lock";

  # Upstream CI owns the test suite; this build exists to produce the binary
  # this host runs.
  doCheck = false;

  meta = {
    description = "Melete — Mneme's companion AI harness, built from the local dev checkout";
    mainProgram = "melete";
  };
}
