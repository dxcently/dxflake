# Experimental launch geometry, never selected by the system or chat defaults.
{ callPackage }:
(callPackage ../../pkgs/bonsai/experimental.nix { }).overrideAttrs (old: {
  version = "${old.version}-two-waves";
  patches = old.patches ++ [ ./patches/ptq1-two-waves.patch ];
})
