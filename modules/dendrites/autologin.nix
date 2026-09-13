{ username, ... }:
{
  # Headless box: skip the tty login prompt so an accidental reboot comes
  # back to a usable console without anyone typing a password at the machine.
  config = {
    services.getty.autologinUser = username;
  };
}
