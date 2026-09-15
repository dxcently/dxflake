# eidolon — the interactive Rust coding harness (github.com/noah427/eidolon),
# noah427's replacement for pi. System-only: it's a CLI/TUI a user runs from a
# terminal, not a service or a home-manager-configured program (it has no
# dotfiles here to manage — its own config.toml is untouched by this dendrite).
{
  nixos =
    { pkgs, inputs, ... }:
    let
      eidolonPkg = pkgs.callPackage ../../pkgs/eidolon-package.nix {
        src = inputs.eidolon-src;
        harnoxSrc = inputs.harnox-src;
      };
    in
    {
      config.environment.systemPackages = [ eidolonPkg ];
    };
}
