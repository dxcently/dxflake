{ username, ... }:
{
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    # khoa's personal key (osaka). Public key — safe to commit; grants SSH from
    # osaka to every host. Private half never leaves osaka.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSHb3e535b2U/hWEmIsFC2j99SmEayq3HS/IH1c61Aw dxcently@gmail.com"
    ];
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "audio"
      "video"
      "dialout"
      "docker"
      "cdrom"
      "openrazer"
    ];
  };
  nix.settings.allowed-users = [ "${username}" ];
}
