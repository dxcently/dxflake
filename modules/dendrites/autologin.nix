{
  config,
  lib,
  username,
  ...
}:
{
  options.dx.autologin.enable = lib.mkEnableOption "passwordless console autologin for the primary user";

  # Headless box: skip the tty login prompt so an accidental reboot comes
  # back to a usable console without anyone typing a password at the machine.
  config = lib.mkIf config.dx.autologin.enable {
    services.getty.autologinUser = username;
  };
}
