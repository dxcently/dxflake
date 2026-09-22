# OpenAI's desktop tools, owned by dxflake.
#
# This used to ride `aoide.openai.enable`, which meant a host could not install
# Codex and the ChatGPT desktop without carrying an Aoide option surface for
# them. Installing an application is not an Aoide integration, so the selection
# lives here like Kimi's does and Aoide's own flag stays unset.
#
# `pkgs.codex` is nixpkgs'. `pkgs.chatgpt-linux` has no nixpkgs definition and
# arrives through the Aoide packages overlay every host already carries — the
# same package `aoide.openai.enable` installed, so membership is unchanged.
# Aoide exports it publicly too (`packages.<system>.chatgpt-linux`); reaching
# that export needs a public overlay/module seam upstream, tracked with the
# rest of the private-path consumption in flake.nix.
{
  nixos =
    { pkgs, ... }:
    {
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = [
        pkgs.codex
        pkgs.chatgpt-linux
      ];
    };

  # The same two applications for a user who wants them without a system-wide
  # install. Package-set permissions stay the consumer's, as with any home lane.
  homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.codex
        pkgs.chatgpt-linux
      ];
    };
}
