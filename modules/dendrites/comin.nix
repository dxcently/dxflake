# comin — pull-based deploys. Each host polls dxflake's main branch and builds
# its own nixosConfigurations.<hostName>; a commit that fails to build is never
# applied, so the running system stays put.
#
# dxflake is public, so comin's own fetch needs no token. The flake's private
# inputs (melete, mneme, eidolon, Aoide, snowglobe) and their cargo git
# dependencies are fetched by root's Nix during evaluation, which has no `gh`
# login. One read token serves both fetchers: `github:` reads `access-tokens`
# from nix.conf (`!include` skips a missing file, so the first activation
# before sops renders it does not break nix.conf), and `git+https`/`fetchGit`
# shell out to git, which reads only a credential helper.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  token = config.sops.secrets."github/read-token".path;
  credential = pkgs.writeShellScript "github-credential" ''
    [ "$1" = get ] || exit 0
    echo username=x-access-token
    echo "password=$(cat ${token})"
  '';
in
{
  imports = [ inputs.comin.nixosModules.comin ];

  # `remotes` is a list, so a host cannot reach into it to change one field.
  options.dx.comin.operation = lib.mkOption {
    type = lib.types.enum [
      "switch"
      "boot"
    ];
    default = "boot";
    description = ''
      How a new main commit is applied. `boot` waits for the next reboot, so a
      desktop never has services restarted under a live session; `switch`
      follows main live.
    '';
  };

  config = {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/dxcently/dxflake.git";
          branches.main.operation = config.dx.comin.operation;
        }
      ];
    };

    # Scoped to comin's own environment; git config elsewhere on the box is untouched.
    systemd.services.comin.environment = {
      GIT_CONFIG_COUNT = "1";
      GIT_CONFIG_KEY_0 = "credential.https://github.com.helper";
      GIT_CONFIG_VALUE_0 = "${credential}";
    };

    sops.secrets."github/read-token".sopsFile = ../../secrets/github-token.yaml;
    sops.templates."nix-access-tokens.conf".content = ''
      access-tokens = github.com=${config.sops.placeholder."github/read-token"}
    '';
    nix.extraOptions = ''
      !include ${config.sops.templates."nix-access-tokens.conf".path}
    '';
  };
}
