{
  pkgs,
  config,
  lib,
  username,
  ...
}:
let
  # sudo -A runs this as the invoking user *before* elevating, so the plaintext
  # travels only from tmpfs (/run/secrets) into sudo's stdin — never argv, shell
  # history, or a command an agent has to echo. Swap the value with `sops`.
  askpass = pkgs.writeShellScript "ask-sudo" ''
    cat ${config.sops.secrets."sudo-password".path}
  '';
in
{
  options.dx.askSudo.enable = lib.mkEnableOption "sops-backed sudo askpass so `sudo -A` elevates unattended";

  config = lib.mkIf config.dx.askSudo.enable {
    sops.secrets."sudo-password" = {
      sopsFile = ../../secrets/sudo.yaml;
      owner = username;
    };

    environment.variables.SUDO_ASKPASS = "${askpass}";
  };
}
