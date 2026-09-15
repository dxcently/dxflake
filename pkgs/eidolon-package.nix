# Eidolon, built from the `eidolon-src` flake input — github.com/noah427/eidolon,
# pinned to that repo's default branch. Same private-repo/git+https deal as
# pkgs/melete-package.nix and pkgs/mneme-package.nix.
#
# Unlike those two, this does not reimplement buildRustPackage: eidolon's own
# nix/eidolon.nix already knows how to reassemble the workspace beside a
# harnox checkout (its Cargo.toml patches `harnox` to `path = "../harnox"`
# for a build of the workspace itself) and build it, so this just calls that
# recipe with the two source trees dxflake pins. See flake.nix's eidolon-src
# / harnox-src comment for why harnox-src is dxflake's own input rather than
# eidolon's.
{
  pkgs,
  src,
  harnoxSrc,
}:
pkgs.callPackage (src + "/nix/eidolon.nix") { inherit harnoxSrc; }
