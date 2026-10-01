# Opt-in build: keep the baseline package and installed runtime available.
{ callPackage }:
(callPackage ./default.nix { }).overrideAttrs (old: {
  version = "${old.version}-hip-ptq1-packed-v2";
  patches = (old.patches or [ ]) ++ [ ./patches/hip-ptq1-packed-dot.patch ];
})
