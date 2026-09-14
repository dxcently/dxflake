# example-package.nix — a package this tree builds itself.
#
# Copy to:  pkgs/<name>/default.nix
# Then:     reach it from a lane. pkgs/ is for builds nixpkgs does not have —
#           not a second copy of nixpkgs. If `pkgs.<name>` already exists, use
#           it and delete this file.
# Replace:  <name>, the source, and the hashes. The hashes below are
#           PLACEHOLDERS: build once with `lib.fakeHash`, and Nix prints the
#           real one in the mismatch error.
#
# Two ways to reach it, and the difference matters:
#
#   1. Directly from the lane that wants it — the honest default for something
#      only one capability uses:
#        environment.systemPackages = [ (pkgs.callPackage ../../pkgs/<name> { }) ];
#
#   2. Through an overlay in flake.nix, when several lanes want it and
#      `pkgs.<name>` reading naturally is worth the indirection.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "example-tool";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "example";
    repo = "example-tool";
    rev = "v${version}";
    hash = lib.fakeHash; # REPLACE — build once, copy the hash from the error
  };

  cargoHash = lib.fakeHash; # REPLACE — same

  meta = {
    description = "One line about what this builds";
    homepage = "https://example.invalid/example-tool";
    license = lib.licenses.mit;
    mainProgram = "example-tool";
  };
}
