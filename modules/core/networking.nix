{
  pkgs,
  host,
  username,
  ...
}: {
  networking = {
    hostName = "${host}";
    networkmanager.enable = true;
    firewall = {
      enable = true;
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeQCxTQvPuOxU6Etb1hQJ7ypy8rETT64eoCLraWhYxw"
    ];
  };

  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
