# The shared khoa account. One definition; hosts attach it. The four identical
# hosts/<host>/users/khoa.nix copies this replaces were byte-for-byte the same
# file, so there was never a per-host identity to lose.
#
# The `nixos` lane is the account itself. The `homeManager` lane is the shared
# home floor — it is evaluated only for a host that turned this user's home
# lane on, so a headless host creates the account and stops there.
{
  nixos =
    { ... }:
    {
      users.users.khoa = {
        isNormalUser = true;
        description = "khoa";
        # khoa's personal key (osaka). Public key — safe to commit; grants SSH
        # from osaka to every host. Private half never leaves osaka.
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
      nix.settings.allowed-users = [ "khoa" ];
    };

  homeManager =
    { ... }:
    {
      home.username = "khoa";
      home.homeDirectory = "/home/khoa";
      home.stateVersion = "23.11";
      programs.home-manager.enable = true;
    };
}
